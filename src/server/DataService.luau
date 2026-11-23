--!strict
-- Dados persistentes: pontos, upgrades permanentes, recorde de onda e recompensa diária.
-- Trava de sessão (Lock): só o servidor dono grava; trava sem renovação expira (servidor caiu).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 60
local LOCK_EXPIRE = 300 -- autosave renova a trava; 5 min sem renovar = servidor morto
local LOCK_ATTEMPTS = 5
local LOCK_WAIT = 6
local PURCHASE_HISTORY = 50 -- últimos PurchaseIds guardados para não conceder duas vezes

export type Data = {
	Points: number,
	BestWave: number,
	Upgrades: { [string]: number },
	DailyStreak: number,
	LastDaily: number, -- dia UTC (os.time() // 86400)
	BoostUntil: number, -- os.time() até quando o Boost de pontos vale
	Purchases: { string }, -- PurchaseIds já concedidos
	Lock: { Job: string, Time: number }?,
}
type Session = { data: Data, canSave: boolean, released: boolean }

local DataService = {}
local sessions: { [Player]: Session } = {}
local saving = 0

local okStore, storeOrErr = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
local store: DataStore? = if okStore then storeOrErr else nil

local function defaults(): Data
	return { Points = 0, BestWave = 0, Upgrades = {}, DailyStreak = 0, LastDaily = 0, BoostUntil = 0, Purchases = {} }
end

local function keyOf(player: Player): string
	return "u_" .. player.UserId
end

local function retry(label: string, fn: () -> ()): boolean
	for attempt = 1, 3 do
		local ok, err = pcall(fn)
		if ok then
			return true
		end
		warn(`[DataService] {label} falhou ({attempt}/3): {err}`)
		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end
	return false
end

local function sync(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	player:SetAttribute("Points", s.data.Points)
	player:SetAttribute("BestWave", s.data.BestWave)
	player:SetAttribute("DailyStreak", s.data.DailyStreak)
	player:SetAttribute("BoostUntil", s.data.BoostUntil)
	for id in Progression.Upgrades do
		player:SetAttribute("Upgrade_" .. id, s.data.Upgrades[id] or 0)
	end
end

-- Retorna os pontos ganhos hoje (0 se já recebeu)
local function claimDaily(data: Data): number
	local today = os.time() // 86400
	if data.LastDaily == today then
		return 0
	end
	data.DailyStreak = if data.LastDaily == today - 1 then data.DailyStreak + 1 else 1
	data.LastDaily = today
	local rewards = Progression.DailyRewards
	local amount = rewards[math.min(data.DailyStreak, #rewards)]
	data.Points += amount
	return amount
end

-- Retorna true se gravou (no Studio sem DataStore, finge que gravou)
local function write(player: Player, s: Session, release: boolean): boolean
	local st = store
	if not s.canSave or not st then
		return RunService:IsStudio()
	end
	if release then
		s.released = true
	end
	saving += 1
	local saved = false
	local ok = retry("save " .. keyOf(player), function()
		saved = false
		st:UpdateAsync(keyOf(player), function(old: Data?)
			if old and old.Lock and old.Lock.Job ~= game.JobId then
				return nil -- outro servidor assumiu a sessão; não sobrescreve
			end
			if s.released and not release then
				return nil -- autosave atrasado não pode travar de novo uma sessão já liberada
			end
			s.data.Lock = if release then nil else { Job = game.JobId, Time = os.time() }
			saved = true
			return s.data
		end)
	end)
	saving -= 1
	return ok and saved
end

-- Salva e libera a sessão (saída do jogador / servidor fechando)
local function release(player: Player)
	local s = sessions[player]
	sessions[player] = nil
	if s then
		write(player, s, true)
	end
end

-- Carrega e trava a sessão. Falha no jogo publicado = kick (nunca joga com dados vazios por cima dos reais).
function DataService.load(player: Player): boolean
	local loaded: Data? = nil
	local st = store
	if st then
		for _ = 1, LOCK_ATTEMPTS do
			local locked = false
			local ok = retry("load " .. keyOf(player), function()
				st:UpdateAsync(keyOf(player), function(old: Data?)
					local data = old or defaults()
					local lock = data.Lock
					if lock and lock.Job ~= game.JobId and os.time() - lock.Time < LOCK_EXPIRE then
						locked = true
						return nil
					end
					locked = false
					data.Lock = { Job = game.JobId, Time = os.time() }
					loaded = data
					return data
				end)
			end)
			if not ok or not locked or not player.Parent then
				break
			end
			task.wait(LOCK_WAIT) -- sessão ainda aberta em outro servidor (ex.: trocou de servidor agora)
		end
	end

	local data = loaded
	if not data then
		if not RunService:IsStudio() then
			player:Kick("Não foi possível carregar seus dados. Tente de novo em alguns minutos.")
			return false
		end
		warn("[DataService] Sem DataStore no Studio: dados temporários, nada será salvo. Ative 'Enable Studio Access to API Services'.")
	end
	local session: Session = { data = data or defaults(), canSave = data ~= nil, released = false }
	for key, value in defaults() :: any do
		if (session.data :: any)[key] == nil then
			(session.data :: any)[key] = value
		end
	end
	sessions[player] = session

	if not player.Parent then -- saiu durante o load: devolve a trava
		release(player)
		return false
	end

	local daily = claimDaily(session.data)
	sync(player)
	if daily > 0 then
		player:SetAttribute("DailyReward", daily)
	end
	return true
end

function DataService.bonus(player: Player, upgradeId: string): number
	local s = sessions[player]
	local level = if s then s.data.Upgrades[upgradeId] or 0 else 0
	return level * Progression.Upgrades[upgradeId].PerLevel
end

-- Fim de partida: soma pontos (com Pontos x2 e Boost), atualiza recorde. Retorna os pontos ganhos.
function DataService.finishMatch(player: Player, wave: number): number
	local s = sessions[player]
	local mult = 1
	if player:GetAttribute("Pass_PointsX2") then
		mult *= Products.PointsX2Multiplier
	end
	if s and os.time() < s.data.BoostUntil then
		mult *= Products.Boost.Multiplier
	end
	local points = math.floor((wave - 1) * EconomyConfig.PointsPerWave * mult)
	if s then
		s.data.Points += points
		s.data.BestWave = math.max(s.data.BestWave, wave)
		sync(player)
	end
	return points
end

-- Compra de Developer Product, idempotente: aplica uma vez por PurchaseId e só confirma depois de salvar.
function DataService.grantPurchase(player: Player, purchaseId: string, apply: (Data) -> ()): boolean
	local s = sessions[player]
	if not s then
		return false
	end
	local history = s.data.Purchases
	if not table.find(history, purchaseId) then
		apply(s.data)
		table.insert(history, purchaseId)
		if #history > PURCHASE_HISTORY then
			table.remove(history, 1)
		end
		sync(player)
	end
	return write(player, s, false)
end

Remotes.BuyUpgrade.OnServerEvent:Connect(function(player, id: any)
	local s = sessions[player]
	local def = if typeof(id) == "string" then Progression.Upgrades[id] else nil
	if not s or not def then
		return
	end
	local level = s.data.Upgrades[id] or 0
	local cost = def.Costs[level + 1]
	if not cost or s.data.Points < cost then
		return
	end
	for req, minLevel in def.Requires or {} do
		if (s.data.Upgrades[req] or 0) < minLevel then
			return
		end
	end
	s.data.Points -= cost
	s.data.Upgrades[id] = level + 1
	sync(player)
end)

Players.PlayerRemoving:Connect(release)

game:BindToClose(function()
	for player in sessions do
		task.spawn(release, player)
	end
	task.wait() -- deixa os saves começarem (inclusive os do PlayerRemoving)
	local deadline = os.clock() + 25
	while saving > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player, s in sessions do
			task.spawn(write, player, s, false)
		end
	end
end)

return DataService

--!strict
-- Ondas infinitas: fórmulas de escala, fila de spawn e intervalo entre ondas.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Waves = require(ReplicatedStorage.Shared.Config.Waves)
local EnemiesConfig = require(ReplicatedStorage.Shared.Config.Enemies)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local EnemyService = require(script.Parent.EnemyService)
local Economy = require(script.Parent.Economy)
local DataService = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local Clock = require(script.Parent.Clock)

type EnemyDef = EnemiesConfig.EnemyDef
type Entry = { def: EnemyDef, scale: EnemyService.Scale, gap: number }

local WaveService = {}

function WaveService.healthMult(n: number): number
	local early = math.min(n, Waves.HealthBreakWave)
	local late = math.max(n - Waves.HealthBreakWave, 0)
	-- Contínuo na onda 30 (1.05^n puro faria a vida cair na onda 31)
	return Waves.HealthGrowthEarly ^ early * Waves.HealthGrowthLate ^ late
end

function WaveService.count(n: number): number
	return math.min(math.floor(Waves.CountBase + n * Waves.CountPerWave), Waves.CountCap)
end

function WaveService.scale(n: number): EnemyService.Scale
	local health = WaveService.healthMult(n)
	local players = math.clamp(#Players:GetPlayers(), 1, Waves.MaxPlayers)
	return {
		Health = health * (1 + Waves.HealthPerExtraPlayer * (players - 1)),
		Speed = 1 + math.min(n * Waves.SpeedPerWave, Waves.SpeedMaxBonus),
		Reward = health ^ Waves.RewardExponent,
	}
end

function WaveService.pool(n: number): { EnemyDef }
	local list: { EnemyDef } = {}
	for _, def in EnemiesConfig.Types do
		if def.UnlockWave and n >= def.UnlockWave then
			table.insert(list, def)
		end
	end
	return list
end

-- Fila da onda n: grupos saem colados (GroupGap), o resto com SpawnInterval; chefe no fim
function WaveService.queue(n: number): { Entry }
	local pool = WaveService.pool(n)
	local scale = WaveService.scale(n)
	local total = WaveService.count(n)
	local q: { Entry } = {}
	while #q < total do
		local def = pool[math.random(#pool)]
		local group = def.GroupSize or 1
		for k = 1, math.min(group, total - #q) do
			table.insert(q, { def = def, scale = scale, gap = if k < group then Waves.GroupGap else Waves.SpawnInterval })
		end
	end
	if n % Waves.BossEvery == 0 then
		-- Chefe escala só a partir da primeira aparição
		table.insert(q, { def = EnemiesConfig.Boss, scale = WaveService.scale(n - Waves.BossEvery), gap = 0 })
	end
	return q
end

function WaveService.run()
	local startTime = Clock.now()
	local n = 0
	while not EnemyService.gameOver do
		n += 1
		local mutator = if n >= Waves.MutatorStartWave then Waves.Mutators[math.random(#Waves.Mutators)] else nil
		ReplicatedStorage:SetAttribute("Wave", n)
		ReplicatedStorage:SetAttribute("Mutator", if mutator then mutator.Name else nil)
		print(("Onda %d%s"):format(n, if mutator then " - " .. mutator.Name else ""))

		for _, entry in WaveService.queue(n) do
			while EnemyService.count() >= Waves.MaxAlive and not EnemyService.gameOver do
				task.wait(0.2)
			end
			if EnemyService.gameOver then
				break
			end
			EnemyService.spawn(entry.def, entry.scale, mutator)
			Clock.wait(entry.gap)
		end

		while EnemyService.count() > 0 and not EnemyService.gameOver do
			task.wait(0.5)
		end
		if not EnemyService.gameOver then
			Economy.payWaveBonus(EconomyConfig.WaveBonus * WaveService.scale(n).Reward)
			-- ponytail: contador do HUD não reajusta se a velocidade mudar no meio do intervalo
			ReplicatedStorage:SetAttribute("NextWaveAt", workspace:GetServerTimeNow() + Waves.TimeBetweenWaves / Clock.speed())
			Clock.wait(Waves.TimeBetweenWaves)
		end
	end
	local seconds = Clock.now() - startTime
	for _, player in Players:GetPlayers() do
		player:SetAttribute("PointsEarned", DataService.finishMatch(player, n))
	end
	task.spawn(function()
		for _, player in Players:GetPlayers() do
			LeaderboardService.submit(player, n, seconds)
		end
		LeaderboardService.refresh()
	end)
	print(("Fim de partida: onda %d"):format(n))
end

function WaveService.selfCheck()
	assert(WaveService.healthMult(0) == 1)
	assert(WaveService.healthMult(31) > WaveService.healthMult(30), "vida não pode cair após a onda 30")
	assert(WaveService.count(1000) == Waves.CountCap)
	assert(WaveService.scale(1000).Speed == 1 + Waves.SpeedMaxBonus)
	assert(WaveService.scale(20).Reward < WaveService.scale(20).Health)
	assert(#WaveService.pool(1) >= 1, "nenhum inimigo com UnlockWave = 1")
	local q = WaveService.queue(Waves.BossEvery)
	assert(q[#q].def == EnemiesConfig.Boss, "chefe faltando na onda do chefe")
	for id, def in EnemiesConfig.Types do
		assert(def.SplitInto == nil or EnemiesConfig.Types[def.SplitInto], id .. ": SplitInto inválido")
	end
end

return WaveService

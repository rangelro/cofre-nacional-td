--!strict
-- Ranking semanal (OrderedDataStore): maior onda; empate = menor tempo de jogo
-- (tempo de jogo não muda com o passe de velocidade, então ninguém compra desempate).
-- Top 10 publicado em ReplicatedStorage "WeeklyTop" (JSON) para a UI.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REFRESH_INTERVAL = 60
local TOP = 10
local TIME_CAP = 99999 -- segundos; score = onda * 100000 + (99999 - tempo)

local LeaderboardService = {}
local names: { [number]: string } = {}

local function store(): OrderedDataStore?
	-- Semana começa segunda 00:00 UTC (o epoch caiu numa quinta)
	local week = (os.time() - 4 * 86400) // (7 * 86400)
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "WeeklyWave_" .. week)
	return if ok then result else nil
end

function LeaderboardService.submit(player: Player, wave: number, seconds: number)
	local st = store()
	if not st then
		return
	end
	local score = wave * (TIME_CAP + 1) + (TIME_CAP - math.min(math.floor(seconds), TIME_CAP))
	local ok, err = pcall(function()
		st:UpdateAsync(tostring(player.UserId), function(old: number?)
			return if old and old >= score then nil else score
		end)
	end)
	if not ok then
		warn("[Leaderboard] submit falhou:", err)
	end
end

function LeaderboardService.refresh()
	local st = store()
	if not st then
		return
	end
	local ok, page = pcall(function()
		return st:GetSortedAsync(false, TOP):GetCurrentPage()
	end)
	if not ok then
		warn("[Leaderboard] leitura falhou:", page)
		return
	end
	local top = {}
	for _, entry in page :: any do
		local userId = tonumber(entry.key) :: number
		if not names[userId] then
			local okName, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
			if okName then
				names[userId] = name
			end
		end
		table.insert(top, {
			name = names[userId] or "?",
			wave = entry.value // (TIME_CAP + 1),
			seconds = TIME_CAP - entry.value % (TIME_CAP + 1),
		})
	end
	ReplicatedStorage:SetAttribute("WeeklyTop", HttpService:JSONEncode(top))
end

task.spawn(function()
	while true do
		LeaderboardService.refresh()
		task.wait(REFRESH_INTERVAL)
	end
end)

return LeaderboardService

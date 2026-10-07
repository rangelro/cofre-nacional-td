local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.WaveConfig)

local WaveSpawner = {}

function WaveSpawner.healthMult(n: number): number
	local early = math.min(n, Config.HealthBreakWave)
	local late = math.max(n - Config.HealthBreakWave, 0)
	-- Contínuo na onda 30 (1.05^n puro faria a vida cair na onda 31)
	return Config.HealthGrowthEarly ^ early * Config.HealthGrowthLate ^ late
end

function WaveSpawner.count(n: number): number
	return math.min(math.floor(Config.CountBase + n * Config.CountPerWave), Config.CountCap)
end

function WaveSpawner.speedMult(n: number): number
	return 1 + math.min(n * Config.SpeedPerWave, Config.SpeedMaxBonus)
end

function WaveSpawner.rewardMult(n: number): number
	return WaveSpawner.healthMult(n) ^ Config.RewardExponent
end

function WaveSpawner.unlocked(n: number)
	local list = {}
	for _, e in Config.Enemies do
		if n >= e.UnlockWave then
			table.insert(list, e)
		end
	end
	return list
end

-- Stats finais de um inimigo na onda n (mutator opcional)
function WaveSpawner.stats(def, n: number, mutator)
	local m = mutator or {}
	return {
		Name = def.Name,
		Health = math.ceil(def.Health * WaveSpawner.healthMult(n) * (m.Health or 1)),
		Speed = def.Speed * WaveSpawner.speedMult(n) * (m.Speed or 1),
		Reward = math.floor(def.Reward * WaveSpawner.rewardMult(n) * (m.Reward or 1)),
	}
end

-- Loop infinito. spawnEnemy(stats) deve criar o inimigo e retornar a Instance;
-- o spawner considera o inimigo morto/finalizado quando a Instance é destruída.
function WaveSpawner.run(spawnEnemy: (any) -> Instance, onWave: ((number, any) -> ())?)
	local alive = 0
	local function spawn(stats)
		while alive >= Config.MaxAlive do
			task.wait(0.2)
		end
		alive += 1
		spawnEnemy(stats).Destroying:Once(function()
			alive -= 1
		end)
	end

	local n = 0
	while true do
		n += 1
		local mutator = nil
		if n >= Config.MutatorStartWave then
			mutator = Config.Mutators[math.random(#Config.Mutators)]
		end
		if onWave then
			onWave(n, mutator)
		end

		local pool = WaveSpawner.unlocked(n)
		for _ = 1, WaveSpawner.count(n) do
			spawn(WaveSpawner.stats(pool[math.random(#pool)], n, mutator))
			task.wait(Config.SpawnInterval)
		end
		if n % Config.BossEvery == 0 then
			-- Chefe escala só a partir da sua primeira aparição
			spawn(WaveSpawner.stats(Config.Boss, n - Config.BossEvery, mutator))
		end

		while alive > 0 do
			task.wait(0.5)
		end
		task.wait(Config.TimeBetweenWaves)
	end
end

function WaveSpawner.selfCheck()
	assert(WaveSpawner.healthMult(0) == 1)
	assert(WaveSpawner.healthMult(31) > WaveSpawner.healthMult(30), "vida não pode cair após a onda 30")
	assert(WaveSpawner.count(1000) == Config.CountCap)
	assert(WaveSpawner.speedMult(1000) == 1 + Config.SpeedMaxBonus)
	assert(WaveSpawner.rewardMult(20) < WaveSpawner.healthMult(20))
	assert(#WaveSpawner.unlocked(1) >= 1)
end

return WaveSpawner

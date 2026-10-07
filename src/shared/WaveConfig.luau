-- Balanceamento das ondas. Mexa aqui; o WaveSpawner (server) só lê.
return {
	-- Vida: base * 1.10^n até a onda 30, depois continua com 1.05 por onda
	HealthGrowthEarly = 1.10,
	HealthGrowthLate = 1.05,
	HealthBreakWave = 30,

	-- Quantidade: base + n * 0.8, com teto
	CountBase = 5,
	CountPerWave = 0.8,
	CountCap = 55,

	-- Inimigos vivos ao mesmo tempo (performance)
	MaxAlive = 55,

	-- Velocidade: +1% por onda, teto +50%
	SpeedPerWave = 0.01,
	SpeedMaxBonus = 0.5,

	-- Recompensa = base * multVida^RewardExponent (< 1 => cresce mais devagar que a vida)
	RewardExponent = 0.6,

	SpawnInterval = 0.6, -- segundos entre spawns
	TimeBetweenWaves = 8,

	-- Um tipo novo a cada 5 ondas (UnlockWave). Personagens fictícios do Clã Mitomano.
	Enemies = {
		{ Name = "Laranja", UnlockWave = 1, Health = 20, Speed = 8, Reward = 5 },
		{ Name = "Assessor Fantasma", UnlockWave = 5, Health = 15, Speed = 13, Reward = 6 },
		{ Name = "Lobista", UnlockWave = 10, Health = 45, Speed = 6, Reward = 9 },
		{ Name = "Doleiro", UnlockWave = 15, Health = 30, Speed = 10, Reward = 10 },
	},

	BossEvery = 10,
	Boss = { Name = "Chefão do Clã", Health = 600, Speed = 5, Reward = 100 },

	-- A partir desta onda, cada onda sorteia um mutador
	MutatorStartWave = 41,
	Mutators = {
		{ Name = "Blindados", Health = 1.3, Speed = 1 },
		{ Name = "Apressados", Health = 1, Speed = 1.2 },
		{ Name = "Delação Premiada", Health = 0.8, Speed = 1, Reward = 1.5 },
	},
}

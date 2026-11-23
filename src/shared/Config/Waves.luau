--!strict
-- Balanceamento das ondas e do Cofre. Só dados; a lógica fica em WaveService.

export type Mutator = {
	Name: string,
	Armor: number?, -- fração do dano ignorada
	Regen: number?, -- fração da vida máx. regenerada por segundo
	Shield: number?, -- escudo extra (fração da vida máx.), absorve dano antes da vida
}

local Mutators: { Mutator } = {
	{ Name = "Armadura", Armor = 0.3 },
	{ Name = "Regeneração", Regen = 0.02 },
	{ Name = "Escudo", Shield = 0.5 },
}

return {
	VaultHealth = 100,

	-- Vida: base * 1.10^n até a onda 30, depois continua com 1.05 por onda
	HealthGrowthEarly = 1.10,
	HealthGrowthLate = 1.05,
	HealthBreakWave = 30,

	-- Quantidade: base + n * 0.8, com teto
	CountBase = 5,
	CountPerWave = 0.8,
	CountCap = 55,

	-- Inimigos vivos ao mesmo tempo; o resto espera na fila de spawn
	MaxAlive = 55,

	-- Co-op: vida * (1 + HealthPerExtraPlayer * (jogadores - 1)), até MaxPlayers
	HealthPerExtraPlayer = 0.6,
	MaxPlayers = 4,

	-- Velocidade: +1% por onda, teto +50%
	SpeedPerWave = 0.01,
	SpeedMaxBonus = 0.5,

	-- Recompensa = base * multVida^RewardExponent (< 1 => cresce mais devagar que a vida)
	RewardExponent = 0.6,

	SpawnInterval = 0.6, -- segundos entre spawns
	GroupGap = 0.15, -- segundos entre membros de um grupo
	TimeBetweenWaves = 8,

	BossEvery = 10,

	-- A partir desta onda, cada onda sorteia um mutador
	MutatorStartWave = 41,
	Mutators = Mutators,
}

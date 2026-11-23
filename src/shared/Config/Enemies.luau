--!strict
-- Tipos de inimigo do Clã Mitomano (personagens fictícios). Só dados; a lógica fica em EnemyService.
-- "Inimigo novo a cada 5 ondas" = UnlockWave. Sem UnlockWave = não entra sozinho na onda.

export type Phase = {
	Name: string,
	Duration: number, -- segundos
	SpeedMult: number?,
	Immune: boolean?,
}

export type EnemyDef = {
	Name: string,
	UnlockWave: number?,
	Health: number,
	Speed: number, -- studs/s
	Reward: number,
	VaultDamage: number,
	Color: Color3,
	Size: number?,
	-- Habilidades (opcionais)
	Reflect: number?, -- fração do dano devolvida a quem atacou
	Invisible: boolean?, -- só torres com detecção acertam
	HealRadius: number?,
	HealPercent: number?, -- fração da vida máx. curada por pulso
	HealInterval: number?,
	GroupSize: number?, -- quantos saem juntos
	SplitInto: string?, -- chave em Types
	SplitCount: number?,
	Phases: { Phase }?, -- ciclo de fases (chefe)
}

local Types: { [string]: EnemyDef } = {
	Motoqueiro = {
		Name = "Motoqueiro da Motociata",
		UnlockWave = 1,
		Health = 12,
		Speed = 14,
		Reward = 2,
		VaultDamage = 1,
		Color = Color3.fromRGB(40, 40, 40),
		GroupSize = 3,
	},
	RachadinhaMan = {
		Name = "Rachadinha Man",
		UnlockWave = 5,
		Health = 20,
		Speed = 12,
		Reward = 4,
		VaultDamage = 1,
		Color = Color3.fromRGB(200, 60, 60),
		Reflect = 0.15,
	},
	Joalheiro = {
		Name = "Joalheiro do Deserto",
		UnlockWave = 10,
		Health = 120,
		Speed = 5,
		Reward = 20,
		VaultDamage = 3,
		Color = Color3.fromRGB(230, 190, 60),
		Size = 4,
	},
	FakeNewsBot = {
		Name = "Fake News Bot",
		UnlockWave = 15,
		Health = 30,
		Speed = 8,
		Reward = 3,
		VaultDamage = 1,
		Color = Color3.fromRGB(80, 120, 220),
		SplitInto = "FakeNewsMini",
		SplitCount = 2,
	},
	FakeNewsMini = {
		Name = "Fake News Repost",
		Health = 10,
		Speed = 11,
		Reward = 1,
		VaultDamage = 1,
		Color = Color3.fromRGB(120, 160, 255),
		Size = 1.5,
	},
	DoutorCloroquina = {
		Name = "Doutor Cloroquina",
		UnlockWave = 20,
		Health = 40,
		Speed = 7,
		Reward = 6,
		VaultDamage = 1,
		Color = Color3.fromRGB(240, 240, 240),
		HealRadius = 12,
		HealPercent = 0.05,
		HealInterval = 2,
	},
	AssessorFantasma = {
		Name = "Assessor Fantasma",
		UnlockWave = 25,
		Health = 25,
		Speed = 10,
		Reward = 5,
		VaultDamage = 2,
		Color = Color3.fromRGB(170, 170, 200),
		Invisible = true,
	},
}

local Boss: EnemyDef = {
	Name = "O Mito",
	Health = 800,
	Speed = 4,
	Reward = 150,
	VaultDamage = 20,
	Color = Color3.fromRGB(0, 150, 60),
	Size = 6,
	Phases = {
		{ Name = "Normal", Duration = 5 },
		{ Name = "Discurso", Duration = 4, SpeedMult = 2 },
		{ Name = "Live", Duration = 3, Immune = true },
	},
}

return {
	Types = Types,
	Boss = Boss,
}

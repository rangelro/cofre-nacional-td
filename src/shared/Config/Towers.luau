--!strict
-- Torres. Levels[1] = colocar; Levels[2..4] = os 3 upgrades. Cost de cada nível é o preço daquele passo.

export type TowerLevel = {
	Cost: number,
	Damage: number,
	Range: number, -- studs
	Cooldown: number, -- segundos entre tiros
	Splash: number?, -- raio de dano em área
	Slow: number?, -- fração de lentidão (0.3 = 30% mais lento)
	SlowDuration: number?,
	Stun: number?, -- segundos parado
	BossMult: number?, -- multiplicador de dano em chefes
	BuffRadius: number?, -- torres neste raio recebem o buff
	BuffDamage: number?, -- +dano para torres no raio (não acumula, vale o maior)
}

export type TowerDef = {
	Name: string,
	Color: Color3,
	Detects: boolean?, -- acerta invisíveis
	GrantsDetection: boolean?, -- torres no BuffRadius também acertam invisíveis
	Levels: { TowerLevel },
}

local Types: { [string]: TowerDef } = {
	Lupa = {
		Name = "Lupa da Transparência",
		Color = Color3.fromRGB(120, 200, 255),
		Detects = true,
		GrantsDetection = true,
		Levels = {
			{ Cost = 120, Damage = 2, Range = 14, Cooldown = 1.0, BuffRadius = 12, BuffDamage = 0.10 },
			{ Cost = 100, Damage = 3, Range = 16, Cooldown = 0.9, BuffRadius = 14, BuffDamage = 0.15 },
			{ Cost = 180, Damage = 4, Range = 18, Cooldown = 0.8, BuffRadius = 16, BuffDamage = 0.20 },
			{ Cost = 300, Damage = 6, Range = 20, Cooldown = 0.7, BuffRadius = 18, BuffDamage = 0.30 },
		},
	},
	Caneta = {
		Name = "Caneta do Fiscal",
		Color = Color3.fromRGB(30, 60, 160),
		Levels = {
			{ Cost = 100, Damage = 25, Range = 24, Cooldown = 2.0 },
			{ Cost = 120, Damage = 45, Range = 26, Cooldown = 1.9 },
			{ Cost = 220, Damage = 80, Range = 28, Cooldown = 1.7 },
			{ Cost = 400, Damage = 150, Range = 32, Cooldown = 1.5 },
		},
	},
	Tribunal = {
		Name = "Tribunal de Contas",
		Color = Color3.fromRGB(140, 90, 50),
		Levels = {
			{ Cost = 150, Damage = 8, Range = 14, Cooldown = 1.5, Splash = 6 },
			{ Cost = 140, Damage = 14, Range = 15, Cooldown = 1.4, Splash = 7 },
			{ Cost = 260, Damage = 24, Range = 16, Cooldown = 1.3, Splash = 8 },
			{ Cost = 450, Damage = 40, Range = 18, Cooldown = 1.2, Splash = 10 },
		},
	},
	Hacker = {
		Name = "Hacker de Planilha",
		Color = Color3.fromRGB(40, 200, 90),
		Levels = {
			{ Cost = 110, Damage = 2, Range = 16, Cooldown = 1.0, Slow = 0.3, SlowDuration = 1.5 },
			{ Cost = 120, Damage = 3, Range = 17, Cooldown = 1.0, Slow = 0.4, SlowDuration = 1.8 },
			{ Cost = 200, Damage = 4, Range = 18, Cooldown = 0.9, Slow = 0.5, SlowDuration = 2.0 },
			{ Cost = 350, Damage = 6, Range = 20, Cooldown = 0.9, Slow = 0.5, SlowDuration = 2.0, Stun = 0.4 },
		},
	},
	Agente = {
		Name = "Agente da Federal",
		Color = Color3.fromRGB(20, 20, 20),
		Levels = {
			{ Cost = 130, Damage = 12, Range = 18, Cooldown = 1.0, BossMult = 2 },
			{ Cost = 140, Damage = 20, Range = 19, Cooldown = 0.95, BossMult = 2.5 },
			{ Cost = 240, Damage = 32, Range = 20, Cooldown = 0.9, BossMult = 3 },
			{ Cost = 420, Damage = 55, Range = 22, Cooldown = 0.8, BossMult = 4 },
		},
	},
}

return {
	Types = Types,
	TargetModes = { "First", "Strongest", "Closest" },
	-- Dano refletido (Rachadinha Man) vira atraso no próximo tiro da torre
	ReflectSecondsPerDamage = 0.02,
}

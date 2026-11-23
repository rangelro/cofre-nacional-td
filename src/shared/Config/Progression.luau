--!strict
-- Progressão permanente (salva no DataStore). Costs[i] = preço em pontos do nível i; MaxLevel = #Costs.

export type Upgrade = {
	Order: number, -- ordem na UI
	Name: string,
	Description: string,
	PerLevel: number,
	Costs: { number },
	Requires: { [string]: number }?, -- id do upgrade -> nível mínimo
}

local Upgrades: { [string]: Upgrade } = {
	TowerDamage = {
		Order = 1,
		Name = "Dano das torres",
		Description = "+5% de dano por nível",
		PerLevel = 0.05,
		Costs = { 50, 100, 200, 400, 800 },
	},
	StartMoney = {
		Order = 2,
		Name = "Caixa inicial",
		Description = "+25 de dinheiro inicial por nível",
		PerLevel = 25,
		Costs = { 40, 80, 160, 320, 640 },
	},
	WaveBonus = {
		Order = 3,
		Name = "Verba extra",
		Description = "+10% no bônus por onda por nível",
		PerLevel = 0.10,
		Costs = { 100, 200, 400 },
		Requires = { StartMoney = 2 },
	},
}

return {
	Upgrades = Upgrades,
	-- Pontos por dia seguido de login; depois do último, repete o último
	DailyRewards = { 10, 15, 20, 30, 40, 50, 75 },
}

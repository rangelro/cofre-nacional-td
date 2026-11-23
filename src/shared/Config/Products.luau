--!strict
-- Game Passes e Developer Products. IDs = 0 são placeholder: troque pelos IDs reais do Creator Dashboard.
-- Regra: compras só aceleram progresso ou são cosméticas. Nada de torre exclusiva mais forte, nada de loot box.

export type Pass = { Id: number, Name: string, Order: number }

local GamePasses: { [string]: Pass } = {
	PointsX2 = { Id = 0, Name = "Pontos x2", Order = 1 },
	SpeedX2 = { Id = 0, Name = "Velocidade x2", Order = 2 },
	SpeedX3 = { Id = 0, Name = "Velocidade x3", Order = 3 }, -- também libera 2x
	SlotExtra = { Id = 0, Name = "Slot extra", Order = 4 }, -- libera os slots com atributo Premium
}

return {
	GamePasses = GamePasses,
	PointsX2Multiplier = 2,
	Boost = { Id = 0, Name = "Boost +50% pontos (30 min)", Multiplier = 1.5, Duration = 1800 },
}

--!strict
-- Dinheiro da partida (individual por jogador).
return {
	StartMoney = 250,
	SellRefund = 0.7, -- fração do total gasto na torre
	-- Bônus por onda concluída, para todos: WaveBonus * multRecompensa(n)
	WaveBonus = 20,
	-- Pontos de progressão no fim da partida: (onda alcançada - 1) * PointsPerWave
	PointsPerWave = 10,
}

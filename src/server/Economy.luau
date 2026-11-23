--!strict
-- Dinheiro da partida em Player:GetAttribute("Money") (replica para a UI; só o servidor altera).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local DataService = require(script.Parent.DataService)

local Economy = {}

function Economy.get(player: Player): number
	return (player:GetAttribute("Money") :: number?) or 0
end

function Economy.add(player: Player, amount: number)
	player:SetAttribute("Money", Economy.get(player) + amount)
end

function Economy.spend(player: Player, amount: number): boolean
	if Economy.get(player) < amount then
		return false
	end
	Economy.add(player, -amount)
	return true
end

-- Chamar depois do DataService.load (usa o upgrade de dinheiro inicial)
function Economy.init(player: Player)
	player:SetAttribute("Money", EconomyConfig.StartMoney + DataService.bonus(player, "StartMoney"))
end

function Economy.payWaveBonus(amount: number)
	for _, player in Players:GetPlayers() do
		Economy.add(player, math.floor(amount * (1 + DataService.bonus(player, "WaveBonus"))))
	end
end

return Economy

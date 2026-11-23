--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local EnemyService = require(script.EnemyService)
local WaveService = require(script.WaveService)
local DataService = require(script.DataService)
local Economy = require(script.Economy)
require(script.TowerService)
require(script.MonetizationService)

local function onPlayer(player: Player)
	if DataService.load(player) then
		Economy.init(player)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end

if RunService:IsStudio() then
	WaveService.selfCheck()
	-- Teste sem torres, pela Command Bar: game.ServerScriptService.DebugDamageAll:Fire(30)
	local debugDamage = Instance.new("BindableEvent")
	debugDamage.Name = "DebugDamageAll"
	debugDamage.Parent = ServerScriptService
	debugDamage.Event:Connect(function(amount: number)
		for _, e in table.clone(EnemyService.all()) do
			EnemyService.damage(e, amount, true)
		end
	end)
end

-- Qualquer jogador pode iniciar; só a primeira chamada conta
Remotes.StartWaves.OnServerEvent:Connect(function()
	if ReplicatedStorage:GetAttribute("WavesStarted") then
		return
	end
	ReplicatedStorage:SetAttribute("WavesStarted", true)
	task.spawn(WaveService.run)
end)

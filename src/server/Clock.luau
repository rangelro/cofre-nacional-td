--!strict
-- Tempo de jogo = tempo real * GameSpeed (passe de velocidade).
-- Movimento, tiros, spawns e intervalos passam por aqui para acelerar juntos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clock = {}
local gameTime = 0

function Clock.speed(): number
	return (ReplicatedStorage:GetAttribute("GameSpeed") :: number?) or 1
end

function Clock.now(): number
	return gameTime
end

function Clock.wait(seconds: number)
	local target = gameTime + seconds
	while gameTime < target do
		RunService.Heartbeat:Wait()
	end
end

RunService.Heartbeat:Connect(function(dt)
	gameTime += dt * Clock.speed()
end)

return Clock

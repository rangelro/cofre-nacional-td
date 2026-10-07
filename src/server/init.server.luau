local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local WaveSpawner = require(script.WaveSpawner)

if RunService:IsStudio() then
	WaveSpawner.selfCheck()
end

-- ponytail: placeholder até existir o movimento por waypoints; troque por EnemyMover.spawn(stats)
local function spawnEnemy(stats)
	local part = Instance.new("Part")
	part.Name = stats.Name
	part.Anchored = true
	part.Size = Vector3.new(2, 4, 2)
	part.Position = Vector3.new(0, 2, 0)
	for k, v in stats do
		part:SetAttribute(k, v)
	end
	part.Parent = workspace
	Debris:AddItem(part, 5)
	return part
end

task.spawn(WaveSpawner.run, spawnEnemy, function(n, mutator)
	print(("Onda %d%s"):format(n, mutator and (" - " .. mutator.Name) or ""))
end)

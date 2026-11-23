--!strict
-- Lê Workspace.Map.Waypoints ("1", "2", ...) e converte distância percorrida em CFrame.
-- Sem mapa no Studio, cria um mapa de teste.
local RunService = game:GetService("RunService")

local function buildTestMap(): Instance
	local map = Instance.new("Folder")
	map.Name = "Map"
	local waypoints = Instance.new("Folder")
	waypoints.Name = "Waypoints"
	waypoints.Parent = map
	local slots = Instance.new("Folder")
	slots.Name = "TowerSlots"
	slots.Parent = map

	local points = {
		Vector3.new(-90, 0, -60),
		Vector3.new(-90, 0, 40),
		Vector3.new(-30, 0, 40),
		Vector3.new(-30, 0, -40),
		Vector3.new(30, 0, -40),
		Vector3.new(30, 0, 60),
		Vector3.new(90, 0, 60),
	}
	for i, p in points do
		local wp = Instance.new("Part")
		wp.Name = tostring(i)
		wp.Anchored = true
		wp.CanCollide = false
		wp.Transparency = 1
		wp.Size = Vector3.one
		wp.Position = p
		wp.Parent = waypoints

		if i > 1 then
			local a = points[i - 1]
			local up = Vector3.new(0, 0.05, 0)
			local road = Instance.new("Part")
			road.Name = "Road"
			road.Anchored = true
			road.Size = Vector3.new(6, 0.1, (p - a).Magnitude + 6)
			road.CFrame = CFrame.lookAt((a + p) / 2 + up, p + up)
			road.Color = Color3.fromRGB(200, 180, 130)
			road.Parent = map

			local slot = Instance.new("Part")
			slot.Name = "Slot" .. (i - 1)
			slot.Anchored = true
			slot.Size = Vector3.new(5, 0.4, 5)
			slot.Position = (a + p) / 2 + (p - a).Unit:Cross(Vector3.yAxis) * 9
			slot.Color = Color3.fromRGB(90, 90, 110)
			slot.Parent = slots
		end
	end

	-- Slots do Game Pass "Slot extra"
	for i, pos in { Vector3.new(60, 0, 51), Vector3.new(0, 0, 0) } do
		local slot = Instance.new("Part")
		slot.Name = "PremiumSlot" .. i
		slot.Anchored = true
		slot.Size = Vector3.new(5, 0.4, 5)
		slot.Position = pos
		slot.Color = Color3.fromRGB(200, 160, 40)
		slot:SetAttribute("Premium", true)
		slot.Parent = slots
	end

	local vault = Instance.new("Part")
	vault.Name = "Cofre"
	vault.Anchored = true
	vault.Size = Vector3.new(8, 6, 8)
	vault.Position = points[#points] + Vector3.new(6, 3, 0)
	vault.Color = Color3.fromRGB(255, 200, 0)
	vault.Material = Enum.Material.Metal
	vault.Parent = map

	map.Parent = workspace
	return map
end

local map = workspace:FindFirstChild("Map")
if not map then
	assert(RunService:IsStudio(), "Workspace.Map não encontrado")
	map = buildTestMap()
end

local parts = (map :: Instance):WaitForChild("Waypoints"):GetChildren()
table.sort(parts, function(a, b)
	return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
end)
assert(#parts >= 2, "Map.Waypoints precisa de pelo menos 2 Parts")

local points: { Vector3 } = {}
local cumulative: { number } = { 0 }
for i, part in parts do
	points[i] = (part :: BasePart).Position
	if i > 1 then
		cumulative[i] = cumulative[i - 1] + (points[i] - points[i - 1]).Magnitude
	end
end

local Map = {}
Map.length = cumulative[#points]
Map.slots = (map :: Instance):WaitForChild("TowerSlots")

-- CFrame no caminho após percorrer d studs, olhando para a frente
function Map.cframeAt(d: number): CFrame
	for i = 2, #points do
		if d <= cumulative[i] or i == #points then
			local a, b = points[i - 1], points[i]
			local t = math.clamp((d - cumulative[i - 1]) / (cumulative[i] - cumulative[i - 1]), 0, 1)
			local pos = a:Lerp(b, t)
			return CFrame.lookAt(pos, pos + (b - a))
		end
	end
	return CFrame.new(points[1])
end

return Map

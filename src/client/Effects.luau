--!strict
-- Barras de vida dos inimigos, aviso de chefe e efeito de tiro das torres.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Enemies = require(ReplicatedStorage.Shared.Config.Enemies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local make = require(script.Parent.Ui)

local gui = make("ScreenGui", { Name = "Effects", ResetOnSpawn = false, Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })

local banner = make("TextLabel", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 50),
	Size = UDim2.new(1, -260, 0, 30), -- deixa espaço para o botão Upgrades à esquerda
	BackgroundColor3 = Color3.fromRGB(150, 20, 20),
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	Parent = gui,
}, { make("UICorner", {}), make("UISizeConstraint", { MaxSize = Vector2.new(420, 30) }) })

local immunePhases: { [string]: boolean } = {}
for _, phase in Enemies.Boss.Phases or {} do
	immunePhases[phase.Name] = phase.Immune == true
end

local function trackBoss(part: BasePart)
	local function update()
		local phase = part:GetAttribute("Phase") :: string
		banner.Text = `CHEFE: {part.Name} · {phase}` .. (if immunePhases[phase] then " (IMUNE)" else "")
		banner.Visible = true
	end
	part:GetAttributeChangedSignal("Phase"):Connect(update)
	part.AncestryChanged:Connect(function(_, parent)
		if not parent then
			banner.Visible = false
		end
	end)
	update()
end

local function attach(part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local boss = part:GetAttribute("Phase") ~= nil
	local fill = make("Frame", {
		BackgroundColor3 = if boss then Color3.fromRGB(220, 60, 60) else Color3.fromRGB(80, 220, 80),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	})
	make("BillboardGui", {
		Adornee = part,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(if boss then 120 else 44, if boss then 10 else 5),
		StudsOffset = Vector3.new(0, part.Size.Y / 2 + 1.5, 0),
		Parent = part,
	}, {
		make("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, { fill }),
	})
	local function update()
		local health = (part:GetAttribute("Health") :: number?) or 0
		local max = (part:GetAttribute("MaxHealth") :: number?) or 1
		fill.Size = UDim2.fromScale(math.clamp(health / max, 0, 1), 1)
	end
	part:GetAttributeChangedSignal("Health"):Connect(update)
	update()
	if boss then
		trackBoss(part)
	end
end

local enemyFolder = workspace:WaitForChild("Enemies")
enemyFolder.ChildAdded:Connect(attach)
for _, part in enemyFolder:GetChildren() do
	attach(part)
end

Remotes.TowerFired.OnClientEvent:Connect(function(tower: BasePart, target: Vector3)
	if not tower.Parent then
		return
	end
	local from = tower.Position + Vector3.new(0, tower.Size.Y / 2, 0)
	local length = (target - from).Magnitude
	local beam = make("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Material = Enum.Material.Neon,
		Color = tower.Color,
		Size = Vector3.new(0.25, 0.25, length),
		CFrame = CFrame.lookAt(from, target) * CFrame.new(0, 0, -length / 2),
		Parent = workspace,
	})
	Debris:AddItem(beam, 0.08)
end)

return {}

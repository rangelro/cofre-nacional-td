--!strict
-- Clique num slot = menu de compra. Clique numa torre = painel de upgrade/venda/alvo.
-- O cliente só pede; o servidor valida tudo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local Towers = require(ReplicatedStorage.Shared.Config.Towers)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local make = require(script.Parent.Ui)

local player = Players.LocalPlayer
local slots = workspace:WaitForChild("Map"):WaitForChild("TowerSlots")
local towerFolder = workspace:WaitForChild("Towers")

local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(25, 25, 35)
local MODE_NAMES = { First = "Primeiro", Strongest = "Mais forte", Closest = "Mais próximo" }

local ids: { string } = {}
for id in Towers.Types do
	table.insert(ids, id)
end
table.sort(ids, function(a, b)
	return Towers.Types[a].Levels[1].Cost < Towers.Types[b].Levels[1].Cost
end)

local gui = make("ScreenGui", { Name = "TowerMenu", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })
local selection = make("SelectionBox", { LineThickness = 0.1, Color3 = Color3.fromRGB(255, 220, 0), Parent = gui })

local function button(text: string, order: number): TextButton
	return make("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromScale(0.19, 1),
		BackgroundColor3 = Color3.fromRGB(50, 50, 70),
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Text = text,
	}, {
		make("UICorner", {}),
		make("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
		make("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }),
	})
end

local function bottomBar(height: number): Frame
	return make("Frame", {
		Visible = false,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -16, 0, height),
		Parent = gui,
	}, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	})
end

local selectedSlot: BasePart? = nil
local selectedTower: BasePart? = nil
local towerConn: RBXScriptConnection? = nil

-- Menu de compra
local buyBar = bottomBar(56)
local buyButtons: { [string]: TextButton } = {}
for i, id in ids do
	local def = Towers.Types[id]
	local b = button(`{def.Name}\n$ {def.Levels[1].Cost}`, i)
	b.Parent = buyBar
	b.Activated:Connect(function()
		if selectedSlot then
			Remotes.PlaceTower:FireServer(selectedSlot, id)
		end
	end)
	buyButtons[id] = b
end

local function refreshBuy()
	local money = (player:GetAttribute("Money") :: number?) or 0
	for id, b in buyButtons do
		local affordable = money >= Towers.Types[id].Levels[1].Cost
		b.BackgroundColor3 = if affordable then Color3.fromRGB(40, 120, 70) else Color3.fromRGB(70, 40, 40)
	end
end

-- Painel da torre
local panel = bottomBar(48)
local title = button("", 1)
title.BackgroundColor3 = DARK
title.AutoButtonColor = false
local upgradeButton, sellButton, modeButton = button("", 2), button("", 3), button("", 4)
for _, b in { title, upgradeButton, sellButton, modeButton } do
	b.Parent = panel
end

local function refreshPanel()
	local t = selectedTower
	if not t then
		return
	end
	local def = Towers.Types[t:GetAttribute("TowerId") :: string]
	local level = t:GetAttribute("Level") :: number
	local mine = t:GetAttribute("Owner") == player.UserId
	local nextLevel = def.Levels[level + 1]
	local spent = 0
	for i = 1, level do
		spent += def.Levels[i].Cost
	end

	title.Text = `{def.Name}\nNível {level}/{#def.Levels}`
	upgradeButton.Text = if nextLevel then `Melhorar\n$ {nextLevel.Cost}` else "Nível máximo"
	sellButton.Text = `Vender\n$ {math.floor(spent * EconomyConfig.SellRefund)}`
	modeButton.Text = `Alvo:\n{MODE_NAMES[t:GetAttribute("TargetMode") :: string]}`
	for _, b in { upgradeButton, sellButton, modeButton } do
		b.Visible = mine
	end
	local money = (player:GetAttribute("Money") :: number?) or 0
	upgradeButton.BackgroundColor3 = if nextLevel and money >= nextLevel.Cost
		then Color3.fromRGB(40, 120, 70)
		else Color3.fromRGB(70, 40, 40)
end

upgradeButton.Activated:Connect(function()
	Remotes.UpgradeTower:FireServer(selectedTower)
end)
sellButton.Activated:Connect(function()
	Remotes.SellTower:FireServer(selectedTower)
end)
modeButton.Activated:Connect(function()
	local t = selectedTower
	if t then
		local i = table.find(Towers.TargetModes, t:GetAttribute("TargetMode")) or 0
		Remotes.SetTargetMode:FireServer(t, Towers.TargetModes[i % #Towers.TargetModes + 1])
	end
end)

local function close()
	selectedSlot, selectedTower = nil, nil
	selection.Adornee = nil
	buyBar.Visible = false
	panel.Visible = false
	if towerConn then
		towerConn:Disconnect()
		towerConn = nil
	end
end

local function selectSlot(slot: BasePart)
	close()
	if slot:GetAttribute("Premium") and not player:GetAttribute("Pass_SlotExtra") then
		local id = Products.GamePasses.SlotExtra.Id
		if id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			warn("Slot extra: ID placeholder em Config/Products")
		end
		return
	end
	selectedSlot = slot
	selection.Adornee = slot
	buyBar.Visible = true
	refreshBuy()
end

local function selectTower(tower: BasePart)
	close()
	selectedTower = tower
	selection.Adornee = tower
	panel.Visible = true
	towerConn = tower.AttributeChanged:Connect(refreshPanel)
	refreshPanel()
end

player:GetAttributeChangedSignal("Money"):Connect(function()
	refreshBuy()
	refreshPanel()
end)

-- Torre comprada no slot selecionado: abre o painel dela
towerFolder.ChildAdded:Connect(function(tower)
	local slot = selectedSlot
	if slot and tower:IsA("BasePart") and tower:GetAttribute("Owner") == player.UserId then
		local offset = tower.Position - slot.Position
		if Vector2.new(offset.X, offset.Z).Magnitude < 1 then
			selectTower(tower)
		end
	end
end)
towerFolder.ChildRemoved:Connect(function(tower)
	if tower == selectedTower then
		close()
	end
end)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { slots, towerFolder }

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local camera = workspace.CurrentCamera
	local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	local part = hit and hit.Instance
	if not part or not part:IsA("BasePart") then
		close()
	elseif part.Parent == towerFolder then
		selectTower(part)
	else
		selectSlot(part)
	end
end)

return {}

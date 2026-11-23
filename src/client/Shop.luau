--!strict
-- Loja (Game Passes + Boost), botão de velocidade e ranking semanal. Posse e compra são validadas no servidor.
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local make = require(script.Parent.Ui)

local player = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(25, 25, 35)
local GREEN = Color3.fromRGB(40, 120, 70)
local GOLD = Color3.fromRGB(170, 130, 30)

local gui = make("ScreenGui", { Name = "Shop", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })

local function owns(key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

local function promptPass(key: string)
	local id = Products.GamePasses[key].Id
	if id == 0 then
		warn(`{key}: ID placeholder em Config/Products`)
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function sideButton(text: string, y: number, color: Color3): TextButton
	return make("TextButton", {
		Text = text,
		Position = UDim2.new(0, 8, 0, y),
		Size = UDim2.fromOffset(110, 30),
		BackgroundColor3 = color,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Parent = gui,
	}, { make("UICorner", {}) })
end

local function centerPanel(height: number): Frame
	return make("Frame", {
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -32, 0, height),
		BackgroundColor3 = DARK,
		Parent = gui,
	}, {
		make("UICorner", {}),
		make("UISizeConstraint", { MaxSize = Vector2.new(420, height) }),
		make("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	})
end

-- Velocidade: alterna entre as velocidades que o jogador tem; sem passe, oferece o passe
local speedButton = sideButton("", 122, Color3.fromRGB(30, 90, 160))
local function updateSpeed()
	speedButton.Text = `Velocidade {ReplicatedStorage:GetAttribute("GameSpeed") or 1}x`
end
ReplicatedStorage:GetAttributeChangedSignal("GameSpeed"):Connect(updateSpeed)
updateSpeed()
speedButton.Activated:Connect(function()
	local allowed = { 1 }
	if owns("SpeedX2") or owns("SpeedX3") then
		table.insert(allowed, 2)
	end
	if owns("SpeedX3") then
		table.insert(allowed, 3)
	end
	if #allowed == 1 then
		promptPass("SpeedX2")
		return
	end
	local current = (ReplicatedStorage:GetAttribute("GameSpeed") :: number?) or 1
	Remotes.SetGameSpeed:FireServer(allowed[(table.find(allowed, current) or 0) % #allowed + 1])
end)

-- Loja
local shopPanel = centerPanel(300)
local ranking = centerPanel(300)
sideButton("Loja", 86, GOLD).Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	ranking.Visible = false
end)

local function shopRow(order: number, onBuy: () -> ()): (TextLabel, TextButton)
	local label = make("TextLabel", {
		Size = UDim2.fromScale(0.62, 1),
		BackgroundTransparency = 1,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local buy = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.36, 1),
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
	}, { make("UICorner", {}) })
	make("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = shopPanel }, { label, buy })
	buy.Activated:Connect(onBuy)
	return label, buy
end

local updates: { () -> () } = {}
for key, pass in Products.GamePasses do
	local label, buy = shopRow(pass.Order, function()
		if not owns(key) then
			promptPass(key)
		end
	end)
	label.Text = pass.Name
	table.insert(updates, function()
		buy.Text = if owns(key) then "Comprado" else "Comprar"
		buy.BackgroundColor3 = if owns(key) then DARK else GREEN
	end)
end

local boostLabel, boostButton = shopRow(10, function()
	if Products.Boost.Id == 0 then
		warn("Boost: ID placeholder em Config/Products")
		return
	end
	MarketplaceService:PromptProductPurchase(player, Products.Boost.Id)
end)
boostButton.Text = "Comprar"
boostButton.BackgroundColor3 = GREEN

local function refreshShop()
	for _, update in updates do
		update()
	end
	local left = ((player:GetAttribute("BoostUntil") :: number?) or 0) - workspace:GetServerTimeNow()
	boostLabel.Text = Products.Boost.Name .. (if left > 0 then `\nAtivo: {math.ceil(left / 60)} min` else "")
end
player.AttributeChanged:Connect(refreshShop)
refreshShop()
task.spawn(function()
	while true do
		task.wait(30)
		refreshShop()
	end
end)

-- Ranking semanal
local rankingText = make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	TextColor3 = WHITE,
	Font = Enum.Font.Gotham,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	Parent = ranking,
})
sideButton("Ranking", 158, Color3.fromRGB(150, 60, 60)).Activated:Connect(function()
	ranking.Visible = not ranking.Visible
	shopPanel.Visible = false
end)

local function updateRanking()
	local json = ReplicatedStorage:GetAttribute("WeeklyTop") :: string?
	local lines = { "Ranking semanal (onda · tempo)" }
	local ok, top = pcall(HttpService.JSONDecode, HttpService, json or "[]")
	for i, entry in if ok then top else {} do
		local seconds = entry.seconds :: number
		table.insert(lines, `{i}. {entry.name} · onda {entry.wave} · {seconds // 60}:{string.format("%02d", seconds % 60)}`)
	end
	if #lines == 1 then
		table.insert(lines, "Ainda sem resultados nesta semana.")
	end
	rankingText.Text = table.concat(lines, "\n")
end
ReplicatedStorage:GetAttributeChangedSignal("WeeklyTop"):Connect(updateRanking)
updateRanking()

return {}

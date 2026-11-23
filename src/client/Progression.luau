--!strict
-- Painel de upgrades permanentes e aviso da recompensa diária. O servidor valida a compra.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Progression = require(ReplicatedStorage.Shared.Config.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local make = require(script.Parent.Ui)

local player = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(25, 25, 35)
local GREEN = Color3.fromRGB(40, 120, 70)
local RED = Color3.fromRGB(70, 40, 40)

local ids: { string } = {}
for id in Progression.Upgrades do
	table.insert(ids, id)
end
table.sort(ids, function(a, b)
	return Progression.Upgrades[a].Order < Progression.Upgrades[b].Order
end)

local gui = make("ScreenGui", { Name = "Progression", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })

local function text(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.TextColor3 = WHITE
	props.Font = Enum.Font.GothamBold
	props.TextScaled = true
	return make("TextLabel", props)
end

local pointsLabel = text({ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 28) })
local panel = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -32, 0, 280),
	BackgroundColor3 = DARK,
	Parent = gui,
}, {
	make("UICorner", {}),
	make("UISizeConstraint", { MaxSize = Vector2.new(440, 280) }),
	make("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}),
	make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
	pointsLabel,
})

local openButton = make("TextButton", {
	Text = "Upgrades",
	Position = UDim2.new(0, 8, 0, 50),
	Size = UDim2.fromOffset(110, 30),
	BackgroundColor3 = Color3.fromRGB(90, 60, 150),
	TextColor3 = WHITE,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	Parent = gui,
}, { make("UICorner", {}) })
openButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

local function level(id: string): number
	return (player:GetAttribute("Upgrade_" .. id) :: number?) or 0
end

local rows: { () -> () } = {}
for i, id in ids do
	local def = Progression.Upgrades[id]
	local info = text({ Size = UDim2.fromScale(0.62, 1), TextXAlignment = Enum.TextXAlignment.Left })
	local buy = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.36, 1),
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
	}, { make("UICorner", {}) })
	make("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Parent = panel }, { info, buy })
	buy.Activated:Connect(function()
		Remotes.BuyUpgrade:FireServer(id)
	end)

	table.insert(rows, function()
		local current = level(id)
		local cost = def.Costs[current + 1]
		local missing: string? = nil
		for req, minLevel in def.Requires or {} do
			if level(req) < minLevel then
				missing = `Requer {Progression.Upgrades[req].Name} {minLevel}`
			end
		end
		info.Text = `{def.Name} ({current}/{#def.Costs})\n{def.Description}`
		buy.Text = if not cost then "Máximo" elseif missing then missing else `Comprar\n{cost} pts`
		local points = (player:GetAttribute("Points") :: number?) or 0
		buy.BackgroundColor3 = if cost and not missing and points >= cost then GREEN else RED
	end)
end

local function refresh()
	pointsLabel.Text = `Pontos: {player:GetAttribute("Points") or 0} · Recorde: onda {player:GetAttribute("BestWave") or 0}`
	for _, update in rows do
		update()
	end
end
player.AttributeChanged:Connect(refresh)
refresh()

-- Aviso da recompensa diária
local toast = text({
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 88),
	Size = UDim2.new(1, -32, 0, 30),
	BackgroundTransparency = 0,
	BackgroundColor3 = GREEN,
	Parent = gui,
})
make("UICorner", { Parent = toast })
make("UISizeConstraint", { MaxSize = Vector2.new(440, 30), Parent = toast })

local function showDaily()
	local amount = player:GetAttribute("DailyReward")
	if amount then
		toast.Text = `Recompensa diária: +{amount} pontos (sequência de {player:GetAttribute("DailyStreak") or 1} dias)`
		toast.Visible = true
		task.delay(6, function()
			toast.Visible = false
		end)
	end
end
player:GetAttributeChangedSignal("DailyReward"):Connect(showDaily)
showDaily()

return {}

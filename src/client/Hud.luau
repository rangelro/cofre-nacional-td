--!strict
-- HUD (onda, Cofre, dinheiro, contador), botão Iniciar e tela de fim de partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Waves = require(ReplicatedStorage.Shared.Config.Waves)
local make = require(script.Parent.Ui)

local player = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(25, 25, 35)

local gui = make("ScreenGui", { Name = "Hud", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })

local function box(order: number): TextLabel
	return make("TextLabel", {
		LayoutOrder = order,
		Size = UDim2.fromScale(0.23, 1),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.2,
		TextColor3 = WHITE,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		Text = "",
	}, {
		make("UICorner", {}),
		make("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
		make("UISizeConstraint", { MaxSize = Vector2.new(190, math.huge) }),
	})
end

local waveLabel, vaultLabel, moneyLabel, timerLabel = box(1), box(2), box(3), box(4)
make("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(1, -16, 0, 34),
	Parent = gui,
}, {
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}),
	waveLabel,
	vaultLabel,
	moneyLabel,
	timerLabel,
})

local function updateWave()
	local mutator = ReplicatedStorage:GetAttribute("Mutator")
	waveLabel.Text = `Onda {ReplicatedStorage:GetAttribute("Wave") or 0}` .. (if mutator then ` · {mutator}` else "")
end
local function updateVault()
	vaultLabel.Text = `Cofre {ReplicatedStorage:GetAttribute("VaultHealth") or Waves.VaultHealth}/{Waves.VaultHealth}`
end
local function updateMoney()
	moneyLabel.Text = `$ {player:GetAttribute("Money") or 0}`
end
ReplicatedStorage:GetAttributeChangedSignal("Wave"):Connect(updateWave)
ReplicatedStorage:GetAttributeChangedSignal("Mutator"):Connect(updateWave)
ReplicatedStorage:GetAttributeChangedSignal("VaultHealth"):Connect(updateVault)
player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
updateWave()
updateVault()
updateMoney()

task.spawn(function()
	while true do
		local at = ReplicatedStorage:GetAttribute("NextWaveAt") :: number?
		local left = if at then math.ceil(at - workspace:GetServerTimeNow()) else 0
		timerLabel.Visible = left > 0
		timerLabel.Text = `Próxima: {left}s`
		task.wait(0.25)
	end
end)

-- Botão Iniciar: some para todos quando alguém do grupo inicia
local startButton = make("TextButton", {
	Text = "Iniciar",
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextColor3 = WHITE,
	BackgroundColor3 = Color3.fromRGB(0, 140, 70),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(240, 80),
	Parent = gui,
}, { make("UICorner", {}) })
startButton.Activated:Connect(function()
	Remotes.StartWaves:FireServer()
end)
local function updateStart()
	startButton.Visible = not ReplicatedStorage:GetAttribute("WavesStarted")
end
ReplicatedStorage:GetAttributeChangedSignal("WavesStarted"):Connect(updateStart)
updateStart()

-- Fim de partida
local endText = make("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	TextColor3 = WHITE,
	Font = Enum.Font.GothamBold,
	TextScaled = true,
})
local endFrame = make("Frame", {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(1, -32, 0, 200),
	BackgroundColor3 = DARK,
	Parent = gui,
}, {
	make("UICorner", {}),
	make("UISizeConstraint", { MaxSize = Vector2.new(380, 200) }),
	make("UIPadding", {
		PaddingTop = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
	}),
	endText,
})
local function updateEnd()
	if not ReplicatedStorage:GetAttribute("GameOver") then
		return
	end
	local points = player:GetAttribute("PointsEarned")
	endFrame.Visible = true
	endText.Text = `O Cofre foi saqueado!\nOnda alcançada: {ReplicatedStorage:GetAttribute("Wave") or 0}\nPontos ganhos: {points or "..."}`
end
ReplicatedStorage:GetAttributeChangedSignal("GameOver"):Connect(updateEnd)
player:GetAttributeChangedSignal("PointsEarned"):Connect(updateEnd)
updateEnd()

return {}

--!strict
-- Game Passes (posse em Player "Pass_<chave>"), velocidade da partida e ProcessReceipt.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local function owns(player: Player, passKey: string): boolean
	return player:GetAttribute("Pass_" .. passKey) == true
end

local function checkPasses(player: Player)
	for key, pass in Products.GamePasses do
		if pass.Id ~= 0 then
			local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and owned then
				player:SetAttribute("Pass_" .. key, true)
			end
		end
	end
end
Players.PlayerAdded:Connect(checkPasses)
for _, player in Players:GetPlayers() do
	task.spawn(checkPasses, player)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	for key, pass in Products.GamePasses do
		if pass.Id == passId then
			player:SetAttribute("Pass_" .. key, true)
		end
	end
end)

-- Velocidade vale para a sala toda (co-op). Qualquer um pode voltar para 1x.
Remotes.SetGameSpeed.OnServerEvent:Connect(function(player, speed: any)
	local allowed = speed == 1
		or (speed == 2 and (owns(player, "SpeedX2") or owns(player, "SpeedX3")))
		or (speed == 3 and owns(player, "SpeedX3"))
	if allowed then
		ReplicatedStorage:SetAttribute("GameSpeed", speed)
	end
end)

MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or receipt.ProductId ~= Products.Boost.Id then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local granted = DataService.grantPurchase(player, receipt.PurchaseId, function(data)
		data.BoostUntil = math.max(data.BoostUntil, os.time()) + Products.Boost.Duration
	end)
	return if granted then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
end

return {
	owns = owns,
}

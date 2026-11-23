--!strict
-- Todos os remotes do jogo. O servidor cria, o cliente espera.
local RunService = game:GetService("RunService")

local function get(name: string): RemoteEvent
	local existing = script:FindFirstChild(name)
	if existing or not RunService:IsServer() then
		return (existing or script:WaitForChild(name)) :: RemoteEvent
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = script
	return remote
end

return {
	StartWaves = get("StartWaves"), -- ()
	PlaceTower = get("PlaceTower"), -- (slot: BasePart, towerId: string)
	UpgradeTower = get("UpgradeTower"), -- (tower: BasePart)
	SellTower = get("SellTower"), -- (tower: BasePart)
	SetTargetMode = get("SetTargetMode"), -- (tower: BasePart, mode: string)
	SetGameSpeed = get("SetGameSpeed"), -- (speed: number)
	BuyUpgrade = get("BuyUpgrade"), -- (upgradeId: string)
	TowerFired = get("TowerFired"), -- servidor -> clientes: (tower: BasePart, target: Vector3), só visual
}

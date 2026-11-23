--!strict
-- Torres: colocar, upgrade, vender, modo de alvo e disparo (um único Heartbeat).
-- Tudo que vem do cliente é validado aqui.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Towers = require(ReplicatedStorage.Shared.Config.Towers)
local EconomyConfig = require(ReplicatedStorage.Shared.Config.Economy)
local EnemiesConfig = require(ReplicatedStorage.Shared.Config.Enemies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local Economy = require(script.Parent.Economy)
local DataService = require(script.Parent.DataService)
local Monetization = require(script.Parent.MonetizationService)
local Map = require(script.Parent.Map)
local Clock = require(script.Parent.Clock)

type Enemy = EnemyService.Enemy

type Tower = {
	def: Towers.TowerDef,
	level: number,
	owner: Player,
	slot: BasePart,
	part: BasePart,
	spent: number,
	mode: string,
	cooldown: number,
}

local towers: { [Instance]: Tower } = {} -- chave: Part da torre
local occupied: { [Instance]: boolean } = {} -- chave: slot

local folder = Instance.new("Folder")
folder.Name = "Towers"
folder.Parent = workspace

local function refresh(t: Tower)
	local height = 2 + t.level
	t.part.Size = Vector3.new(3, height, 3)
	t.part.Position = t.slot.Position + Vector3.new(0, t.slot.Size.Y / 2 + height / 2, 0)
	t.part:SetAttribute("Level", t.level)
	t.part:SetAttribute("TargetMode", t.mode)
end

local function ownedTower(player: Player, part: any): Tower?
	local t = if typeof(part) == "Instance" then towers[part] else nil
	return if t and t.owner == player then t else nil
end

Remotes.PlaceTower.OnServerEvent:Connect(function(player, slot: any, towerId: any)
	if typeof(slot) ~= "Instance" or not slot:IsA("BasePart") or slot.Parent ~= Map.slots or occupied[slot] then
		return
	end
	if slot:GetAttribute("Premium") and not Monetization.owns(player, "SlotExtra") then
		return
	end
	local def = if typeof(towerId) == "string" then Towers.Types[towerId] else nil
	if not def or not Economy.spend(player, def.Levels[1].Cost) then
		return
	end

	local part = Instance.new("Part")
	part.Name = def.Name
	part.Anchored = true
	part.Color = def.Color
	part:SetAttribute("TowerId", towerId)
	part:SetAttribute("Owner", player.UserId)
	local t: Tower = {
		def = def,
		level = 1,
		owner = player,
		slot = slot,
		part = part,
		spent = def.Levels[1].Cost,
		mode = Towers.TargetModes[1],
		cooldown = 0,
	}
	refresh(t)
	part.Parent = folder
	towers[part] = t
	occupied[slot] = true
end)

Remotes.UpgradeTower.OnServerEvent:Connect(function(player, part: any)
	local t = ownedTower(player, part)
	local nextLevel = t and t.def.Levels[t.level + 1]
	if t and nextLevel and Economy.spend(player, nextLevel.Cost) then
		t.level += 1
		t.spent += nextLevel.Cost
		refresh(t)
	end
end)

Remotes.SellTower.OnServerEvent:Connect(function(player, part: any)
	local t = ownedTower(player, part)
	if t then
		towers[t.part] = nil
		occupied[t.slot] = nil
		t.part:Destroy()
		Economy.add(player, math.floor(t.spent * EconomyConfig.SellRefund))
	end
end)

Remotes.SetTargetMode.OnServerEvent:Connect(function(player, part: any, mode: any)
	local t = ownedTower(player, part)
	if t and table.find(Towers.TargetModes, mode) then
		t.mode = mode
		refresh(t)
	end
end)

-- Buff de dano e detecção vindos de Lupas próximas (vale o maior buff, não acumula)
local function support(t: Tower): (number, boolean)
	local mult, detects = 1, t.def.Detects == true
	for _, other in towers do
		local s = other.def.Levels[other.level]
		if other ~= t and s.BuffRadius and (other.part.Position - t.part.Position).Magnitude <= s.BuffRadius then
			mult = math.max(mult, 1 + (s.BuffDamage or 0))
			detects = detects or other.def.GrantsDetection == true
		end
	end
	return mult, detects
end

local function findTarget(t: Tower, range: number, detects: boolean): Enemy?
	local pos = t.part.Position
	local best: Enemy? = nil
	local bestScore = -math.huge
	for _, e in EnemyService.all() do
		local dist = (e.part.Position - pos).Magnitude
		if dist <= range and (detects or not e.def.Invisible) then
			local score = if t.mode == "Strongest" then e.health elseif t.mode == "Closest" then -dist else e.distance
			if score > bestScore then
				best, bestScore = e, score
			end
		end
	end
	return best
end

-- Retorna o dano refletido total
local function fire(t: Tower, target: Enemy, mult: number, detects: boolean): number
	local s = t.def.Levels[t.level]
	local hits = { target }
	if s.Splash then
		hits = {}
		for _, e in EnemyService.all() do
			if (e.part.Position - target.part.Position).Magnitude <= s.Splash then
				table.insert(hits, e)
			end
		end
	end

	Remotes.TowerFired:FireAllClients(t.part, target.part.Position)
	local reflected = 0
	local permanent = 1 + DataService.bonus(t.owner, "TowerDamage")
	for _, e in hits do
		local damage = s.Damage * mult * permanent
		if s.BossMult and e.def == EnemiesConfig.Boss then
			damage *= s.BossMult
		end
		local r, killed = EnemyService.damage(e, damage, detects)
		reflected += r
		if killed then
			Economy.add(t.owner, e.reward)
		else
			if s.Stun then
				EnemyService.slow(e, 1, s.Stun)
			end
			if s.Slow then
				EnemyService.slow(e, s.Slow, s.SlowDuration or 1)
			end
		end
	end
	return reflected
end

RunService.Heartbeat:Connect(function(realDt)
	local dt = realDt * Clock.speed()
	for _, t in towers do
		t.cooldown -= dt
		if t.cooldown <= 0 then
			local s = t.def.Levels[t.level]
			local mult, detects = support(t)
			local target = findTarget(t, s.Range, detects)
			if target then
				local reflected = fire(t, target, mult, detects)
				t.cooldown = s.Cooldown + reflected * Towers.ReflectSecondsPerDamage
			end
		end
	end
end)

return {}

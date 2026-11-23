--!strict
-- Estado de todos os inimigos, movimento (um único Heartbeat), habilidades e vida do Cofre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EnemiesConfig = require(ReplicatedStorage.Shared.Config.Enemies)
local Waves = require(ReplicatedStorage.Shared.Config.Waves)
local Map = require(script.Parent.Map)
local Clock = require(script.Parent.Clock)

type EnemyDef = EnemiesConfig.EnemyDef
type Mutator = Waves.Mutator

export type Scale = { Health: number, Speed: number, Reward: number }

export type Enemy = {
	def: EnemyDef,
	scale: Scale,
	mutator: Mutator?,
	part: BasePart,
	offset: CFrame,
	health: number,
	maxHealth: number,
	shield: number,
	speed: number,
	reward: number,
	distance: number,
	alive: boolean,
	healTimer: number,
	phase: number,
	phaseTimer: number,
	slowFactor: number,
	slowTimer: number,
}

local EnemyService = {}
EnemyService.gameOver = false

local enemies: { Enemy } = {}
local vaultHealth = Waves.VaultHealth
ReplicatedStorage:SetAttribute("VaultHealth", vaultHealth)

local folder = Instance.new("Folder")
folder.Name = "Enemies"
folder.Parent = workspace

local function setHealth(e: Enemy, h: number)
	e.health = math.clamp(h, 0, e.maxHealth)
	local shown = math.ceil(e.health)
	if e.part:GetAttribute("Health") ~= shown then
		e.part:SetAttribute("Health", shown)
	end
end

local function remove(e: Enemy)
	if not e.alive then
		return
	end
	e.alive = false
	local i = table.find(enemies, e)
	if i then
		enemies[i] = enemies[#enemies]
		enemies[#enemies] = nil
	end
	e.part:Destroy()
end

local function isImmune(e: Enemy): boolean
	local phases = e.def.Phases
	return phases ~= nil and phases[e.phase].Immune == true
end

local function hitVault(damage: number)
	vaultHealth = math.max(vaultHealth - damage, 0)
	ReplicatedStorage:SetAttribute("VaultHealth", vaultHealth)
	if vaultHealth == 0 then
		EnemyService.gameOver = true
		ReplicatedStorage:SetAttribute("GameOver", true)
		for i = #enemies, 1, -1 do
			remove(enemies[i])
		end
	end
end

local function healArea(healer: Enemy)
	local radius = healer.def.HealRadius or 0
	local amount = healer.def.HealPercent or 0
	local pos = healer.part.Position
	for _, e in enemies do
		if (e.part.Position - pos).Magnitude <= radius then
			setHealth(e, e.health + e.maxHealth * amount)
		end
	end
end

function EnemyService.spawn(def: EnemyDef, scale: Scale, mutator: Mutator?, distance: number?): Enemy
	local maxHealth = math.ceil(def.Health * scale.Health)
	local size = def.Size or 2
	local phases = def.Phases

	local part = Instance.new("Part")
	part.Name = def.Name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Size = Vector3.one * size
	part.Color = def.Color
	part.Transparency = if def.Invisible then 0.7 else 0
	part:SetAttribute("MaxHealth", maxHealth)
	part:SetAttribute("Health", maxHealth)
	if phases then
		part:SetAttribute("Phase", phases[1].Name)
	end

	local e: Enemy = {
		def = def,
		scale = scale,
		mutator = mutator,
		part = part,
		offset = CFrame.new(0, size / 2, 0),
		health = maxHealth,
		maxHealth = maxHealth,
		shield = maxHealth * (mutator and mutator.Shield or 0),
		speed = def.Speed * scale.Speed,
		reward = math.floor(def.Reward * scale.Reward),
		distance = distance or 0,
		alive = true,
		healTimer = def.HealInterval or 0,
		phase = 1,
		phaseTimer = if phases then phases[1].Duration else 0,
		slowFactor = 0,
		slowTimer = 0,
	}
	part.CFrame = Map.cframeAt(e.distance) * e.offset
	part.Parent = folder
	table.insert(enemies, e)
	return e
end

local function kill(e: Enemy)
	remove(e)
	local child = e.def.SplitInto and EnemiesConfig.Types[e.def.SplitInto]
	if child then
		for k = 1, e.def.SplitCount or 2 do
			EnemyService.spawn(child, e.scale, e.mutator, math.max(e.distance - k * 2, 0))
		end
	end
end

-- Aplica dano. detects = a torre enxerga invisíveis.
-- Retorna o dano refletido (Rachadinha Man) e se o inimigo morreu.
function EnemyService.damage(e: Enemy, amount: number, detects: boolean?): (number, boolean)
	if not e.alive or (e.def.Invisible and not detects) or isImmune(e) then
		return 0, false
	end
	local reflected = amount * (e.def.Reflect or 0)
	local m = e.mutator
	if m and m.Armor then
		amount *= 1 - m.Armor
	end
	local absorbed = math.min(e.shield, amount)
	e.shield -= absorbed
	setHealth(e, e.health - (amount - absorbed))
	if e.health <= 0 then
		kill(e)
		return reflected, true
	end
	return reflected, false
end

-- factor 1 = stun. Lentidão mais forte substitui a atual; mais fraca só vale se a atual acabou.
function EnemyService.slow(e: Enemy, factor: number, duration: number)
	if not e.alive or isImmune(e) then
		return
	end
	if factor >= e.slowFactor or e.slowTimer <= 0 then
		e.slowFactor = factor
		e.slowTimer = duration
	end
end

function EnemyService.all(): { Enemy }
	return enemies
end

function EnemyService.count(): number
	return #enemies
end

RunService.Heartbeat:Connect(function(realDt: number)
	local dt = realDt * Clock.speed()
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	-- De trás pra frente: remove() troca com o último, que já foi processado
	for i = #enemies, 1, -1 do
		local e = enemies[i]
		local speedMult = 1

		local phases = e.def.Phases
		if phases then
			e.phaseTimer -= dt
			if e.phaseTimer <= 0 then
				e.phase = e.phase % #phases + 1
				e.phaseTimer = phases[e.phase].Duration
				e.part:SetAttribute("Phase", phases[e.phase].Name)
			end
			speedMult = phases[e.phase].SpeedMult or 1
		end

		if e.slowTimer > 0 then
			e.slowTimer -= dt
			speedMult *= 1 - e.slowFactor
		end

		local m = e.mutator
		if m and m.Regen and e.health < e.maxHealth then
			setHealth(e, e.health + e.maxHealth * m.Regen * dt)
		end

		if e.def.HealInterval then
			e.healTimer -= dt
			if e.healTimer <= 0 then
				e.healTimer = e.def.HealInterval
				healArea(e)
			end
		end

		e.distance += e.speed * speedMult * dt
		if e.distance >= Map.length then
			remove(e)
			hitVault(e.def.VaultDamage)
			if EnemyService.gameOver then
				return
			end
		else
			table.insert(parts, e.part)
			table.insert(cframes, Map.cframeAt(e.distance) * e.offset)
		end
	end
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end)

return EnemyService

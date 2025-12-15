-- ServerStorage/Abilities/BaseSpell.lua
local BaseSpell = {}
BaseSpell.__index = BaseSpell

local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local damageModule = require(ServerScriptService.DamageModule)
local PlayerData = Modules.Get("PlayerData")

-- Constructor
function BaseSpell.new(config)
    -- config: {Name, ModelName, BaseDamage, BaseCooldown}
    local self = setmetatable({}, BaseSpell)

    self.Name = config.Name
    self.ModelName = config.ModelName
    self.BaseDamage = config.BaseDamage or 0
    self.BaseCooldown = config.BaseCooldown or 1
    self.DebrisTimer = config.DebrisTimer or 1

    return self
end

-- Override ↓ for spell-specific behaviour
function BaseSpell:OnCast(player, mousePos, stats, model)
    -- Default: nothing
end

-- Utility: spawns the projectile & sets velocity
function BaseSpell:SpawnProjectile(modelName, cframe, speed)
    local part = ServerStorage.Abilities:FindFirstChild(modelName):Clone()
    part.CFrame = cframe
    part.Parent = workspace

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = part.CFrame.LookVector * speed
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = part

    return part
end

function BaseSpell:SpawnAttack(modelName, cframe)
    local part = ServerStorage.Abilities:FindFirstChild(modelName):Clone()
    part.CFrame = cframe
    part.Parent = workspace

    return part
end

-- Default hit handling (can be overridden)
function BaseSpell:OnHit(hit, damage)
    local character = hit.Parent
    if not character then return end
    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end

    local player = Players:GetPlayerFromCharacter(character)
    if player then
        print("Hit player:", player.Name)
    else
        hum.Health -= damage
    end
end

-- Main activation entry
function BaseSpell:Activate(player, mousePos, stats)
    -- print(player.Name .. " used " .. self.Name .. "!")

    -- Calculate actual cooldown
    self.Cooldown = self.BaseCooldown * math.clamp(10 - (stats.cooldownReduction/100), 0, 1)

    -- Damage calculation
    local damage = damageModule.CalculateDamage(self.BaseDamage, stats)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Let the spell-specific subclass run its custom logic
    return self:OnCast(player, mousePos, stats, damage)
end

return BaseSpell

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
local BaseEnemy = Modules.Get("BaseEnemy")
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
-- stacks = number of times the ability has been purchased (1 = base)
function BaseSpell:OnCast(player, mousePos, stats, damage, stacks)
    -- Default: nothing
end

-- Utility: spawns the projectile & sets velocity
function BaseSpell:SpawnProjectile(modelName, cframe, speed, mousePos)
    local part = ServerStorage.Abilities:FindFirstChild(modelName):Clone()

    -- Create a look-at CFrame
    local origin = cframe.Position
    local target = Vector3.new(mousePos.X, origin.Y, mousePos.Z)
    local lookCFrame = CFrame.lookAt(origin, target)

    part.CFrame = lookCFrame
    part.Parent = workspace

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = lookCFrame.LookVector * speed
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = part

    return part
end


-- Utility: spawns the spell in front of player
function BaseSpell:SpawnAttack(modelName, cframe)
    local part = ServerStorage.Abilities:FindFirstChild(modelName):Clone()
    part.CFrame = cframe
    part.Parent = workspace

    return part
end

function BaseSpell:SpawnAttackAtMouse(modelName, mousePos)
    -- print(mousePos)
    local part = ServerStorage.Abilities:FindFirstChild(modelName):Clone()
    part.Position = mousePos.Position
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
        local target = BaseEnemy.GetFromHumanoid(hum)
        target:TakeDamage(damage)
    end
end

-- Main activation entry
-- stacks = number of times the ability was purchased (passed from AbilityHandler)
function BaseSpell:Activate(player, mousePos, stats, stacks)
    stacks = stacks or 1

    -- Calculate actual cooldown
    self.Cooldown = self.BaseCooldown * math.clamp(10 - (stats.cooldownReduction/100), 0, 1)

    -- Base damage, then scale by purchase count (+25% per additional stack)
    local damage = damageModule.CalculateDamage(self.BaseDamage, stats)
    local stackMultiplier = 1 + (stacks - 1) * 0.25
    damage = math.floor(damage * stackMultiplier)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Forward stacks to OnCast so individual abilities can scale their own effects
    return self:OnCast(player, mousePos, stats, damage, stacks)
end

return BaseSpell

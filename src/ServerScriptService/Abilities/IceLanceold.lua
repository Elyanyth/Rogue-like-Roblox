-- ServerScriptService/Abilities/IceLance.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local ItemManager = Modules.Get("ItemManager")

-- Configure this spell
local IceLance = BaseSpell.new({
    Name = "IceLance",
    ModelName = "IceLance", -- expects a model/part named "IceLance" under ServerStorage/Abilities
    BaseDamage = 35,         -- base damage before strength & crit scaling
    BaseCooldown = 4,        -- seconds
    DebrisTimer = 3          -- how long the projectile stays in the world
})

-- Extra per‑spell settings
IceLance.SlowAmount = 0.5     -- 50% slow
IceLance.SlowDuration = 2.5   -- seconds
IceLance.ProjectileSpeed = 90 -- studs/second

-- Optional: apply item modifiers for this spell
local function applyItemModifiers(player, spell)
    local modifiers = ItemManager and ItemManager:GetSpellModifiers(player, spell.Name) or {}

    local slowAmount = spell.SlowAmount
    local slowDuration = spell.SlowDuration

    for _, mod in ipairs(modifiers) do
        local data = mod.data
        local stacks = mod.stacks or 1

        if data.SlowAmountMultiplier then
            slowAmount = slowAmount * data.SlowAmountMultiplier(stacks)
        end
        if data.SlowDurationMultiplier then
            slowDuration = slowDuration * data.SlowDurationMultiplier(stacks)
        end
    end

    return slowAmount, slowDuration
end

-- Override OnHit to add a slow on enemies
function IceLance:OnHit(hit, damage)
    local character = hit.Parent
    if not character then return end

    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end

    local player = Players:GetPlayerFromCharacter(character)

    -- Deal damage using the base behaviour for both players and enemies
    hum:TakeDamage(damage)

    -- Only slow non‑player enemies (so we don't grief other players unless desired)
    if player then
        return
    end

    -- Apply slow
    local originalSpeed = hum.WalkSpeed
    local slowAmount, slowDuration = self.SlowAmount, self.SlowDuration

    -- Clamp slow to avoid negative or zero speed
    slowAmount = math.clamp(slowAmount or 0.5, 0, 0.95)
    slowDuration = slowDuration or 2

    local newSpeed = originalSpeed * (1 - slowAmount)
    hum.WalkSpeed = newSpeed

    -- Restore speed after duration, if the humanoid is still alive
    task.delay(slowDuration, function()
        if hum and hum.Parent and hum.Health > 0 then
            hum.WalkSpeed = originalSpeed
        end
    end)
end

-- Override OnCast: fire a single projectile towards the mouse
function IceLance:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Make sure our IceLance projectile exists
    if not ServerStorage:FindFirstChild("Abilities") or not ServerStorage.Abilities:FindFirstChild(self.ModelName) then
        warn("IceLance projectile model '" .. self.ModelName .. "' not found in ServerStorage.Abilities")
        return
    end

    -- Aim from player toward mouse position (flattened on Y so it travels horizontally)
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0, 0, -5)

    local projectile = self:SpawnProjectile(self.ModelName, spawnCF, self.ProjectileSpeed)

    -- Apply item‑based slow modifiers per cast
    local slowAmount, slowDuration = applyItemModifiers(player, self)

    -- Track what we've already hit so this stays single‑target
    local hitEntities = {}

    projectile.Touched:Connect(function(hit)
        local character = hit.Parent
        if not character then return end
        local hum = character:FindFirstChild("Humanoid")
        if not hum then return end

        if hitEntities[character] then return end
        hitEntities[character] = true

        -- Temporarily override the spell's slow values for this hit
        local oldSlowAmount = self.SlowAmount
        local oldSlowDuration = self.SlowDuration
        self.SlowAmount = slowAmount
        self.SlowDuration = slowDuration

        -- Use our overridden OnHit (which also slows enemies)
        self:OnHit(hit, damage)

        -- Restore defaults so other casts are not affected
        self.SlowAmount = oldSlowAmount
        self.SlowDuration = oldSlowDuration

        -- Destroy the projectile on first valid hit (single target)
        projectile:Destroy()
    end)

    Debris:AddItem(projectile, self.DebrisTimer)
end

return IceLance

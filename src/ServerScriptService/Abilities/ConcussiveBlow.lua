-- ServerScriptService/Abilities/ConcussiveBlow.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local ItemManager = Modules.Get("ItemManager")

-- Configure this spell
local ConcussiveBlow = BaseSpell.new({
    Name = "ConcussiveBlow",
    ModelName = "ConcussiveBlow", -- expects a visual part/model in ServerStorage/Abilities
    BaseDamage = 40,              -- base damage, scales with strength via DamageModule
    BaseCooldown = 6,             -- seconds
    DebrisTimer = 0.5             -- visual lifetime
})

-- Per-spell defaults
ConcussiveBlow.Radius = 10       -- studs
ConcussiveBlow.StunDuration = 2  -- seconds

-- Optional: item modifiers can affect radius and stun duration
local function applyItemModifiers(player, spell)
    local modifiers = ItemManager and ItemManager:GetSpellModifiers(player, spell.Name) or {}

    local radius = spell.Radius
    local stunDuration = spell.StunDuration

    for _, mod in ipairs(modifiers) do
        local data = mod.data
        local stacks = mod.stacks or 1

        if data.RadiusMultiplier then
            radius = radius * data.RadiusMultiplier(stacks)
        end
        if data.DurationMultiplier then
            stunDuration = stunDuration * data.DurationMultiplier(stacks)
        end
    end

    return radius, stunDuration
end

-- Optional: override OnHit if you later want hit-based logic.
-- For now we do everything in OnCast's AOE loop.
function ConcussiveBlow:OnHit(hit, damage)
    -- Intentionally unused; AOE logic is handled in OnCast
end

-- Main spell logic: AOE in front of the player that stuns enemies
function ConcussiveBlow:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Check visual asset
    if not ServerStorage:FindFirstChild("Abilities") or not ServerStorage.Abilities:FindFirstChild(self.ModelName) then
        warn("ConcussiveBlow model '" .. self.ModelName .. "' not found in ServerStorage.Abilities")
        return
    end

    -- Spawn the hitbox/visual in front of the player, oriented toward mouse
    local facingCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    )

    local spawnCF = facingCF * CFrame.new(0, 0, -5) -- 5 studs in front
    local aoePart = self:SpawnAttack(self.ModelName, spawnCF)
    aoePart.Anchored = true
    aoePart.CanCollide = false

    -- Apply item-based modifiers
    local radius, stunDuration = applyItemModifiers(player, self)

    -- Find enemies in front (around the AOE part)
    local center = aoePart.Position
    local parts = workspace:GetPartBoundsInRadius(center, radius)
    local processedCharacters = {}

    for _, part in ipairs(parts) do
        local character = part.Parent
        if character and not processedCharacters[character] then
            processedCharacters[character] = true

            local hum = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if hum and rootPart and hum.Health > 0 then
                local owningPlayer = Players:GetPlayerFromCharacter(character)
                -- Only affect enemies (non-player characters)
                if not owningPlayer then
                    -- Deal damage that already scales with strength & crit (DamageModule)
                    hum:TakeDamage(damage)

                    -- Stun: set WalkSpeed to 0 and restore after duration
                    local originalSpeed = hum.WalkSpeed
                    hum.WalkSpeed = 0

                    task.delay(stunDuration, function()
                        if hum and hum.Parent and hum.Health > 0 then
                            hum.WalkSpeed = originalSpeed
                        end
                    end)
                end
            end
        end
    end

    -- Clean up the visual
    Debris:AddItem(aoePart, self.DebrisTimer)
end

return ConcussiveBlow
-- ServerStorage/Abilities/Fireball.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local EffectManager = Modules.Get("EffectManager")
local Slowness = Modules.Get("Slowness")
local damageModule = Modules.Get("DamageModule")
local PlayerData = Modules.Get("PlayerData")
local ItemManager = Modules.Get("ItemManager")

-- Setup config for this spell
local Spell = BaseSpell.new({
    Name = "IceSpear",
    ModelName = "IceSpear",
    BaseDamage = 35,
    BaseCooldown = 3,
    DebrisTimer = 3
})

-- Extra per‑spell settings
Spell.SlowAmount = 0.5     -- 50% slow
Spell.SlowDuration = 2.5   -- seconds
Spell.ProjectileSpeed = 90 -- studs/second

-- Override OnHit to add a slow on enemies
function Spell:OnHit(hit, damage)
    local character = hit.Parent
    if not character then return end
    local hum = character:FindFirstChild("Humanoid")
    if not hum then return end

    local player = Players:GetPlayerFromCharacter(character)
    if player then -- only slow and damage non players
        print("Hit player:", player.Name)
        return
    else
        hum.Health -= damage
    end

    -- Apply Slowness

    local slow = Slowness.new({
        Target = hum,
        Magnitude = 0.3,
        Duration = 4
    })

    EffectManager.ApplyEffect(slow)
end


-- Override OnCast (unique Fireball behavior)
function Spell:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character.HumanoidRootPart

    -- -- Extra: scaling based on Wizard Cap
    -- local modifiers = ItemManager:GetSpellModifiers(player, self.Name)

    -- local sizeMultiplier = 1

    -- for _, mod in ipairs(modifiers) do
    --     if mod.data.SizeMultiplier then
    --         sizeMultiplier *= mod.data.SizeMultiplier(mod.stacks)
    --     end
    -- end

    -- Spawn projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0,0,-5)

    local part = self:SpawnProjectile(self.ModelName, spawnCF, 90, mousePos)

    -- Apply size multiplier
    -- part.Size *= sizeMultiplier

    -- Prevent multi-hit
    local hitEntities = {}

    part.Touched:Connect(function(hit)
        local character = hit.Parent
        if character and character:FindFirstChild("Humanoid") then
            
            if hitEntities[character] then return end
            hitEntities[character] = true

            -- Use the BaseSpell hit logic
            self:OnHit(hit, damage)
        end
    end)

    Debris:AddItem(part, self.DebrisTimer)
end

return Spell

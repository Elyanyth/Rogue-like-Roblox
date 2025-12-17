-- ServerStorage/Abilities/Fireball.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local damageModule = Modules.Get("DamageModule")
local PlayerData = Modules.Get("PlayerData")
local ItemManager = Modules.Get("ItemManager")

-- Setup config for this spell
local Fireball = BaseSpell.new({
    Name = "Fireball",
    ModelName = "Fireball",
    BaseDamage = 50,
    BaseCooldown = 5,
    DebrisTimer = 3
})

-- Override OnCast (unique Fireball behavior)
function Fireball:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character.HumanoidRootPart

    -- Extra: scaling based on Wizard Cap
    local modifiers = ItemManager:GetSpellModifiers(player, self.Name)

    local sizeMultiplier = 1

    for _, mod in ipairs(modifiers) do
        if mod.data.SizeMultiplier then
            sizeMultiplier *= mod.data.SizeMultiplier(mod.stacks)
        end
    end

    -- Spawn fireball projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0,0,-5)

    local part = self:SpawnProjectile(self.ModelName, spawnCF, 80, mousePos)

    -- Apply size multiplier
    part.Size *= sizeMultiplier

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

return Fireball

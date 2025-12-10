-- ServerStorage/Abilities/Fireball.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local damageModule = Modules.Get("DamageModule")
local PlayerData = Modules.Get("PlayerData")

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
    local WizardCaps = PlayerData.GetItem(player, "Wizard Cap") or 0
    local multiplier = WizardCaps > 0 and math.max(1, 1 + (WizardCaps / 10)) or 1

    -- Spawn fireball projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0,0,-5)

    local part = self:SpawnProjectile(self.ModelName, spawnCF, 80)

    -- Apply size multiplier
    if typeof(multiplier) == "number" and multiplier > 0 then
        part.Size = part.Size * multiplier
    end

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

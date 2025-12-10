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
local PrimaryAttack = BaseSpell.new({
    Name = "PrimaryAttack",
    ModelName = "PrimaryAttack",
    BaseDamage = 20,
    BaseCooldown = 0.5,
    DebrisTimer = 0.25
})

-- Override OnCast (unique Fireball behavior)
function PrimaryAttack:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character.HumanoidRootPart

    -- Spawn fireball projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0,0,-5)

    local part = self:SpawnAttack(self.ModelName, spawnCF)

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

return PrimaryAttack

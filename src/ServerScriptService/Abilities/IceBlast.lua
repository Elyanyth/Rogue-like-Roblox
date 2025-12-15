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
    Name = "IceBlast",
    ModelName = "IceBlast",
    BaseDamage = 100,
    BaseCooldown = 10,
    DebrisTimer = 0.5
})

-- Override OnCast (unique Fireball behavior)
function Fireball:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character.HumanoidRootPart

    -- Extra: scaling based on Wizard Cap
    local WizardCaps = PlayerData.GetItem(player, "Wizard Cap") or 0
	local cap = tonumber(WizardCaps) or 0

	local multiplier = cap > 0 and (1 + cap / 10) or 1

    -- Spawn fireball projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0,0,-5)

    local part = self:SpawnAttackAtMouse(self.ModelName, mousePos)

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

-- ServerStorage/Abilities/Fireball.lua
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local ItemManager = Modules.Get("ItemManager")

-- ===============================
-- CONFIGURATION
-- ===============================
local PROJECTILE_SIZE   = 2    -- diameter of the traveling ball (studs)
local EXPLOSION_SIZE    = 10   -- diameter of the explosion sphere at peak (studs)
local EXPAND_TIME       = 0.3  -- seconds to balloon from small → explosion
local FADE_TIME         = 0.25 -- seconds to fade out after fully expanded

local Fireball = BaseSpell.new({
    Name = "Fireball",
    ModelName = "Fireball",
    BaseDamage = 50,
    BaseCooldown = 5,
    DebrisTimer = 3
})

function Fireball:OnCast(player, mousePos, _, damage, _)
    local character = player.Character
    local root = character.HumanoidRootPart

    -- WizardCap (or other item) size modifier — only scales the explosion, not the projectile
    -- mod.stacks is an array returned by PlayerData.GetItem; index [1] is the actual count
    local modifiers = ItemManager:GetSpellModifiers(player, self.Name)
    local sizeMultiplier = 1
    for _, mod in ipairs(modifiers) do
        if mod.data.SizeMultiplier then
            sizeMultiplier *= mod.data.SizeMultiplier(mod.stacks[1])
        end
    end

    local projSize      = PROJECTILE_SIZE               -- always small regardless of upgrades
    local explodeSize   = EXPLOSION_SIZE * sizeMultiplier
    local explodeRadius = explodeSize / 2

    -- Spawn small projectile
    local spawnCF = CFrame.new(
        root.Position,
        Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)
    ) * CFrame.new(0, 0, -5)

    local part = self:SpawnProjectile(self.ModelName, spawnCF, 80, mousePos)
    part.Size = Vector3.new(projSize, projSize, projSize)

    local exploded = false

    part.Touched:Connect(function(hit)
        if exploded then return end

        -- Only trigger on non-player characters that have a Humanoid
        local hitCharacter = hit.Parent
        if not hitCharacter or not hitCharacter:FindFirstChild("Humanoid") then return end
        if Players:GetPlayerFromCharacter(hitCharacter) then return end

        exploded = true

        -- Freeze the projectile in place
        local bv = part:FindFirstChildOfClass("BodyVelocity")
        if bv then bv:Destroy() end
        part.Anchored = true
        part.CanCollide = false

        local hitPos = part.Position

        -- Damage every enemy inside the explosion radius
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Humanoid") then
                local enemyChar = obj.Parent
                if enemyChar and not Players:GetPlayerFromCharacter(enemyChar) then
                    local rootPart = enemyChar:FindFirstChild("HumanoidRootPart")
                    if rootPart and (rootPart.Position - hitPos).Magnitude <= explodeRadius then
                        self:OnHit(rootPart, damage)
                    end
                end
            end
        end

        -- Balloon to full explosion size
        local expandTween = TweenService:Create(
            part,
            TweenInfo.new(EXPAND_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = Vector3.new(explodeSize, explodeSize, explodeSize) }
        )
        expandTween:Play()

        -- Once fully expanded, fade out and clean up
        expandTween.Completed:Connect(function()
            TweenService:Create(
                part,
                TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear),
                { Transparency = 1 }
            ):Play()
            Debris:AddItem(part, FADE_TIME)
        end)
    end)

    -- Safety cleanup if the fireball never hits anything
    Debris:AddItem(part, self.DebrisTimer)
end

return Fireball

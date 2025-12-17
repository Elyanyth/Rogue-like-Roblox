-- ServerScriptService/Abilities/Whirlpool.lua
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local BaseSpell = Modules.Get("BaseAbility")
local ItemManager = Modules.Get("ItemManager")

-- Configure this spell
local Whirlpool = BaseSpell.new({
    Name = "Whirlpool",
    ModelName = "Whirlpool", -- expects a part/model named "Whirlpool" in ServerStorage/Abilities
    BaseDamage = 0,            -- does no damage
    BaseCooldown = 8,          -- seconds
    DebrisTimer = 5            -- fallback lifetime for the visual
})

-- Per‑spell defaults
Whirlpool.Radius = 10        -- studs
Whirlpool.Duration = 4       -- seconds
Whirlpool.SlowAmount = 0.5   -- 50% slow
Whirlpool.PullStrength = 60  -- horizontal pull velocity strength

-- Apply item modifiers (radius/duration/slow) if defined in item modules
local function applyItemModifiers(player, spell)
    local modifiers = ItemManager and ItemManager:GetSpellModifiers(player, spell.Name) or {}

    local radius = spell.Radius
    local duration = spell.Duration
    local slowAmount = spell.SlowAmount

    for _, mod in ipairs(modifiers) do
        local data = mod.data
        local stacks = mod.stacks or 1

        if data.RadiusMultiplier then
            radius = radius * data.RadiusMultiplier(stacks)
        end
        if data.DurationMultiplier then
            duration = duration * data.DurationMultiplier(stacks)
        end
        if data.SlowAmountMultiplier then
            slowAmount = slowAmount * data.SlowAmountMultiplier(stacks)
        end
    end

    return radius, duration, slowAmount
end

-- Override OnHit so this spell never applies damage via the default handler
function Whirlpool:OnHit(hit, damage)
    -- Intentionally no damage; all effects are handled in the AoE loop
end

-- Main spell logic
function Whirlpool:OnCast(player, mousePos, stats, damage)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Ensure the visual asset exists
    if not ServerStorage:FindFirstChild("Abilities") or not ServerStorage.Abilities:FindFirstChild(self.ModelName) then
        warn("Whirlpool model '" .. self.ModelName .. "' not found in ServerStorage.Abilities")
        return
    end

    -- Spawn the whirlpool visual at the mouse position
    local whirlpoolPart = self:SpawnAttackAtMouse(self.ModelName, mousePos)
    whirlpoolPart.Anchored = true
    whirlpoolPart.CanCollide = false
    

    -- Apply item-based modifiers
    local radius, duration, slowAmount = applyItemModifiers(player, self)

    radius = whirlpoolPart.size.Y / 2 -- OVERIDES RADUIS ATM!!!!! ----------------------------------------------------------------------------------------------------

    -- Clamp slow between 0 and 95%
    slowAmount = math.clamp(slowAmount or 0.5, 0, 0.95)

    local startTime = os.clock()
    local affected = {} -- [Humanoid] = { originalSpeed = number }
    local position = whirlpoolPart.Position

    -- Heartbeat loop: pull & slow enemies inside the radius
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        local elapsed = os.clock() - startTime
        if elapsed >= duration then
            -- Cleanup: restore speeds and destroy part
            if connection then
                connection:Disconnect()
            end

            for hum, data in pairs(affected) do
                if hum and hum.Parent and hum.Health > 0 then
                    hum.WalkSpeed = data.originalSpeed
                end
            end

            if whirlpoolPart and whirlpoolPart.Parent then
                whirlpoolPart:Destroy()
            end

            return
        end

        -- Update cached position in case the part was moved externally
        position = whirlpoolPart.Position

        -- Find nearby parts and filter to enemy humanoids (non-player)
        local parts = workspace:GetPartBoundsInRadius(position, radius)
        local seenCharacters = {}

        for _, part in ipairs(parts) do
            local character = part.Parent
            if character and not seenCharacters[character] then
                seenCharacters[character] = true

                local hum = character:FindFirstChild("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if hum and rootPart and hum.Health > 0 then
                    local owningPlayer = Players:GetPlayerFromCharacter(character)
                    if not owningPlayer then
                        -- Apply slow once
                        if not affected[hum] then
                            affected[hum] = { originalSpeed = hum.WalkSpeed }
                            hum.WalkSpeed = hum.WalkSpeed * (1 - slowAmount)
                        end

                        -- Pull towards center
                        local toCenter = position - rootPart.Position
                        local distance = toCenter.Magnitude
                        if distance > 0.1 then
                            local dir = toCenter.Unit
                            -- Keep vertical velocity mostly unchanged; pull horizontally
                            local currentVel = rootPart.AssemblyLinearVelocity
                            rootPart.AssemblyLinearVelocity = Vector3.new(
                                dir.X * Whirlpool.PullStrength,
                                currentVel.Y,
                                dir.Z * Whirlpool.PullStrength
                            )
                        end
                    end
                end
            end
        end
    end)

    -- Safety cleanup in case something goes wrong
    Debris:AddItem(whirlpoolPart, duration + 1)
end

return Whirlpool

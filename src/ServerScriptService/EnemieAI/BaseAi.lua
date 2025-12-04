local BaseEnemie = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local CHASE_RANGE = 1000
local SPEED = 12
local DAMAGE = 20
local HEALTH = 100
local ATTACK_RANGE = 2
local ATTACK_COOLDOWN = 1

-- Modules
local enemyTypes = require(ServerScriptService.EnemieAI:WaitForChild("enemyTypes")) 

function BaseEnemie.Active(enemy, enemyType)
    
    -- print(enemy)
    -- print(enemyType)

    local config = enemyType or enemyTypes.Chase

    local lastAttackTime = 0
    local isAlive = true

    local humanoid = enemy:FindFirstChild("Humanoid")
    local rootPart = enemy:FindFirstChild("HumanoidRootPart")

    local CHASE_RANGE = config.chaseRange
    local DAMAGE = config.damage
    local ATTACK_RANGE = config.attackRange
    local ATTACK_COOLDOWN = config.attackCooldown
    local SPEED = config.speed
    local HEALTH = config.health

    humanoid.WalkSpeed = SPEED
    humanoid.MaxHealth = HEALTH
    humanoid.Health = HEALTH

    
    -- Modules
    local playerStatsModule = require(ServerScriptService:WaitForChild("plrDataModule"))
    local genericFunctions = require(ServerScriptService.GenericFunctions)

    -- Tag this enemy
    CollectionService:AddTag(enemy, "Enemy")
    
    -- Utility functions
    local function isPlayerCharacter(character)
        return Players:GetPlayerFromCharacter(character) ~= nil
    end
    
    -- local function getClosestPlayer()
    --     local closestPlayer = nil
    --     local closestDist = CHASE_RANGE + 1
    
    --     for _, player in ipairs(Players:GetPlayers()) do
    --         if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
    --             local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
    --             if dist <= CHASE_RANGE and dist < closestDist then
    --                 closestDist = dist
    --                 closestPlayer = player
    --             end
    --         end
    --     end
    --     return closestPlayer
    -- end
    
    local function tryAttackPlayer(targetCharacter)
        if not isAlive then return end
        if targetCharacter == enemy then return end
        if not isPlayerCharacter(targetCharacter) then return end
    
        if tick() - lastAttackTime >= ATTACK_COOLDOWN then
            local playerHumanoid = targetCharacter:FindFirstChild("Humanoid")
            if playerHumanoid then
                local plr = Players:GetPlayerFromCharacter(targetCharacter)
                local plrStats = playerStatsModule.fetchPlrStatsTable(plr)
    
                playerHumanoid:TakeDamage(math.max(0, DAMAGE - plrStats.armor))
                lastAttackTime = tick()
            end
        end
    end
    
    -- Handle death
    humanoid.Died:Connect(function()
        isAlive = false
        humanoid.WalkSpeed = 0
        CollectionService:RemoveTag(enemy, "Enemy") -- remove tag
        task.delay(1, function()
            if enemy then
                enemy:Destroy()
            end
        end)
    end)
    
    -- Chase Loop
    RunService.Heartbeat:Connect(function(dt)
        if not isAlive then return end
        
        local targetPlayer = genericFunctions.getClosestPlayer(enemy)
        if not targetPlayer or not targetPlayer.Character then return end

        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end

        local distToTarget = (targetHRP.Position - rootPart.Position).Magnitude

        if distToTarget <= ATTACK_RANGE then
            tryAttackPlayer(targetPlayer.Character)
        else
            humanoid:MoveTo(targetHRP.Position)
        end
    end)

end




return BaseEnemie



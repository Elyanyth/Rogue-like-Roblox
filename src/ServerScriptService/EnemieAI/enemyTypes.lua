local enemyTypes = {}

local ServerStorage = game:GetService("ServerStorage")
local enemyModels = ServerStorage:WaitForChild("EnemyModels")

enemyTypes.Chase = {
    chaseRange = 1000,
    speed = 12,
    damage = 20,
    health = 100,
    attackRange = 2,
    attackCooldown = 1,
    model = enemyModels:WaitForChild("Chase") 

}

enemyTypes.Swarm = {
    chaseRange = 1000,
    speed = 14,
    damage = 5,
    health = 50,
    attackRange = 2,
    attackCooldown = 1,
    model = enemyModels:WaitForChild("Swarm") 
}

enemyTypes.Tank = {
    chaseRange = 1000,
    speed = 10,
    damage = 40,
    health = 300,
    attackRange = 2,
    attackCooldown = 1,
    model = enemyModels:WaitForChild("Tank") 
}

function enemyTypes.getWeightedRandomType()
    local weightedTypes = {
        {type = "Chase", weight = 55},      -- 55% chance
        {type = "Swarm", weight = 30},  -- 30% chance
        {type = "Tank", weight = 15},        -- 15% chance
    }
    
    local totalWeight = 0
    for _, entry in ipairs(weightedTypes) do
        totalWeight = totalWeight + entry.weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, entry in ipairs(weightedTypes) do
        currentWeight = currentWeight + entry.weight
        if random <= currentWeight then
            return entry.type
        end
    end
    
    return "Chase" -- fallback
end


return enemyTypes

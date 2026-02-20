-- ReplicatedStorage.EnemyDefinitions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EnemyDefinitions = {}

local EnemyDefaults = {
    Armor = 0,
    AttackCooldown = 1,
    PreferredDistance = 0,
}

EnemyDefinitions.Types = {
    {
        Weight = 50,
        Type = "Melee",
        Name = "Zombie",
        Speed = 12,
        Health = 150,
        Damage = 20,
        Armor = 5,
        Model = ServerStorage.EnemyModels.Chase,
        AttackCooldown = EnemyDefaults.AttackCooldown
    },
    {
        Weight = 30,
        Type = "Ranged",
        Name = "Skeleton Archer",
        Speed = 14,
        Health = 80,
        Damage = 15,
        Armor = 3,
        Model = ServerStorage.EnemyModels.Archer,
        PreferredDistance = 20,
        AttackRange = 30,
        AttackCooldown = EnemyDefaults.AttackCooldown

    },
    {
        Weight = 10,
        Type = "Summoner",
        Name = "Necromancer",
        Speed = 10,
        Health = 200,
        Damage = 20,
        Armor = 15,
        Model = ServerStorage.EnemyModels.Summoner,
        PreferredDistance = 20,
        AttackRange = 25,
        AttackCooldown = 2,
        ProjectileSpeed = 20,
        MaxSummons = 5,
        SummonCooldown = 3,
        SummonTemplate = ServerStorage.EnemyModels.Swarm,
        SummonStats = {
            Name = "Skeleton Warrior",
            Speed = 14,
            Health = 60,
            Damage = 12,
            Armor = 2,
        }
    },
    {
        Weight = 15,
        Type = "Bomber",
        Name = "Suicide Bomber",
        Speed = 18,
        Health = 60,
        Damage = 0,
        Armor = 0,
        Model = ServerStorage.EnemyModels.Bomber,
        AttackCooldown = 999,
    },
    {
        Weight = 2,
        Type = "Egg",
        Name = "Egg",
        Speed = 0,
        Health = 100,
        Damage = 0,
        Armor = 0,
        -- No Model field: the egg Part is created programmatically in EggEnemy
        HatchStats = {
            Name = "Empowered Zombie",
            Speed = 16,
            Health = 300,
            Damage = 40,
            Armor = 10,
            ModelScale = 2,
        }
    },
    {
        Weight = 8,
        Type = "Mage",
        Name = "Mage",
        Speed = 8,
        Health = 120,
        Damage = 0,
        Armor = 10,
        Model = ServerStorage.EnemyModels.Mage,
    }
}

-- Optional: Add helper functions
function EnemyDefinitions.GetByName(name)
    for _, enemyType in ipairs(EnemyDefinitions.Types) do
        if enemyType.Name == name then
            return enemyType
        end
    end
    return nil
end

function EnemyDefinitions.GetWeightedRandom()
    local totalWeight = 0
    for _, enemy in ipairs(EnemyDefinitions.Types) do
        totalWeight += enemy.Weight
    end
    
    local rand = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, enemy in ipairs(EnemyDefinitions.Types) do
        currentWeight += enemy.Weight
        if rand <= currentWeight then
            return enemy
        end
    end
end

return EnemyDefinitions
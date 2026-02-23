-- ReplicatedStorage.EnemyDefinitions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local EnemyDefinitions = {}

local EnemyDefaults = {
    Armor = 0,
    AttackCooldown = 1,
    PreferredDistance = 0,
}

-- =====================================================================
-- WAVE UNLOCK REFERENCE
--   MinWave = 1  → available from the very first wave
--   MinWave = 3  → first appears on wave 3
--   (omitting MinWave defaults to 1 in GetWeightedRandom)
-- =====================================================================
EnemyDefinitions.Types = {
    {
        MinWave = 1,        -- always available
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
        MinWave = 2,        -- archers join on wave 2
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
        MinWave = 5,        -- necromancer unlocks on wave 4
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
        MinWave = 4,        -- bombers unlock on wave 5
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
        MinWave = 10,        -- eggs first appear on wave 3
        Weight = 2,
        Type = "Egg",
        Name = "Egg",
        Speed = 0,
        Health = 150,
        Damage = 0,
        Armor = 0,
        -- No Model field: the egg Part is created programmatically in EggEnemy
        HatchStats = {
            Name = "Empowered Zombie",
            Speed = 24,
            Health = 500,
            Damage = 40,
            Armor = 30,
            ModelScale = 1.5,
        }
    },
    {
        MinWave = 7,        -- mage is a late-game threat, unlocks wave 6
        Weight = 8,
        Type = "Mage",
        Name = "Mage",
        Speed = 16,
        Health = 300,
        Damage = 75,
        Armor = 25,
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

-- Returns a random enemy definition that is unlocked for the given wave.
-- Enemies with MinWave > currentWave are excluded from the pool entirely.
function EnemyDefinitions.GetWeightedRandom(currentWave)
    currentWave = currentWave or 1

    local totalWeight = 0
    for _, enemy in ipairs(EnemyDefinitions.Types) do
        if currentWave >= (enemy.MinWave or 1) then
            totalWeight += enemy.Weight
        end
    end

    if totalWeight == 0 then return nil end

    local rand = math.random(1, totalWeight)
    local runningWeight = 0

    for _, enemy in ipairs(EnemyDefinitions.Types) do
        if currentWave >= (enemy.MinWave or 1) then
            runningWeight += enemy.Weight
            if rand <= runningWeight then
                return enemy
            end
        end
    end
end

return EnemyDefinitions
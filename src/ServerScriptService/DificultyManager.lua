local DifficultyManager = {}

local ServerScriptService = game:GetService("ServerScriptService")

-- ===============================
-- IMPORTS
-- ===============================
local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local WaveModule = Modules.Get("WaveModule")

-- ===============================
-- CONFIGURATION
-- ===============================
local BASE_SCALING = 0.08 -- 8% increase per wave

local DIFFICULTY_PRESETS = {
    Easy   = { Health = 0.75, Damage = 0.75, Speed = 0.9,  Armor = 0.5,  AttackCooldown = 1.3 },
    Normal = { Health = 1.0,  Damage = 1.0,  Speed = 1.0,  Armor = 1.0,  AttackCooldown = 1.0 },
    Hard   = { Health = 1.5,  Damage = 1.25, Speed = 1.15, Armor = 1.25, AttackCooldown = 0.8 },
}

-- Stats that are "better when lower" need to be inverted (e.g. cooldowns)
local INVERSE_STATS = {
    AttackCooldown = true,
    SummonCooldown = true,
}

local currentMultipliers = DIFFICULTY_PRESETS.Normal

-- ===============================
-- PUBLIC API
-- ===============================

function DifficultyManager.SetPreset(presetName: string)
    local preset = DIFFICULTY_PRESETS[presetName]
    if not preset then
        warn("Unknown difficulty preset: " .. presetName)
        return
    end
    currentMultipliers = preset
    print("Difficulty set to:", presetName)
end

-- Returns a modified copy of enemyData with scaled stats
function DifficultyManager.DifficultySetting(enemyData: table): table
    local scaled = table.clone(enemyData)

    for stat, multiplier in pairs(currentMultipliers) do
        if scaled[stat] ~= nil then
            if INVERSE_STATS[stat] then
                -- Lower cooldown = harder, so we divide instead
                scaled[stat] = scaled[stat] / multiplier
            else
                scaled[stat] = scaled[stat] * multiplier
            end
        end
    end

    return scaled
end


function DifficultyManager.WaveScalling(enemyData: table)
    local wave = WaveModule.Get()
    
    local scale = 1 + (wave - 1) * BASE_SCALING 
    
    currentMultipliers = {
        Health         = scale,
        Damage         = scale,
        Speed          = 1 + (wave - 1) * 0.03, -- Speed scales slower
        Armor          = scale,
        AttackCooldown = scale, -- Divided, so cooldown shrinks
        SummonCooldown = scale,
    }

    local scaled = table.clone(enemyData)

    for stat, multiplier in pairs(currentMultipliers) do
        if scaled[stat] ~= nil then
            if INVERSE_STATS[stat] then
                -- Lower cooldown = harder, so we divide instead
                scaled[stat] = scaled[stat] / multiplier
            else
                scaled[stat] = scaled[stat] * multiplier
            end
        end
    end

    return scaled

end

function DifficultyManager.GetMultipliers()
    return currentMultipliers
end

return DifficultyManager
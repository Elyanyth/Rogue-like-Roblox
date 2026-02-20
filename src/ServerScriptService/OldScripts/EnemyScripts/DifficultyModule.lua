--[[
    Difficulty Scaling Module
    
    PURPOSE:
        Dynamically scales enemy difficulty based on the current wave number.
        Provides progressive challenge by increasing enemy stats as waves advance.
    
    FEATURES:
        - Configurable scaling curves for each stat type
        - Multiple scaling modes (linear, exponential, logarithmic, stepwise)
        - Wave milestone bonuses for dramatic difficulty spikes
        - Stat caps to prevent infinite scaling
        - Easy integration with existing enemy systems
    
    SCALING FORMULA:
        Base Formula: baseStat × (1 + (wave - 1) × scalingFactor)
        Exponential: baseStat × (scalingBase ^ (wave - 1))
        Logarithmic: baseStat × (1 + log(wave) × scalingFactor)
        Stepwise: baseStat × (1 + floor(wave / stepSize) × scalingFactor)
    
    USAGE:
        local DifficultyModule = require(path.to.DifficultyModule)
        
        -- Get scaled stats for current wave
        local scaledStats = DifficultyModule.ScaleEnemyStats(baseEnemyConfig, waveNumber)
        BaseEnemy.Active(enemy, scaledStats)
        
        -- Or get individual stat scaling
        local scaledHealth = DifficultyModule.ScaleStat("health", 100, waveNumber)
    
    EXAMPLES:
        Wave 1: Health 100, Damage 20, Speed 12
        Wave 5: Health 180, Damage 32, Speed 13.6
        Wave 10: Health 280, Damage 48, Speed 15.2
        Wave 20: Health 520, Damage 88, Speed 18.4
    
    CUSTOMIZATION:
        Modify SCALING_CONFIG to adjust difficulty curves per stat.
        Add wave milestones for special difficulty spikes at certain waves.
    
    DEPENDENCIES:
        - WaveModule: Provides current wave number
    
    AUTHOR: [Your Name]
    LAST UPDATED: [Date]
--]]

local DifficultyModule = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Module Dependencies
local Modules = require(ServerScriptService.ModuleLoader)
local WaveModule = Modules.Get("WaveModule")

--[[
    SCALING CONFIGURATION
    
    Each stat can have its own scaling mode and parameters:
    
    mode: "linear" | "exponential" | "logarithmic" | "stepwise" | "none"
    factor: Scaling multiplier (how much stat increases per wave)
    cap: Maximum value the stat can reach (nil = no cap)
    
    Linear: Most predictable, steady increase
    Exponential: Aggressive scaling, gets hard fast
    Logarithmic: Starts strong, tapers off (good for speed)
    Stepwise: Increases in chunks every N waves
--]]
local SCALING_CONFIG = {
    health = {
        mode = "linear",
        factor = 0.20,      -- +20% per wave
        cap = 2000,         -- Max 2000 HP
    },
    
    damage = {
        mode = "linear",
        factor = 0.15,      -- +15% per wave
        cap = 200,          -- Max 200 damage
    },
    
    speed = {
        mode = "logarithmic",
        factor = 0.50,      -- Logarithmic scaling
        cap = 24,           -- Max 24 speed (2x base of 12)
    },
    
    chaseRange = {
        mode = "none",      -- Keep constant
        factor = 0,
        cap = nil,
    },
    
    attackRange = {
        mode = "stepwise",
        factor = 0.10,      -- +10% every step
        stepSize = 5,       -- Increase every 5 waves
        cap = 5,            -- Max 5 studs
    },
    
    attackCooldown = {
        mode = "logarithmic",
        factor = -0.05,     -- Negative = faster attacks
        cap = 0.3,          -- Min 0.3 seconds between attacks
    },
}

--[[
    WAVE MILESTONES
    
    Special multipliers applied at specific wave numbers.
    These stack with normal scaling for dramatic difficulty spikes.
    
    Example: Boss waves, challenge waves, etc.
--]]
local WAVE_MILESTONES = {
    [5] = {
        health = 1.25,      -- +25% bonus health
        damage = 1.15,      -- +15% bonus damage
    },
    [10] = {
        health = 1.50,      -- +50% bonus health
        damage = 1.25,      -- +25% bonus damage
        speed = 1.10,       -- +10% bonus speed
    },
    [15] = {
        health = 1.75,
        damage = 1.35,
        speed = 1.15,
    },
    [20] = {
        health = 2.0,       -- Double health at wave 20
        damage = 1.5,       -- +50% damage
        speed = 1.2,        -- +20% speed
    },
    [25] = {
        health = 2.5,
        damage = 1.75,
        speed = 1.3,
    },
}

-- Constants
local SCALING_BASE = 1.05  -- Default exponential base

--[[
    Applies linear scaling to a stat
    @param baseStat number - The base stat value
    @param wave number - Current wave number
    @param factor number - Scaling factor per wave
    @return number - Scaled stat value
]]
local function scaleLinear(baseStat: number, wave: number, factor: number): number
    return baseStat * (1 + (wave - 1) * factor)
end

--[[
    Applies exponential scaling to a stat
    @param baseStat number - The base stat value
    @param wave number - Current wave number
    @param factor number - Exponential base (default 1.05 = 5% per wave)
    @return number - Scaled stat value
]]
local function scaleExponential(baseStat: number, wave: number, factor: number): number
    local base = factor > 0 and factor or SCALING_BASE
    return baseStat * (base ^ (wave - 1))
end

--[[
    Applies logarithmic scaling to a stat
    @param baseStat number - The base stat value
    @param wave number - Current wave number
    @param factor number - Scaling factor
    @return number - Scaled stat value
]]
local function scaleLogarithmic(baseStat: number, wave: number, factor: number): number
    if wave <= 1 then return baseStat end
    return baseStat * (1 + math.log(wave) * factor)
end

--[[
    Applies stepwise scaling to a stat
    @param baseStat number - The base stat value
    @param wave number - Current wave number
    @param factor number - Scaling factor per step
    @param stepSize number - Waves between increases
    @return number - Scaled stat value
]]
local function scaleStepwise(baseStat: number, wave: number, factor: number, stepSize: number): number
    local steps = math.floor((wave - 1) / (stepSize or 5))
    return baseStat * (1 + steps * factor)
end

--[[
    Scales a single stat based on wave number and config
    @param statName string - Name of the stat to scale
    @param baseStat number - Base value of the stat
    @param wave number - Current wave number
    @return number - Scaled and capped stat value
]]
function DifficultyModule.ScaleStat(statName: string, baseStat: number, wave: number): number
    -- Validate inputs
    if type(baseStat) ~= "number" or baseStat < 0 then
        warn(`DifficultyModule: Invalid baseStat for {statName}`)
        return baseStat
    end
    
    if type(wave) ~= "number" or wave < 1 then
        wave = WaveModule.Get()
    end
    
    -- Get scaling config for this stat
    local config = SCALING_CONFIG[statName]
    if not config or config.mode == "none" then
        return baseStat
    end
    
    -- Apply scaling based on mode
    local scaledValue = baseStat
    
    if config.mode == "linear" then
        scaledValue = scaleLinear(baseStat, wave, config.factor)
    elseif config.mode == "exponential" then
        scaledValue = scaleExponential(baseStat, wave, config.factor)
    elseif config.mode == "logarithmic" then
        scaledValue = scaleLogarithmic(baseStat, wave, config.factor)
    elseif config.mode == "stepwise" then
        scaledValue = scaleStepwise(baseStat, wave, config.factor, config.stepSize)
    end
    
    -- Apply wave milestone bonuses
    local milestone = WAVE_MILESTONES[wave]
    if milestone and milestone[statName] then
        scaledValue = scaledValue * milestone[statName]
    end
    
    -- Apply cap if configured
    if config.cap then
        if config.factor < 0 then
            -- For negative scaling (like cooldown), cap is minimum
            scaledValue = math.max(config.cap, scaledValue)
        else
            -- For positive scaling, cap is maximum
            scaledValue = math.min(config.cap, scaledValue)
        end
    end
    
    return scaledValue
end

--[[
    Scales all stats in an enemy config based on wave number
    @param baseConfig table - Base enemy configuration
    @param wave number? - Wave number (uses WaveModule.Get() if nil)
    @return table - New config table with scaled stats
]]
function DifficultyModule.ScaleEnemyStats(baseConfig: table, wave: number?): table
    if not baseConfig then
        warn("DifficultyModule: baseConfig is nil")
        return {}
    end
    
    -- Get current wave if not provided
    local currentWave = wave or WaveModule.Get()
    
    -- Create new config table (don't modify original)
    local scaledConfig = {}
    
    -- Scale each stat
    for statName, baseValue in pairs(baseConfig) do
        if type(baseValue) == "number" then
            scaledConfig[statName] = DifficultyModule.ScaleStat(statName, baseValue, currentWave)
        else
            -- Copy non-numeric values as-is
            scaledConfig[statName] = baseValue
        end
    end
    
    return scaledConfig
end

--[[
    Gets a difficulty multiplier for the current wave
    Useful for scaling rewards, XP, etc.
    @param wave number? - Wave number (uses WaveModule.Get() if nil)
    @return number - Overall difficulty multiplier (1.0 = baseline)
]]
function DifficultyModule.GetDifficultyMultiplier(wave: number?): number
    local currentWave = wave or WaveModule.Get()
    
    -- Base multiplier increases linearly
    local baseMultiplier = 1 + (currentWave - 1) * 0.15
    
    -- Apply milestone bonus
    local milestone = WAVE_MILESTONES[currentWave]
    if milestone then
        baseMultiplier = baseMultiplier * 1.25 -- +25% for milestone waves
    end
    
    return baseMultiplier
end

--[[
    Checks if the current wave is a milestone wave
    @param wave number? - Wave number (uses WaveModule.Get() if nil)
    @return boolean - True if this is a milestone wave
]]
function DifficultyModule.IsMilestoneWave(wave: number?): boolean
    local currentWave = wave or WaveModule.Get()
    return WAVE_MILESTONES[currentWave] ~= nil
end

--[[
    Gets the next milestone wave number
    @param wave number? - Wave number (uses WaveModule.Get() if nil)
    @return number? - Next milestone wave, or nil if none configured
]]
function DifficultyModule.GetNextMilestone(wave: number?): number?
    local currentWave = wave or WaveModule.Get()
    
    local nextMilestone = nil
    for milestoneWave, _ in pairs(WAVE_MILESTONES) do
        if milestoneWave > currentWave then
            if not nextMilestone or milestoneWave < nextMilestone then
                nextMilestone = milestoneWave
            end
        end
    end
    
    return nextMilestone
end

--[[
    Preview what stats will be at a future wave
    Useful for UI display or testing
    @param baseConfig table - Base enemy configuration
    @param targetWave number - Wave to preview
    @return table - Scaled stats for that wave
]]
function DifficultyModule.PreviewWaveStats(baseConfig: table, targetWave: number): table
    return DifficultyModule.ScaleEnemyStats(baseConfig, targetWave)
end

return DifficultyModule
local DamageCalcModule = {}

-- Random number generator instance (more reliable than randomseed)
local rng = Random.new()

--[[
    Calculates damage with critical hit mechanics
    @param baseDamage number - Base damage before modifiers
    @param stats table - Stats table containing:
        - strength: number (additive damage bonus)
        - critRate: number (0-100, chance to crit)
        - critDamage: number (percentage multiplier, e.g., 150 = 1.5x)
    @return damage: number - Final calculated damage
    @return isCritical: boolean - Whether the hit was a critical
]]
function DamageCalcModule.CalculateDamage(baseDamage, stats)
    -- Input validation
    if type(baseDamage) ~= "number" or baseDamage < 0 then
        warn("Invalid baseDamage provided:", baseDamage)
        return 0, false
    end
    
    if type(stats) ~= "table" then
        warn("Stats must be a table")
        return baseDamage, false
    end
    
    -- Extract stats with defaults
    local strength = stats.strength or 0
    local critRate = math.clamp(stats.critRate or 0, 0, 100)
    local critDamage = stats.critDamage or 100
    
    -- Calculate base damage with strength bonus
    local damage = baseDamage + strength
    
    -- Determine critical hit
    local isCritical = rng:NextNumber(0, 100) < critRate
    
    -- Apply critical multiplier
    if isCritical then
        damage = damage * (critDamage / 100)
    end
    
    return math.floor(damage + 0.5), isCritical -- Round to nearest integer
end

return DamageCalcModule
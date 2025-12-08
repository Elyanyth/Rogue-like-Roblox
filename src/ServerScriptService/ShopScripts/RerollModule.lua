--[[
    Reroll Module
    
    Purpose:
        Calculates the cost for rerolling based on the current wave number.
        The price scales dynamically with wave progression to balance economy.
    
    Formula:
        Base Reroll Price = 3 × Current Wave Number
        
    Example:
        Wave 1: 3 coins
        Wave 5: 15 coins
        Wave 10: 30 coins
    
    Usage:
        local RerollModule = require(path.to.RerollModule)
        local cost = RerollModule.GetBasePrice()
        
    Dependencies:
        - WaveModule: Provides current wave number
    
    Author: [Your Name]
    Last Updated: [Date]
--]]

local RerollModule = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Module Dependencies
local Modules = require(ServerScriptService.ModuleLoader)
local WaveModule = Modules.Get("WaveModule")

-- Constants
local PRICE_MULTIPLIER = 3 -- Base cost per wave

--[[
    Calculates the base reroll price based on current wave
    @return number - The reroll cost (minimum 3)
]]
function RerollModule.GetBasePrice(): number
    local currentWave = WaveModule.Get()
    
    -- Validate wave number
    if type(currentWave) ~= "number" or currentWave < 1 then
        warn("RerollModule: Invalid wave number, defaulting to wave 1")
        currentWave = 1
    end
    
    local basePrice = PRICE_MULTIPLIER * currentWave
    
    return basePrice
end

-- Alias for backwards compatibility (if needed)
RerollModule.BasePrice = RerollModule.GetBasePrice

return RerollModule
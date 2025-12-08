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
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Events
local RerollEvent = ReplicatedStorage:WaitForChild("RerollEvent")
local LootEvent = ReplicatedStorage:WaitForChild("LootEvent")

-- Module Dependencies
local Modules = require(ServerScriptService.ModuleLoader)
local WaveModule = Modules.Get("WaveModule")
local PlayerDataModule = Modules.Get("PlayerData")
local MoneyModule = Modules.Get("MoneyModule")
local LootModule = Modules.Get("LootModule")

-- Constants
local CONFIG = {
	RerollBasePrice = 3,
	LootRollsPerReroll = 3,
	RerollPriceIncrement = 3,
}

local RerollCounts = {} -- Store reroll counts per player (by UserId)
local CurrentWave = nil

local function resetRerollCountsIfNewWave()
	local currentWave = WaveModule.Get()

	if CurrentWave ~= currentWave then
		-- New wave detected - reset all reroll counts
		for userId in pairs(RerollCounts) do
			RerollCounts[userId] = 0
		end
		CurrentWave = currentWave
	end
end

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
    
    local basePrice = CONFIG.RerollBasePrice * currentWave
    
    return basePrice
end

function RerollModule.GetRerollPrice(rerollCount): number
    local wave = WaveModule.Get()

    -- Validate wave number
    if type(wave) ~= "number" or wave < 1 then
        warn("RerollModule: Invalid wave number, defaulting to wave 1")
        wave = 1
    end

    return CONFIG.RerollBasePrice * (wave + rerollCount)

end

function RerollModule.Reroll(player)
    resetRerollCountsIfNewWave()

    local userId = player.UserId

	-- Initialize reroll count for new players
	if not RerollCounts[userId] then
		RerollCounts[userId] = 0
	end

	-- Calculate reroll price
	local price = RerollModule.GetRerollPrice(RerollCounts[userId])

	-- Check if player can afford reroll
	local playerStats = PlayerDataModule.fetchPlrStats(player)
	if not playerStats or not playerStats.Money then
		warn("Player stats not found for", player.Name)
		return
	end

	if playerStats.Money.Value < price then
		-- Not enough money - could send feedback to client
		return
	end

	-- Process reroll
	MoneyModule.Remove(player, price)
	RerollCounts[userId] = RerollCounts[userId] + 1

	-- Generate new loot
	local playerLoot = LootModule.GenerateReward(player, CONFIG.LootRollsPerReroll)

	-- Send updated data to client
	LootEvent:FireClient(player, playerLoot)
	RerollEvent:FireClient(player, price + CONFIG.RerollPriceIncrement)
end

function RerollModule.Cleanup(player)
	RerollCounts[player.UserId] = nil
end

-- Alias for backwards compatibility (if needed)
RerollModule.BasePrice = RerollModule.GetBasePrice

return RerollModule
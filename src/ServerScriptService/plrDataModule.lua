local plrDataModule = {}

local serverStorage = game:GetService("ServerStorage")

export type PlayerStats = {
	health: number,
	speed: number,
	strength: number,
	armor: number,
	critRate: number,
	critDamage: number,
	healthRegen: number,
	cooldownReduction: number,
}

-- Default stats table in correct Lua format
plrDataModule.DefaultStats = {
	health = 100,
	speed = 20,
	strength = 0,
	armor = 0,
	critRate = 0, -- percentage (0-100)
	critDamage = 125,
	healthRegen = 0,
	cooldownReduction = 0,
	Income = 20, 
	Money = 20
}

function plrDataModule.getPlayerFolder(player)
	local playerFolder = serverStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
	return playerFolder
end

function plrDataModule.fetchPlrData(player)
	local playerData = plrDataModule.getPlayerFolder(player)
	return playerData:GetChildren()
end
	
function plrDataModule.fetchPlrStats(player)
	local playerData = plrDataModule.getPlayerFolder(player)
	local PlayerStats = playerData.Stats
	return PlayerStats
end

function plrDataModule.fetchPlrStatsTable(player)
	
	local playerStats = plrDataModule.fetchPlrStats(player)

	-- Create a table with Name = Value for each IntValue
	local StatsTable = {}
	for _, stat in ipairs(playerStats:GetChildren()) do
		if stat:IsA("IntValue") then
			StatsTable[stat.Name] = stat.Value
		end
	end

	return StatsTable
end

return plrDataModule


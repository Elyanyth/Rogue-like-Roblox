--[[
	Enemy Spawner System
	
	This script continuously spawns enemy packs in the game world with weighted random selection.
	
	Main Functions:
	- Spawns enemy packs at regular intervals on a designated spawner surface
	- Uses weighted random system to select enemy types with varying spawn rates
	- Validates spawn positions to prevent enemies spawning too close to players
	- Manages total enemy count to maintain performance (max 75 enemies)
	- Supports two spawn patterns: "Spread" (scattered) and grouped spawning
	
	How It Works:
	1. Waits for at least one player to join the game
	2. Checks current enemy count via CollectionService "Enemy" tag
	3. If below max count, selects a random enemy type using weighted probabilities
	4. Spawns a pack of enemies (size determined by enemy type settings)
	5. Validates each spawn is at least 15 studs away from nearest player
	6. Retries spawn position up to 10 times if too close to players
	7. Waits for spawn interval before next pack
	
	Spawn Configuration:
	- spawnInterval: Time in seconds between pack spawns (default: 1)
	- minPackSize/maxPackSize: Global pack size range (can be overridden by enemy type)
	- maxCount: Maximum total enemies allowed in world (default: 75)
	- Spawner: The part enemies spawn on (currently workspace.Baseplate)
	
	Spawn Types:
	- "Spread": Each enemy in pack gets random position across spawner
	- Other: All enemies in pack spawn near same location with small offset
	
	Dependencies:
	- enemyTypes module: Contains enemy definitions with weights and properties
	- BaseAi module: Handles enemy AI behavior after spawning
	- GenericFunctions module: Provides getClosestPlayer utility function
	- ServerStorage.Enemies.Dummy: Template enemy model to clone
	- CollectionService "Enemy" tag: Used to track total enemy count
	
	Safety Features:
	- Maximum 10 spawn attempts per enemy to prevent infinite loops
	- Distance check prevents spawn camping near players
	- Enemy count cap maintains server performance
--]]

local MobSpawner = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- Configuration (consolidated at top for easy tweaking)
local CONFIG = {
	Spawner = workspace.Baseplate,
	SpawnInterval = 1,
	MaxEnemyCount = 75,
	MinPlayerDistance = 15, -- Minimum distance from players to spawn
	MaxSpawnAttempts = 10,
	SpawnJitter = 3, -- Random position offset range
	PackSpawnDelay = 1, -- time in between packs
	enemySpawnInterval = 0.2 -- time between enemys in the same pack
}

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local enemyTypes = Modules.Get("EnemyTypes")
local BaseAi = Modules.Get("BaseEnemy")
local genericFunctions = Modules.Get("GenericFunctions")
local DifficultyModule = Modules.Get("DifficultyModule")

-- Cache spawner properties
local spawnerSize = CONFIG.Spawner.Size
local spawnerTopY = CONFIG.Spawner.Position.Y + (spawnerSize.Y / 2)

-- Utility Functions
local function waitForPlayers()
	local ok, err = pcall(function()
    while #Players:GetPlayers() < 1 do
        task.wait(0.5)
    end
	end)

	if not ok then
		warn("waitForPlayers error:", err)
	end

end

local function getRandomPosition()
	local offsetX = math.random(-spawnerSize.X/2, spawnerSize.X/2)
	local offsetZ = math.random(-spawnerSize.Z/2, spawnerSize.Z/2)
	return offsetX, offsetZ
end

local function getCurrentEnemyCount()
	return #CollectionService:GetTagged("Enemy")
end

local function createSpawnPosition(baseX, baseZ, enemyHeight)
	return CFrame.new(
		CONFIG.Spawner.Position.X + baseX + math.random(-CONFIG.SpawnJitter, CONFIG.SpawnJitter),
		spawnerTopY + (enemyHeight / 2) + 2,
		CONFIG.Spawner.Position.Z + baseZ + math.random(-CONFIG.SpawnJitter, CONFIG.SpawnJitter)
	)
end

local function isValidSpawnLocation(entity)
	local closestPlayer, distance = genericFunctions.getClosestPlayer(entity)
	return distance > CONFIG.MinPlayerDistance
end

local function spawnSingleEnemy(enemyType, baseX, baseZ)
	local offsetX, offsetZ = baseX, baseZ
	
	for attempt = 1, CONFIG.MaxSpawnAttempts do
		-- Recalculate position for spread spawns
		if enemyType.spawnType == "Spread" then
			offsetX, offsetZ = getRandomPosition()
		end
		
		-- Create and position entity
		local entity = enemyType.model:Clone()
		entity.PrimaryPart = entity:FindFirstChild("Head")
		
		if not entity.PrimaryPart then
			warn("Enemy model missing Head (PrimaryPart)")
			entity:Destroy()
			return false
		end
		
		local enemyScript = ServerScriptService.EnemyScripts.EnemyScript:Clone()
		enemyScript.Parent = entity
		
		local spawnCFrame = createSpawnPosition(offsetX, offsetZ, entity.PrimaryPart.Size.Y)
		entity:PivotTo(spawnCFrame)
		
		-- Validate spawn location
		if isValidSpawnLocation(entity) then
			entity.Parent = workspace.Enemies
			local scaledStats = DifficultyModule.ScaleEnemyStats(enemyType)
			-- print(scaledStats)
			BaseAi.Active(entity, scaledStats)
			return true
		else
			entity:Destroy()
		end
	end
	
	warn("Failed to find valid spawn after", CONFIG.MaxSpawnAttempts, "attempts")
	return false
end

local function spawnEnemyPack(enemyType)
	local packSize = math.random(enemyType.minPackSize, enemyType.maxPackSize)
	local baseX, baseZ = getRandomPosition()
	
	for i = 1, packSize do
		-- Check if we've hit the cap mid-spawn
		if getCurrentEnemyCount() >= CONFIG.MaxEnemyCount then
			break
		end
		
		spawnSingleEnemy(enemyType, baseX, baseZ)
		task.wait(CONFIG.enemySpawnInterval)
	end
	task.wait(CONFIG.PackSpawnDelay)
end

-- Main Spawning Loop
local function runSpawner()
	waitForPlayers()
	
	local ok, err = pcall(function()
        while true do 
			if getCurrentEnemyCount() < CONFIG.MaxEnemyCount then
				local enemyType = enemyTypes.getWeightedRandomType()
				spawnEnemyPack(enemyType)
			end
		end
    end)

    if not ok then
        warn("Spawner loop error:", err)
    end

    task.wait(CONFIG.SpawnInterval)
end

-- Start the spawner
function MobSpawner.Start()
    -- Run the spawner loop on its own thread so callers don't get blocked
    MobSpawner = task.spawn(function()
        local success, err = pcall(runSpawner)
        if not success then
            warn("Spawner error:", err)
        end
    end)
end

function MobSpawner.Stop()
    -- Run the spawner loop on its own thread so callers don't get blocked
    if MobSpawner then
		task.cancel(MobSpawner) -- Cancels the spawned task
		MobSpawner = nil
	end
end

return MobSpawner
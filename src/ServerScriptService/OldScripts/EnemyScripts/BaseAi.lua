--[[
	BaseEnemy Module
	
	PURPOSE:
	This module provides the core AI behavior for enemy NPCs in the game. It handles
	enemy movement, player targeting, combat, and lifecycle management.
	
	FEATURES:
	- Automatic player detection and chasing within configurable range
	- Melee combat system with cooldown and armor calculation
	- Configurable enemy stats (health, speed, damage, ranges)
	- Proper cleanup and memory management on death
	- CollectionService tagging for easy enemy querying
	
	BEHAVIOR:
	Enemies will continuously scan for the closest player within chase range.
	When a player is found, the enemy will move toward them. If the player
	is within attack range, the enemy will deal damage (reduced by player armor)
	with a cooldown between attacks. Upon death, enemies are tagged for removal,
	stop moving, and are destroyed after a 1 second delay.
	
	USAGE:
	local BaseEnemy = require(path.to.BaseEnemy)
	local enemy = workspace.EnemyModel
	local config = {
		chaseRange = 50,
		speed = 16,
		damage = 25,
		health = 150,
		attackRange = 3,
		attackCooldown = 1.5
	}
	BaseEnemy.Active(enemy, config)
	
	REQUIREMENTS:
	- Enemy model must have a Humanoid and HumanoidRootPart
	- Requires ServerScriptService modules:
	  * EnemieAI/enemyTypes - Enemy configuration presets
	  * plrDataModule - Player stats (armor, etc.)
	  * GenericFunctions - Utility functions (getClosestPlayer)
	
	DEPENDENCIES:
	- Players (service)
	- RunService (service)
	- ServerScriptService (service)
	- CollectionService (service)
	
	CONFIGURATION:
	Enemy stats can be customized via the enemyType parameter or will fall back
	to defaults. All distance values are in studs, time values in seconds.
	
	DEFAULT VALUES:
	- Chase Range: 1000 studs
	- Speed: 12 studs/second
	- Damage: 20 HP
	- Health: 100 HP
	- Attack Range: 2 studs
	- Attack Cooldown: 1 second
	
	NOTES:
	- Uses Heartbeat for smooth 60fps AI updates
	- Automatically cleans up connections on death or destruction
	- Damage calculation: max(0, enemyDamage - playerArmor)
	- Tagged with "Enemy" in CollectionService for group operations
	
	AUTHOR: [Your Name]
	LAST UPDATED: [Date]
--]]


local BaseEnemy = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local enemyTypes = Modules.Get("EnemyTypes")
local playerStatsModule = Modules.Get("PlayerData")
local genericFunctions = Modules.Get("GenericFunctions")

-- Constants
local DEFAULT_CONFIG = {
	chaseRange = 1000,
	speed = 12,
	damage = 20,
	health = 100,
	attackRange = 2,
	attackCooldown = 1
}

-- Utility functions
local function isPlayerCharacter(character)
	return Players:GetPlayerFromCharacter(character) ~= nil
end

local function validateEnemyParts(enemy)
	local humanoid = enemy:FindFirstChild("Humanoid")
	local rootPart = enemy:FindFirstChild("HumanoidRootPart")
	
	if not humanoid or not rootPart then
		warn(`Enemy {enemy.Name} missing required parts (Humanoid or HumanoidRootPart)`)
		return false, nil, nil
	end
	
	return true, humanoid, rootPart
end

function BaseEnemy.Active(enemy, enemyType)
	if not enemy then
		warn("BaseEnemy.Active: enemy parameter is nil")
		return
	end
	
	-- Validate enemy has required parts
	local isValid, humanoid, rootPart = validateEnemyParts(enemy)
	if not isValid then return end
	
	-- Configuration
	local config = enemyType or enemyTypes.Chase or DEFAULT_CONFIG
	
	-- Enemy state
	local enemyState = {
		isAlive = true,
		lastAttackTime = 0,
		connection = nil
	}
	
	-- Apply stats
	humanoid.WalkSpeed = config.speed
	humanoid.MaxHealth = config.health
	humanoid.Health = config.health
	
	-- Tag this enemy
	CollectionService:AddTag(enemy, "Enemy")
	
	-- Attack function
	local function tryAttackPlayer(targetCharacter)
		if not enemyState.isAlive or not targetCharacter then return end
		if targetCharacter == enemy then return end
		if not isPlayerCharacter(targetCharacter) then return end
		
		local currentTime = os.clock()
		if currentTime - enemyState.lastAttackTime < config.attackCooldown then
			return
		end
		
		local playerHumanoid = targetCharacter:FindFirstChild("Humanoid")
		if not playerHumanoid or playerHumanoid.Health <= 0 then return end
		
		local plr = Players:GetPlayerFromCharacter(targetCharacter)
		if not plr then return end
		
		local plrStats = playerStatsModule.fetchPlrStatsTable(plr)
		if plrStats then
			local damageDealt = math.max(0, config.damage - (plrStats.armor or 0))
			playerHumanoid:TakeDamage(damageDealt)
			enemyState.lastAttackTime = currentTime
		end
	end
	
	-- Chase behavior
	local function updateChase()
		if not enemyState.isAlive then return end
		if not rootPart or not rootPart.Parent then return end
		
		local targetPlayer, distToTarget = genericFunctions.getClosestPlayer(enemy)
        
		if not targetPlayer or not targetPlayer.Character then 
			humanoid:MoveTo(rootPart.Position) -- Stop moving
			return 
		end
		
		local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not targetHRP then return end
		
		-- Only chase if within range
		if distToTarget > config.chaseRange then
			humanoid:MoveTo(rootPart.Position) -- Stop moving
			return
		end
		
		if distToTarget <= config.attackRange then
			tryAttackPlayer(targetPlayer.Character)
		else
			humanoid:MoveTo(targetHRP.Position)
		end
	end
	
	-- Handle death
	local deathConnection
	deathConnection = humanoid.Died:Connect(function()
		enemyState.isAlive = false
		humanoid.WalkSpeed = 0
		CollectionService:RemoveTag(enemy, "Enemy")
		
		-- Disconnect chase loop
		if enemyState.connection then
			enemyState.connection:Disconnect()
			enemyState.connection = nil
		end
		
		-- Disconnect death event
		if deathConnection then
			deathConnection:Disconnect()
		end
		
		-- Destroy after delay
		task.delay(1, function()
			if enemy and enemy.Parent then
				enemy:Destroy()
			end
		end)
	end)
	
	-- Chase loop (using Heartbeat for smooth behavior)
	enemyState.connection = RunService.Heartbeat:Connect(updateChase)
	
	-- Cleanup when enemy is destroyed
	enemy.Destroying:Connect(function()
		if enemyState.connection then
			enemyState.connection:Disconnect()
		end
		if deathConnection then
			deathConnection:Disconnect()
		end
	end)
end

return BaseEnemy
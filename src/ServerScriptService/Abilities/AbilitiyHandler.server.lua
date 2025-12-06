--[[
	Ability System Handler
	
	This script manages the server-side logic for player abilities in the game.
	
	Main Functions:
	- Listens for ability activation requests from clients via RemoteEvent
	- Validates if a player can use a specific ability (checks if learned and not on cooldown)
	- Loads and executes ability modules dynamically from ServerScriptService/Abilities
	- Tracks cooldowns per player to prevent ability spam
	- Passes player stats to ability modules for damage/effect calculations
	
	How It Works:
	1. Client fires AbilityEvent with ability name, mouse position, and spawn type
	2. Server checks if ability exists and player has learned it
	3. Server verifies ability is not on cooldown
	4. Server executes the ability's Activate function with player data
	5. Server sets cooldown timer based on ability's Cooldown property
	
	Ability Module Requirements:
	- Must have an Activate(player, mousePos, stats) function
	- Should have a Cooldown property (number in seconds)
	- Must be stored in ServerScriptService/Abilities folder
	
	Dependencies:
	- plrDataModule: Provides fetchPlrStatsTable function for player stats
	- Individual ability modules in ServerScriptService/Abilities
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local playerStatsModule = Modules.Get("PlayerData")

-- RemoteEvent for client  server
local AbilityEvent = ReplicatedStorage:FindFirstChild("AbilityEvent") or Instance.new("RemoteEvent")
AbilityEvent.Name = "AbilityEvent"
AbilityEvent.Parent = ReplicatedStorage

-- Folder containing all module abilities
local AbilityFolder = ServerScriptService:WaitForChild("Abilities")

-- Table to track cooldowns per player
local cooldowns = {}

local function canUseAbility(player, abilityName)
	
	local plrFolder = ServerStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
	local PlayerAbilities = plrFolder.Abilities 
		
	if not PlayerAbilities:FindFirstChild(abilityName) then
		return false, abilityName .. " hasn't been learned"
	end
	
	if not cooldowns[player.UserId] then
		cooldowns[player.UserId] = {}
	end

	local abilityCooldown = cooldowns[player.UserId][abilityName]
	if abilityCooldown and abilityCooldown > os.clock() then
		return false, abilityCooldown - os.clock()
	end

	return true
end

AbilityEvent.OnServerEvent:Connect(function(player, abilityName, mousePos, spawnType)
	local abilityModule = AbilityFolder:FindFirstChild(abilityName)
	if not abilityModule then
		warn("Ability not found: " .. tostring(abilityName))
		return
	end

	local canUse, remaining = canUseAbility(player, abilityName)
	if not canUse and type(remaining) == "number" then
		print(player.Name .. " tried to use " .. abilityName .. " but it's on cooldown (" .. math.ceil(remaining) .. "s left)")
		return
	elseif not canUse and type(remaining) ~= "number" then
		print(remaining)	
		return
	end

	local ability = require(abilityModule)

	-- Run the ability logic safely
	task.spawn(function()
		local stats = playerStatsModule.fetchPlrStatsTable(player)
		local success, err = pcall(function()
			ability.Activate(player, mousePos, stats)
		end)
		if not success then
			warn("Error activating ability " .. abilityName .. ": " .. err)
		end
	end)

	-- Set new cooldown
	cooldowns[player.UserId][abilityName] = os.clock() + (ability.Cooldown or 0)
end)

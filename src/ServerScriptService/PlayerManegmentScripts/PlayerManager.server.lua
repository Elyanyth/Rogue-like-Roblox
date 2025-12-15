--[[
	Player Data Management System

	This script manages player data storage and initialization in Roblox.

	Main Functions:
	- Creates a folder structure in ServerStorage for each player when they join
	- Initializes player stats from a default configuration module
	- Sets up folders for Stats, Abilities, and Items for each player
	- Handles cleanup when players leave the game
	- Provides a RemoteEvent for client-server data communication

	Folder Structure Created:
	ServerStorage/PlayerData/[PlayerName - UserID]/
		├── Stats/ (populated with default stats from plrDataModule)
		├── Abilities/ (contains PrimaryAttack IntValue)
		└── Items/ (for future item storage)

	Dependencies:
	- plrDataModule: Contains DefaultStats table and fetchPlrStatsTable function
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Events
local playerDataEvent = ReplicatedStorage:FindFirstChild("PlayerDataEvent") or Instance.new("RemoteEvent")
playerDataEvent.Name = "PlayerDataEvent"
playerDataEvent.Parent = ReplicatedStorage

local AbilityAddedEvent = ReplicatedStorage:FindFirstChild("AbilityAddedEvent") or Instance.new("RemoteEvent")
AbilityAddedEvent.Name = "AbilityAddedEvent"
AbilityAddedEvent.Parent = ReplicatedStorage

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local playerDataModule = Modules.Get("PlayerData")
local PlayerStatsModule = Modules.Get("PlayerStats")

local function CreateStats(player, folder)
	for statName, statValue in pairs(playerDataModule.DefaultStats) do
		local stat = Instance.new("IntValue")
		stat.Name = statName
		stat.Value = statValue
		stat.Parent = folder
	end
end

local function CreateFolder(folderName, parent)

	local folder = Instance.new("Folder")
	folder.Name = folderName -- remove plr name from folder name in future
	folder.Parent = parent

	return folder
end


local function disableJump(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Forcefully disable jumping from the server
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	-- Stop hackers from forcing Jump internally
	humanoid.Changed:Connect(function(property)
		if property == "Jump" then
			humanoid.Jump = false
		end
	end)
end

-- Player Added stuff
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(disableJump)
	-- Check if the folder already exists (avoid duplicates)
	if not ServerStorage:FindFirstChild(player.Name) then

		local plrFolder = CreateFolder(player.Name .. " - " .. player.UserId, ServerStorage.PlayerData)
		local statsFolder = CreateFolder("Stats", plrFolder)
		local AbilitiesFolder = CreateFolder("Abilities", plrFolder)
		local ItemsFolder = CreateFolder("Items", plrFolder)

		CreateStats(player, statsFolder)
		print("Created folders for " .. player.Name)

		local obj = Instance.new("IntValue")
		obj.Name = "PrimaryAttack"
		obj.Value = 0
		obj.Parent = AbilitiesFolder

		local AbilityList = playerDataModule.GetAbilityList(player)
		AbilityAddedEvent:FireClient(player, AbilityList)

	end
end)

-- Cleanup when player leaves
Players.PlayerRemoving:Connect(function(player)
	local folder = ServerStorage:FindFirstChild(player.Name)
	if folder then
		folder:Destroy()
		print("Removed folder for " .. player.Name)
	end
end)

-- Change to send all plr data (when items are added)
playerDataEvent.OnServerEvent:Connect(function(plr)
	local plrStats = playerDataModule.fetchPlrStatsTable(plr)
	print(plrStats)
	playerDataEvent:FireClient(plr, plrStats)
end)

-- Respawn Logic
local function newCharacter(character)
	local player = Players:GetPlayerFromCharacter(character)
	local PlayerStats = playerDataModule.fetchPlrStatsTable(player)
	PlayerStatsModule.updatePlayerCharacter(player, PlayerStats)
end

local function newPlayer(player)
	if player.Character then
		task.defer(newCharacter, player.Character)
	end
	player.CharacterAdded:Connect(newCharacter)
end

for _,player in game.Players:GetPlayers() do
	task.defer(newPlayer, player)
end
game.Players.PlayerAdded:Connect(newPlayer)
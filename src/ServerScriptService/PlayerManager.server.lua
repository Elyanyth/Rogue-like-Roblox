local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Events
local playerDataEvent = ServerStorage:FindFirstChild("PlayerDataEvent")

if not playerDataEvent then
	playerDataEvent = Instance.new("RemoteEvent")
	playerDataEvent.Name = "PlayerDataEvent"
	playerDataEvent.Parent = ReplicatedStorage
end

-- Modules
local playerDataModule = require(game.ServerScriptService:WaitForChild("plrDataModule"))


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

-- Player Added stuff
Players.PlayerAdded:Connect(function(player)
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

-- CHange to send all plr data (when items are added)
playerDataEvent.OnServerEvent:Connect(function(plr)
	local plrStats = playerDataModule.fetchPlrStatsTable(plr)
	print(plrStats)
	playerDataEvent:FireClient(plr, plrStats)	
end)
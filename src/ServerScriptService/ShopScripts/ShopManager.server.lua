--[[
	Loot Selection and Reroll Handler

	This script manages the loot selection system, including:
	- Player loot rerolls with escalating costs per wave
	- Applying selected loot rewards (stats and spells) to players
	- Money transactions for rerolls
	- Reroll count tracking that resets each wave

	Main Events:
	- RerollEvent: Handles player reroll requests (costs money, generates new loot)
	- MoneyEvent: Handles money-related requests
	- SelectionEvent: Applies chosen loot reward to player stats/abilities

	Reroll System:
	- Cost formula: 3 * (CurrentWave + PlayerRerollCount)
	- Reroll counts reset when wave changes
	- Generates 3 new loot items per reroll

	Dependencies:
	- LootModule: Generates and manages loot rewards
	- PlayerDataModule: Accesses player stats and data
	- MoneyModule: Handles currency transactions
	- WaveModule: Tracks current wave number
	- RerollModule: (imported but unused - consider removing)
--]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Events
local RerollEvent = ReplicatedStorage:WaitForChild("RerollEvent")
local LootEvent = ReplicatedStorage:WaitForChild("LootEvent")
local MoneyEvent = ReplicatedStorage:WaitForChild("MoneyEvent")
local SelectionEvent = ReplicatedStorage:WaitForChild("SelectionEvent")

local ItemsAddedEvent = ReplicatedStorage:FindFirstChild("ItemsAddedEvent") or Instance.new("RemoteEvent")
ItemsAddedEvent.Name = "ItemsAddedEvent"
ItemsAddedEvent.Parent = ReplicatedStorage

local AbilityAddedEvent = ReplicatedStorage:FindFirstChild("AbilityAddedEvent") or Instance.new("RemoteEvent")
AbilityAddedEvent.Name = "AbilityAddedEvent"
AbilityAddedEvent.Parent = ReplicatedStorage

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local LootModule = Modules.Get("LootModule")
local MoneyModule = Modules.Get("MoneyModule")
local PlayerDataModule = Modules.Get("PlayerData")
local WaveModule = Modules.Get("WaveModule")
local RerollModule = Modules.Get("RerollModule")
-- local RerollModule = Modules.Get("RerollModule") -- Unused, consider enabling if needed

-- Configuration
local CONFIG = {
	RerollBasePrice = 3,
	LootRollsPerReroll = 3,
	RerollPriceIncrement = 3,
}

-- State Management
local RerollCounts = {} -- Store reroll counts per player (by UserId)
local CurrentWave = nil

-- Utility Functions

local function getPlayerFolder(player)
	return ServerStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
end

local function applyStatReward(playerStats, lootItem)
	local statObject = playerStats:FindFirstChild(lootItem.id)

	if statObject then
		statObject.Value = statObject.Value + lootItem.amount
	else
		warn("Stat not found:", lootItem.id, "for player")
	end
end

local function applySpellReward(Player, playerAbilities, lootItem)
	local spellObject = playerAbilities:FindFirstChild(lootItem.id)

	if not spellObject then
		-- Create new spell/ability
		spellObject = Instance.new("IntValue")
		spellObject.Name = lootItem.id
		spellObject.Value = 0
		spellObject.Parent = playerAbilities
	end

	spellObject.Value = spellObject.Value + lootItem.amount

	local AbilityList = PlayerDataModule.GetAbilityList(Player)
	AbilityAddedEvent:FireClient(Player, AbilityList)
end

local function applyItemReward(Player, ItemFolder, lootItem)
	local Item = ItemFolder:FindFirstChild(lootItem.id)

	if not Item then 
		-- Create new spell/ability
		Item = Instance.new("IntValue")
		Item.Name = lootItem.id
		Item.Value = 0
		Item.Parent = ItemFolder
	end

	Item.Value = Item.Value + lootItem.amount

	local ItemList = PlayerDataModule.GetItemList(Player)
	ItemsAddedEvent:FireClient(Player, ItemList)

end


local function updatePlayerCharacter(player, playerStats)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Update character stats
	humanoid.MaxHealth = playerStats.health.Value
	humanoid.Health = playerStats.health.Value -- Also heals player
	humanoid.WalkSpeed = playerStats.speed.Value
end

-- Event Handlers
RerollEvent.OnServerEvent:Connect(function(player)
	RerollModule.Reroll(player)
end)

MoneyEvent.OnServerEvent:Connect(function(player, action)
	if action == "get" then
		MoneyModule.Get(player)
	else
		warn("Unknown money action:", action)
	end
end)

SelectionEvent.OnServerEvent:Connect(function(player, selectionIndex)
	local playerLoot = LootModule.GetPlayerLoot(player)

	if not playerLoot then
		warn("No loot data found for", player.Name)
		return
	end

	if not selectionIndex or selectionIndex < 1 or selectionIndex > #playerLoot then
		warn("Invalid selection index:", selectionIndex, "for", player.Name)
		return
	end

	-- Get player's data folder
	local playerFolder = getPlayerFolder(player)
	if not playerFolder then
		warn("Player folder not found for", player.Name)
		return
	end

	local playerStats = playerFolder:FindFirstChild("Stats")
	local playerAbilities = playerFolder:FindFirstChild("Abilities")
	local playerItems = playerFolder:FindFirstChild("Items")

	if not playerStats or not playerAbilities then
		warn("Stats or Abilities folder missing for", player.Name)
		return
	end

	-- Apply the selected loot
	local selectedLoot = playerLoot[selectionIndex]

	if selectedLoot.type == "stat" then
		applyStatReward(playerStats, selectedLoot)
	elseif selectedLoot.type == "spell" then
		applySpellReward(player, playerAbilities, selectedLoot)
	elseif selectedLoot.type == "item" then
		applyItemReward(player, playerItems, selectedLoot)
	else
		warn("Unknown loot type:", selectedLoot.type)
	end

	-- Update player character with new stats
	updatePlayerCharacter(player, playerStats)

	-- Clear the player's loot data
	LootModule.RemovePlayerLoot(player)
end)

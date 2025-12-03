local ShopModule = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Events 
local SelectionEvent = ReplicatedStorage:FindFirstChild("SelectionEvent")

-- Modules
LootModule = require(ServerScriptService.LootModule)

-- Variables
local plrLootData = {} 

-- Functions

SelectionEvent.OnServerEvent:Connect(function(Player, Selection)
	
	-- print("Recived Selection")
	
	plrLootData = LootModule.GetPlayerLoot(Player) 
	
	if plrLootData then 
		local plrFolder = ServerStorage.PlayerData:FindFirstChild(Player.Name .. " - " .. Player.UserId)
		local PlayerStats = plrFolder.Stats
		local PlayerAbilities = plrFolder.Abilities
		local plrLootList = plrLootData[Player].lootList
		local plrSelection = plrLootList[Selection]

		--if not plrFolder:FindFirstChild(plrSelection.id) then 
		--	local obj = Instance.new("IntValue")
		--	obj.Name = plrSelection.id
		--	obj.Value = 0
		--	obj.Parent = plrFolder

		--end

		if plrSelection.type == "stat" then
			PlayerStats[plrSelection.id].Value = plrSelection.amount + PlayerStats[plrSelection.id].Value

		elseif plrSelection.type == "spell" then
			if not PlayerAbilities:FindFirstChild(plrSelection.id) then 
				local obj = Instance.new("IntValue")
				obj.Name = plrSelection.id
				obj.Value = 0
				obj.Parent = PlayerAbilities   
			end

			PlayerAbilities[plrSelection.id].Value = plrSelection.amount + PlayerAbilities[plrSelection.id].Value


		end


		Player.Character.Humanoid.MaxHealth = PlayerStats.health.Value
		Player.Character.Humanoid.WalkSpeed = PlayerStats.speed.Value

		-- Heals player
		Player.Character.Humanoid.Health = PlayerStats.health.Value

		LootModule.RemovePlayerLoot(Player)
	end
	
	
end)


return ShopModule

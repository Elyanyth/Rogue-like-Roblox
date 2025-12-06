local StatManagerModule = {}

	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local ServerStorage = game:GetService("ServerStorage")

	local selectionEvent = ReplicatedStorage:FindFirstChild("SelectionEvent")
	local timerEvent = ReplicatedStorage:FindFirstChild("TimerUpdate")
	local lootEvent = ReplicatedStorage:FindFirstChild("LootEvent")

	-- Module Scripts 
	local Modules = require(ServerScriptService.ModuleLoader)
	local LootModule = Modules.Get("LootModule")

	if not lootEvent then
		lootEvent = Instance.new("RemoteEvent")
		lootEvent.Name = "LootEvent"
		lootEvent.Parent = ReplicatedStorage
	end

	if not selectionEvent then
		lootEvent = Instance.new("RemoteEvent")
		lootEvent.Name = "SelectionEvent"
		lootEvent.Parent = ReplicatedStorage
	end

--function StatManagerModule.StatUpdate(timeleft)
--	local plrLootData = {}
	
--	--if timeleft == 0 then  

--	--	for _, player in ipairs(Players:GetPlayers()) do
--	--		local plrLoot = LootModule.GenerateReward(player, 3)
--	--		lootEvent:FireClient(player, plrLoot)

--	--		plrLootData[player] = {
--	--			lootList = plrLoot
--	--		}
--	--	end
--	--end

--	selectionEvent.OnServerEvent:Connect(function(player, selection)

--		if plrLootData[player] then 
--			local plrFolder = ServerStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
--			local PlayerStats = plrFolder.Stats
--			local PlayerAbilities = plrFolder.Abilities
--			local plrLootList = plrLootData[player].lootList
--			local plrSelection = plrLootList[selection]
			
--			--if not plrFolder:FindFirstChild(plrSelection.id) then 
--			--	local obj = Instance.new("IntValue")
--			--	obj.Name = plrSelection.id
--			--	obj.Value = 0
--			--	obj.Parent = plrFolder
				
--			--end
			
--			if plrSelection.type == "stat" then
--				PlayerStats[plrSelection.id].Value = plrSelection.amount + PlayerStats[plrSelection.id].Value
			
--			elseif plrSelection.type == "spell" then
--				if not PlayerAbilities:FindFirstChild(plrSelection.id) then 
--					local obj = Instance.new("IntValue")
--					obj.Name = plrSelection.id
--					obj.Value = 0
--					obj.Parent = PlayerAbilities   
--				end
				
--				PlayerAbilities[plrSelection.id].Value = plrSelection.amount + PlayerAbilities[plrSelection.id].Value

				
--			end
			
			
--			player.Character.Humanoid.MaxHealth = PlayerStats.health.Value
--			player.Character.Humanoid.WalkSpeed = PlayerStats.speed.Value
			
--			-- Heals player
--			player.Character.Humanoid.Health = PlayerStats.health.Value
			
--			plrLootData[player] = nil
--		end


--end)
	
	
--end

return StatManagerModule

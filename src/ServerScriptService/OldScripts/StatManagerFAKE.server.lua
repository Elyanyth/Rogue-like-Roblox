local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local selectionEvent = ReplicatedStorage:FindFirstChild("SelectionEvent")
local timerEvent = ReplicatedStorage:FindFirstChild("TimerUpdate")
local lootEvent = ReplicatedStorage:FindFirstChild("LootEvent")

-- Module Scripts 
local LootModule = require(game.ServerScriptService:WaitForChild("LootModule"))

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

timerEvent.OnServerEvent:Connect(function(timeLeft)
	if timeLeft == 0 then  
		local plrLootData = {}

		for _, player in ipairs(Players:GetPlayers()) do
			local plrLoot = LootModule.GenerateReward(player, 3)
			lootEvent:FireClient(player, plrLoot)

			plrLootData[player] = {
				lootList = plrLoot
			}
		end
	end
end)

plrLootData = nil

selectionEvent.OnServerEvent:Connect(function(player, selection)

	if plrLootData[player] then 
		local plrFolder = ServerStorage.PlayerData:FindFirstChild(player.Name .. " - " .. player.UserId)
		local plrLootList = plrLootData[player].lootList
		local plrSelection = plrLootList[selection]

		plrFolder[plrSelection.id].Value = plrSelection.amount + plrFolder[plrSelection.id].Value
		plrLootData[player] = nil
	end


end)

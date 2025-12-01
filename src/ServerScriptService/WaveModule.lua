local WaveModule = {}

-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Modules
LootModule = require(ServerScriptService.LootModule)

-- Events 
local LootEvent = ReplicatedStorage:WaitForChild("LootEvent")

Wave = 1

function WaveModule.Get()
	
	return Wave
	
end

function WaveModule.Increase()
	
	Wave = Wave + 1
	
end


function WaveModule.Ended(Time)
	
	if Time == 0 then  

		for _, player in ipairs(Players:GetPlayers()) do
			local plrLoot = LootModule.GenerateReward(player, 3)
			LootModule:FireClient(player, plrLoot)
			
		end
	end
	
end


return WaveModule

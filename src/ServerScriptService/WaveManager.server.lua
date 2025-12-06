local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Create or get a RemoteEvent
local nextWaveEvent = ReplicatedStorage:FindFirstChild("NextWave")
local timerEvent = ReplicatedStorage:FindFirstChild("TimerUpdate")
local RerollEvent = ReplicatedStorage:FindFirstChild("RerollEvent")

local MobSpawner = ServerScriptService:WaitForChild("Mob Spawner")

if not nextWaveEvent then
	nextWaveEvent = Instance.new("RemoteEvent")
	nextWaveEvent.Name = "NextWave"
	nextWaveEvent.Parent = ReplicatedStorage
end

if not timerEvent then
	timerEvent = Instance.new("RemoteEvent")
	timerEvent.Name = "TimerUpdate"
	timerEvent.Parent = ReplicatedStorage
end




-- Module Scripts 
local Modules = require(ServerScriptService.ModuleLoader)
local LootModule = Modules.Get("LootModule")
local MoneyModule = Modules.Get("MoneyModule")

local StatManager = require(game.ServerScriptService:WaitForChild("StatManager"))
-- MoneyModule = require(ServerScriptService.MoneyModule)
WaveModule = require(ServerScriptService.WaveModule)
RerollModule = require(ServerScriptService.RerollModule)
--local LootModule = require(game.ServerScriptService:WaitForChild("LootModule"))


local function ClearMap()
	MobSpawner.Disabled = true
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") then
			-- Check if this Humanoid belongs to a player
			local player = Players:GetPlayerFromCharacter(obj.Parent)
			if not player then
				-- It's an NPC or other entity — kill it
				obj.Parent:Destroy()
			end
		end
	end
end


local timerLength = script:GetAttribute("Timer") or 20
local timeLeft = timerLength

while true do
	--timerLength = math.clamp(timerLength + ((waveCount-1) * 5), 20, 90) -- Gradually increase timer
	timeLeft = timerLength
	while timeLeft > 0 do
		-- Send the current time to all clients
		timerEvent:FireAllClients(timeLeft)
		wait(1)
		timeLeft -= 1
	end

	-- Optional: tell clients the timer ended	
	

	
	ClearMap()
	
	RerollEvent:FireAllClients(RerollModule.BasePrice())
	timerEvent:FireAllClients(0)
	
	-- Generate Loot for all players
	
	for _, player in pairs(Players:GetChildren()) do 
		LootModule.GenerateReward(player, 3)
		
	end
	
	
	--StatManager.StatUpdate(0) -- old Loot Gen 
	-- Recieved by StatManager and player GUIManager
	
	for _, player in ipairs(Players:GetChildren()) do
		MoneyModule.Income(player)
	end
	
	-- Wait for the player to click "Next"
	nextWaveEvent.OnServerEvent:Wait()
	MobSpawner.Disabled = false
	
	WaveModule.Increase()
	nextWaveEvent:FireAllClients(WaveModule.Get())
	print("Timer finished, restarting...")
	print("Wave " .. WaveModule.Get() .. " starting...")
end



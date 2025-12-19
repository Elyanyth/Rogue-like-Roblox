local GameController = {}

-- // Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // RemoteEvents ------------------------
local nextWaveEvent = ReplicatedStorage:FindFirstChild("NextWave") or Instance.new("RemoteEvent")
nextWaveEvent.Name = "NextWave"
nextWaveEvent.Parent = ReplicatedStorage

local timerEvent = ReplicatedStorage:FindFirstChild("TimerUpdate") or Instance.new("RemoteEvent")
timerEvent.Name = "TimerUpdate"
timerEvent.Parent = ReplicatedStorage

local rerollEvent = ReplicatedStorage:FindFirstChild("RerollEvent") or Instance.new("RemoteEvent")
rerollEvent.Name = "RerollEvent"
rerollEvent.Parent = ReplicatedStorage

local gameOverEvent = ReplicatedStorage:FindFirstChild("GameOverEvent") or Instance.new("RemoteEvent")
gameOverEvent.Name = "GameOverEvent"
gameOverEvent.Parent = ReplicatedStorage

-- New event: players request restart
local restartRequestEvent = ReplicatedStorage:FindFirstChild("RestartRequest") or Instance.new("RemoteEvent")
restartRequestEvent.Name = "RestartRequest"
restartRequestEvent.Parent = ReplicatedStorage
----------------------------------------------------

-- // Module Loader -------------------------
local Modules = require(ServerScriptService.ModuleLoader)
local LootModule = Modules.Get("LootModule")
local MoneyModule = Modules.Get("MoneyModule")
local WaveModule = Modules.Get("WaveModule")
local RerollModule = Modules.Get("RerollModule")
local ReadyCheck = Modules.Get("ReadyCheck")
local MobSpawner = Modules.Get("MobSpawner")
local PlayerData = Modules.Get("PlayerData")

local baseTimerLength = 20
local gameActive = false

----------------------------------------------------
-- INTERNAL HELPERS
----------------------------------------------------

local function ClearMap()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") then
			local player = Players:GetPlayerFromCharacter(obj.Parent)
			if not player then
				obj.Parent:Destroy()
			end
		end
	end
end


local function AreAllPlayersDead()
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hum = character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                return false
            end
        end
    end
    return true
end

----------------------------------------------------
-- RESET GAME DATA
----------------------------------------------------
local function ResetGameState()
    WaveModule.Reset()          -- You must add Reset() inside WaveModule
    -- MobSpawner.Reset() 
	-- You must add Reset() in MobSpawner
	for _, player in pairs(Players:GetChildren()) do
		PlayerData.StatReset(player)
		PlayerData.ItemReset(player)
		PlayerData.AbilityReset(player)
	end
    
	
	ClearMap()
end


----------------------------------------------------
-- MAIN GAME LOOP
----------------------------------------------------
function GameController.Start()
	gameActive = true
	local readyCheck = ReadyCheck.new()

	while gameActive do
		local CurrentWave = WaveModule.Get()
		print("Wave " .. CurrentWave .. " starting...")

		nextWaveEvent:FireAllClients(WaveModule.Get())
		if CurrentWave ~= 1 then readyCheck:WaitForAllReady() end
		MobSpawner.Start()

		local timeLeft = math.min(70, baseTimerLength + (CurrentWave * 5))

		while timeLeft > 0 do
			if AreAllPlayersDead() then
				print("All players dead → GAME OVER")
				gameActive = false
				break
			end

			timerEvent:FireAllClients(timeLeft)
			task.wait(1)
			timeLeft -= 1
		end

		if not gameActive then
			MobSpawner.Stop()
			ClearMap()
			gameOverEvent:FireAllClients(WaveModule.Get())
			break
		end

		-- Wave end
		MobSpawner.Stop()
		ClearMap()

		rerollEvent:FireAllClients(RerollModule.BasePrice())
		timerEvent:FireAllClients(0)

		for _, player in pairs(Players:GetPlayers()) do
			LootModule.GenerateReward(player, 3)
			MoneyModule.Income(player)
		end

		WaveModule.Increase()
	end

	-- GAME OVER HANDLING
	readyCheck:Reset()
	readyCheck:WaitForAllReady()
	ResetGameState()

	-- Start the game again
	task.wait(1)
	GameController.Start()
end


function GameController.Stop()
	gameActive = false
	MobSpawner.Stop()
end

return GameController

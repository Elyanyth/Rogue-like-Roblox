-- ReadyCheck Module
local ReadyCheck = {}
ReadyCheck.__index = ReadyCheck
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create or get the RemoteEvent
local function getReadyEvent()
	local event = ReplicatedStorage:FindFirstChild("PlayerReady")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "PlayerReady"
		event.Parent = ReplicatedStorage
	end
	return event
end

-- Create a new ReadyCheck instance
function ReadyCheck.new()
	local self = setmetatable({}, ReadyCheck)
	self.readyPlayers = {} -- [player] = true when ready
	self.readyEvent = getReadyEvent()
	
	-- Reset ready state if a player leaves
	Players.PlayerRemoving:Connect(function(player)
		self.readyPlayers[player] = nil
	end)
	
	-- Listen for players sending ready
	self.readyEvent.OnServerEvent:Connect(function(player)
		self.readyPlayers[player] = true
		print(player.Name .. " is ready!")
	end)
	
	return self
end

-- Check if all current players are ready
function ReadyCheck:AllPlayersReady()
	for _, player in ipairs(Players:GetPlayers()) do
		if not self.readyPlayers[player] then
			return false
		end
	end
	return true  -- Moved the reset logic out of here
end

-- Wait until all players are ready
function ReadyCheck:WaitForAllReady()
	-- Wait until at least one player exists
	while #Players:GetPlayers() == 0 do
		task.wait(0.5)
	end
	
	-- Wait until all players are ready
	repeat
		task.wait(0.2)
	until self:AllPlayersReady()
	
	print("All players are ready.")
	
	-- Reset ready states for next round
	self:Reset()
end

function ReadyCheck:Reset()
	self.readyPlayers = {}
end

return ReadyCheck
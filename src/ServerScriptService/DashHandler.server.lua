local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent that the client fires to toggle I-frames
local DashEvent = Instance.new("RemoteEvent")
DashEvent.Name = "DashEvent"
DashEvent.Parent = ReplicatedStorage

local MAX_INVINCIBLE_DURATION = 1 -- server-side safety cap (seconds)

DashEvent.OnServerEvent:Connect(function(player, isInvincible)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if isInvincible then
		humanoid:SetAttribute("IsInvincible", true)

		-- Auto-remove I-frames after the cap to prevent exploits
		task.delay(MAX_INVINCIBLE_DURATION, function()
			if humanoid and humanoid.Parent then
				humanoid:SetAttribute("IsInvincible", false)
			end
		end)
	else
		humanoid:SetAttribute("IsInvincible", false)
	end
end)

-- Clean up on disconnect in case the player leaves mid-dash
Players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetAttribute("IsInvincible", false)
		end
	end
end)

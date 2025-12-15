local PlayerStats = {}

function PlayerStats.updatePlayerCharacter(player, playerStats)
	
    if not playerStats then return end
    
    local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Update character stats
	humanoid.MaxHealth = playerStats.health
	humanoid.Health = playerStats.health -- Also heals player
	humanoid.WalkSpeed = playerStats.speed
end

return PlayerStats
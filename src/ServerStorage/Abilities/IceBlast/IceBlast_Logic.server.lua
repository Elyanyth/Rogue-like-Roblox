local part = script.Parent
local Players = game:GetService("Players")

local damage = 50

-- Table to keep track of entities already hit
local hitEntities = {}

part.Touched:Connect(function(hit)
	local character = hit.Parent
	if character and character:FindFirstChild("Humanoid") then
		-- Make sure we haven't already processed this character
		if hitEntities[character] then
			return
		end

		-- Mark as hit
		hitEntities[character] = true

		local hum = character.Humanoid
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			print("Touched a player: " .. player.Name)
			-- Additional player-specific logic here
		else
			hum.Health -= damage
		end
	end
end)

local Players = game:GetService("Players")

local part = script.Parent
local forward = part.CFrame.LookVector
local mass = part:GetMass()

local damage = 30

-- BodyVelocity
local bv = Instance.new("BodyVelocity", part)
local maxForce = math.huge
bv.Velocity = part.CFrame.LookVector * 80 -- speed
bv.MaxForce = Vector3.new(maxForce, maxForce, maxForce) -- make sure it can push in all directions


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

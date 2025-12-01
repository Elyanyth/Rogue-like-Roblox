 -- ServerStorage/Abilities/Fireball.lua
local Template = {}

ServerStorage = game:GetService("ServerStorage")
ServerScriptService = game:GetService("ServerScriptService")
RunService = game:GetService("RunService")
local damageModule = require(ServerScriptService.DamageModule)

local baseCooldown = 0.5 -- seconds

function Template.Activate(player, mousePos, stats)
	--print(player.Name .. " used auto attack!")
	
	Template.Cooldown = baseCooldown * (math.clamp(1 - (stats.cooldownReduction/100), 0.5, 1))
	
	local Players = game:GetService("Players")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	
	-- Auto Attack code
	local part = ServerStorage.Abilities:FindFirstChild("PrimaryAttack"):Clone()
	part.CFrame = CFrame.new(root.CFrame.Position, Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)) * CFrame.new(0, 0, -5)
	part.Parent = workspace
	local forward = part.CFrame.LookVector
	local mass = part:GetMass()
	
	local baseDamage = 30
	local damage = damageModule.CalculateDamage(baseDamage, stats)

	-- Table to keep track of entities already hit
	local hitEntities = {}

	--part.Touched:Connect(function(hit)
	--	local character = hit.Parent
	--	if character and character:FindFirstChild("Humanoid") then
	--		-- Make sure we haven't already processed this character
	--		if hitEntities[character] then
	--			return
	--		end

	--		-- Mark as hit
	--		hitEntities[character] = true

	--		local hum = character.Humanoid
	--		local player = Players:GetPlayerFromCharacter(character)

	--		if player then
	--			print("Touched a player: " .. player.Name)
	--			-- Additional player-specific logic here
	--		else
	--			hum.Health -= damage
	--		end
	--	end
	--end)
	
	local hbConn

	hbConn = RunService.Heartbeat:Connect(function()
		if not part or not part.Parent then
			-- Part removed, stop the loop
			hbConn:Disconnect()
			return
		end

		local parts = workspace:GetPartBoundsInBox(part.CFrame, part.Size)

		for _, hit in ipairs(parts) do
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") and not hitEntities[character] then

				hitEntities[character] = true

				local hum = character.Humanoid
				local player = Players:GetPlayerFromCharacter(character)

				if player then
					print("player hit")
				else
					hum:TakeDamage(damage)
				end
			end
		end
	end)	

	game:GetService("Debris"):AddItem(part, 0.25)
end

return Template

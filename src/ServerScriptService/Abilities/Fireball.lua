 -- ServerStorage/Abilities/Fireball.lua
local Template = {}

ServerStorage = game:GetService("ServerStorage")
ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService:WaitForChild("ModuleLoader"))
local damageModule = require(ServerScriptService.DamageModule)
local PlayerData =  Modules.Get("PlayerData")

local baseCooldown = 5 -- seconds

function Template.Activate(player, mousePos, stats)
	print(player.Name .. " used Fireball!")
	
	
	Template.Cooldown = baseCooldown * (math.clamp(1 - (stats.cooldownReduction/100), 0.5, 1))
	
	local Players = game:GetService("Players")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	
	-- Fireball code

	local WizardCaps = PlayerData.GetItem(player, "Wizard Cap")
	
	local part = ServerStorage.Abilities:FindFirstChild("Fireball"):Clone()
	
	local multiplier = 1 + (1 - (WizardCaps / 10))

	if typeof(multiplier) == "number" and multiplier > 0 then
		part.Size = part.Size * multiplier
	end
	
	part.CFrame = CFrame.new(root.CFrame.Position, Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)) * CFrame.new(0, 0, -5)
	part.Parent = workspace
	local forward = part.CFrame.LookVector
	local mass = part:GetMass()
	
	local baseDamage = 50 
	local damage = damageModule.CalculateDamage(baseDamage, stats)

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

	game:GetService("Debris"):AddItem(part, 3)
end

return Template

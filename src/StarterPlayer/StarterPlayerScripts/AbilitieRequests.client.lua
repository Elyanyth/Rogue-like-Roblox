local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local AbilityEvent = ReplicatedStorage:WaitForChild("AbilityEvent")
local Mouse = Players.LocalPlayer:GetMouse()


-- Helper function to trigger ability
local function useAbility(abilityName, mousePos, spawnType)
	AbilityEvent:FireServer(abilityName, mousePos, spawnType)
end

-- Key press abilities
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local mousePos = Mouse.Hit
	
	if input.KeyCode == Enum.KeyCode.Q then
		useAbility("Fireball", mousePos)
	elseif input.KeyCode == Enum.KeyCode.E then
		useAbility("IceBlast", mousePos, "Mouse")
	elseif input.KeyCode == Enum.KeyCode.R then
		useAbility("Heal", mousePos)
	end
end)

-- Mouse click abilities
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local mousePos = Mouse.Hit
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		useAbility("PrimaryAttack", mousePos) -- Left click
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		useAbility("SecondaryAttack", mousePos) -- Right click
	end
end)

-- Listen for cooldown updates from server
AbilityEvent.OnClientEvent:Connect(function(abilityName, cooldownTime)
	--print("Cooldown for " .. abilityName .. " started: " .. cooldownTime .. "s")
	-- Update UI here (e.g., start filling a cooldown bar)
end)

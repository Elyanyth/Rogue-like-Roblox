local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local AbilityEvent = ReplicatedStorage:WaitForChild("AbilityEvent")
local nextWaveEvent = ReplicatedStorage:WaitForChild("NextWave")

local Mouse = Players.LocalPlayer:GetMouse()

local Player = Players.LocalPlayer

-- Helper function to trigger ability
local function useAbility(abilityName, mousePos, spawnType)
	AbilityEvent:FireServer(abilityName, mousePos, spawnType)
end

local EquipedButtons = Player.PlayerGui:WaitForChild("ScreenGui").ShopGui.AbilitiesInventory.Abilities.Equiped:GetChildren()
local Abilities = {}

local function equipedAbilities()
    Abilities = {} -- reset table each time

    for _, object in ipairs(EquipedButtons) do
        if object:IsA("TextButton") and object.Text ~= "Empty" then
            table.insert(Abilities, object.Text)
        end
    end

	print("Updated Abilities:", table.concat(Abilities, ", "))

    return Abilities
end

for _, btn in ipairs(EquipedButtons) do
    if btn:IsA("TextButton") then
        btn:GetPropertyChangedSignal("Text"):Connect(equipedAbilities)
    end
end


-- Key press abilities
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local mousePos = Mouse.Hit

	if input.KeyCode == Enum.KeyCode.Q then
		useAbility(Abilities[3], mousePos)
	elseif input.KeyCode == Enum.KeyCode.E then
		useAbility(Abilities[4], mousePos, "Mouse")
	elseif input.KeyCode == Enum.KeyCode.R then
		useAbility(Abilities[5], mousePos)
	end
end)

-- Mouse click abilities
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local mousePos = Mouse.Hit

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		useAbility(Abilities[1], mousePos) -- Left click
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		useAbility(Abilities[2], mousePos) -- Right click
	end
end)

-- Listen for cooldown updates from server
AbilityEvent.OnClientEvent:Connect(function(abilityName, cooldownTime)
	--print("Cooldown for " .. abilityName .. " started: " .. cooldownTime .. "s")
	-- Update UI here (e.g., start filling a cooldown bar)
end)

nextWaveEvent.OnClientEvent:Connect(function()
	equipedAbilities()
end)



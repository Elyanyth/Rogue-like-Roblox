local ReplicatedStorage = game:GetService("ReplicatedStorage")
local nextWaveEvent = ReplicatedStorage:WaitForChild("NextWave")

local button = script.Parent  -- The TextButton

button.MouseButton1Click:Connect(function()
	-- Fire to the server when clicked
	nextWaveEvent:FireServer()
end)

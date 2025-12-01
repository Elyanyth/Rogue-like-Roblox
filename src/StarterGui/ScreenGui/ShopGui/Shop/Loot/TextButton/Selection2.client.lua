-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local nextWaveEvent = ReplicatedStorage:WaitForChild("NextWave")
local selectionEvent = ReplicatedStorage:WaitForChild("SelectionEvent")

-- vars 
local button = script.Parent
local window = button.Parent
local player = game.Players.LocalPlayer

local function clicked()
	selectionEvent:FireServer(2)
end

button.MouseButton1Click:Connect(clicked)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local nextWaveEvent = ReplicatedStorage:WaitForChild("NextWave")
local selectionEvent = ReplicatedStorage:WaitForChild("SelectionEvent")
local rerollEvent = ReplicatedStorage:WaitForChild("RerollEvent")

-- vars 
local button = script.Parent
local window = button.Parent
local player = game.Players.LocalPlayer

local function clicked()
	selectionEvent:FireServer(1)
	rerollEvent:FireServer()
end

button.MouseButton1Click:Connect(clicked)

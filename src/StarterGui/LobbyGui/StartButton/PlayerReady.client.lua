local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local readyEvent = ReplicatedStorage:FindFirstChild("PlayerReady") or Instance.new("RemoteEvent")
readyEvent.Name = "PlayerReady"
readyEvent.Parent = ReplicatedStorage

local gameOverEvent = ReplicatedStorage:FindFirstChild("GameOverEvent") or Instance.new("RemoteEvent")
gameOverEvent.Name = "GameOverEvent"
gameOverEvent.Parent = ReplicatedStorage

local readyButton = script.Parent
local lobbyGui = readyButton.Parent

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

readyButton.Active = true
lobbyGui.Enabled = true

readyButton.Activated:Connect(function()
    readyEvent:FireServer()

    readyButton.Active = false
    lobbyGui.Enabled = false

end)

gameOverEvent.OnClientEvent:Connect(function()
    -- print("Game over event received!")
    
    readyButton.Text = "Restart"
    readyButton.Active = true
    lobbyGui.Enabled = true

end)



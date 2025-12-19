local ReplicatedStorage = game:GetService("ReplicatedStorage")

local button = script.Parent

local gameOverEvent = ReplicatedStorage:FindFirstChild("GameOverEvent") or Instance.new("RemoteEvent")
gameOverEvent.Name = "GameOverEvent"
gameOverEvent.Parent = ReplicatedStorage


button.Activated:Connect(function()
    button.Text = "Empty"
end)

gameOverEvent.OnClientEvent:Connect(function()
    -- print("Game over event received!")
    
    button.Text = "Empty"

end)

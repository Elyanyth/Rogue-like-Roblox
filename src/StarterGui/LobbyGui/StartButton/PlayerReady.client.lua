local ReplicatedStorage = game:GetService("ReplicatedStorage")

local readyEvent = ReplicatedStorage:FindFirstChild("PlayerReady")
if not readyEvent then
    readyEvent = Instance.new("RemoteEvent")
    readyEvent.Name = "PlayerReady"
    readyEvent.Parent = ReplicatedStorage
end


local readyButton = script.Parent
local lobbyGui = readyButton.Parent

readyButton.Activated:Connect(function()
    readyEvent:FireServer()

    readyButton.Active = false
    lobbyGui.Enabled = false

end)
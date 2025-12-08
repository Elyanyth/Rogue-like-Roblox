local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerReady = ReplicatedStorage:WaitForChild("PlayerReady")

local button = script.Parent  -- The TextButton

button.MouseButton1Click:Connect(function()
	-- Fire to the server when clicked
	PlayerReady:FireServer()
end)

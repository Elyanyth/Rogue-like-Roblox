local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rerollEvent = ReplicatedStorage:WaitForChild("RerollEvent")

local button = script.Parent  -- The TextButton

button.MouseButton1Click:Connect(function()
	-- Fire to the server when clicked
	rerollEvent:FireServer()
end)


rerollEvent.OnClientEvent:Connect(function(Price)
	
	button.Text = "Reroll - " .. Price .. "$"	
	
end)
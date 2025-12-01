Players = game:GetService("Players")

playerData = game.ServerStorage.PlayerData:WaitForChild("Rakinorf - 21391918")
money = playerData.Stats:WaitForChild("Money")

print(money.Value)

money.Changed:Connect(function(newValue)
	print("Money changed:", newValue) -- set a breakpoint here
end)

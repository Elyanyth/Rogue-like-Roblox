local MoneyModule = {}

-- Services
ReplicatedStorage = game:GetService("ReplicatedStorage")
ServerStorage = game:GetService("ServerStorage")
ServerScriptService = game:GetService("ServerScriptService")

-- Events
MoneyEvent = ReplicatedStorage:WaitForChild("MoneyEvent")

-- Requirements
PlayerDataModule = require(ServerScriptService.plrDataModule)


function MoneyModule.Get(Player)
	
	local PlayerStats = PlayerDataModule.fetchPlrStats(Player)
	MoneyEvent:FireClient(Player, PlayerStats.Money.Value, "update")
	
end


function MoneyModule.Income(Player)
	
	local PlayerStats = PlayerDataModule.fetchPlrStats(Player)
	PlayerStats.Money.Value = PlayerStats.Money.Value + PlayerStats.Income.Value
	MoneyEvent:FireClient(Player, PlayerStats.Money.Value, "update")

end

function MoneyModule.Remove(Player, Amount)
	
	local PlayerStats = PlayerDataModule.fetchPlrStats(Player)
	PlayerStats.Money.Value = PlayerStats.Money.Value - Amount
	MoneyEvent:FireClient(Player, PlayerStats.Money.Value, "update")
	
end


return MoneyModule

local MoneyModule = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local PlayerDataModule = Modules.Get("PlayerData")

-- Events
local MoneyEvent = ReplicatedStorage:WaitForChild("MoneyEvent")


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

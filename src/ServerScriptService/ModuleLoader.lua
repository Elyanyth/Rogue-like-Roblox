-- ServerScriptService.ModuleLoader
local ModuleLoader = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folders = {

    ShopScripts = "ShopScripts"


}

-- Define all module paths in one place
local Modules = {
	-- Player Systems
	PlayerData = ServerScriptService:WaitForChild("PlayerManegmentScripts"):WaitForChild("plrDataModule"),
	
    -- Shop Systems
	LootModule = ServerScriptService:WaitForChild("ShopScripts"):WaitForChild("LootModule"),
	LootTable = ServerScriptService:WaitForChild("ShopScripts"):WaitForChild("LootTable"),
	MoneyModule = ServerScriptService:WaitForChild("ShopScripts"):WaitForChild("MoneyModule"),
	RerollModule = ServerScriptService:WaitForChild("ShopScripts"):WaitForChild("RerollModule"),
	StatManager = ServerScriptService:WaitForChild("StatManager"),

	
	-- Wave Systems
	WaveModule = ServerScriptService:WaitForChild("WaveScripts"):WaitForChild("WaveModule"),
	ReadyCheck = ServerScriptService:WaitForChild("GameScripts"):WaitForChild("ReadyCheck"),
	MobSpawner = ServerScriptService:WaitForChild("WaveScripts"):WaitForChild("MobSpawner"),
	GameControler = ServerScriptService:WaitForChild("WaveScripts"):WaitForChild("GameControler"),


	-- Combat Systems
	BaseEnemy = ServerScriptService:WaitForChild("EnemyScripts"):WaitForChild("BaseAi"),
	EnemyTypes = ServerScriptService:WaitForChild("EnemyScripts"):WaitForChild("enemyTypes"),
	DifficultyModule = ServerScriptService:WaitForChild("EnemyScripts"):WaitForChild("DifficultyModule"),
	DamageModule = ServerScriptService:WaitForChild("DamageModule"),

	-- Utilities
	GenericFunctions = ServerScriptService:WaitForChild("GenericFunctions"),
	PlayerStats = ServerScriptService:WaitForChild("ShopScripts"):WaitForChild("PlayerStats"),
	
	-- Abilities 
	BaseAbility = ServerScriptService:WaitForChild("Abilities"):WaitForChild("BaseAbility"),


	-- Items
	ItemManager = ServerScriptService:WaitForChild("ItemManager"),

	-- Shared (ReplicatedStorage)
	-- SharedUtils = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SharedUtils"),
}

-- Cache loaded modules to avoid repeated requires
local LoadedModules = {}

function ModuleLoader.Get(moduleName)
	-- Return cached module if already loaded
	if LoadedModules[moduleName] then
		return LoadedModules[moduleName]
	end
	
	-- Load module
	local modulePath = Modules[moduleName]
	if not modulePath then
		error(`Module "{moduleName}" not found in ModuleLoader`)
	end
	
	local success, result = pcall(function()
		return require(modulePath)
	end)
	
	if not success then
		error(`Failed to load module "{moduleName}": {result}`)
	end
	
	-- Cache and return
	LoadedModules[moduleName] = result
	return result
end

return ModuleLoader
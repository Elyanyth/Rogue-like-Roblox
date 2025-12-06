local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local EnemyAi = Modules.Get("BaseEnemy")


local enemy  = script.Parent
EnemyAi.Active(enemy)

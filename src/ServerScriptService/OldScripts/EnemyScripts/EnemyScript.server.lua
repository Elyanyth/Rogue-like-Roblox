local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local BaseAi = Modules.Get("BaseEnemy")
local enemyTypes = Modules.Get("EnemyTypes")

local enemy  = script.Parent
if enemy ~= ServerScriptService.EnemyScripts then 
    local enemyType = enemyTypes[enemy.Name]
    BaseAi.Active(enemy, enemyType)
end 

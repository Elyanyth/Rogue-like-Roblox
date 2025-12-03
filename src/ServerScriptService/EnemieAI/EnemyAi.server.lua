local ServerScriptService = game:GetService("ServerScriptService")


-- Modules
local BaseAi = require(ServerScriptService.EnemieAI:WaitForChild("BaseAi"))


local enemy  = script.Parent
local enemyType = enemy.Name
BaseAi.Active(enemy, enemyType)


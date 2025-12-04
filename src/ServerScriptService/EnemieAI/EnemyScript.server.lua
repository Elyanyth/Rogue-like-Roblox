local ServerScriptService = game:GetService("ServerScriptService")


-- Modules
local BaseAi = require(ServerScriptService.EnemieAI:WaitForChild("BaseAi"))
local enemyTypes = require(ServerScriptService.EnemieAI.enemyTypes)

local enemy  = script.Parent
local enemyType = enemyTypes[enemy.Name]
BaseAi.Active(enemy, enemyType)

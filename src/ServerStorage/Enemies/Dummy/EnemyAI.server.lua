local ServerScriptService = game:GetService("ServerScriptService")


-- Modules
local EnemyAi = require(ServerScriptService.EnemieAI:WaitForChild("BaseAi"))


local enemy  = script.Parent
EnemyAi.Active(enemy)

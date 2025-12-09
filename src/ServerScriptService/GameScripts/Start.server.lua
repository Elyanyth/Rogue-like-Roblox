local ServerScriptService = game:GetService("ServerScriptService")

-- Modules
local Modules = require(ServerScriptService.ModuleLoader)
local GameController = Modules.Get("GameControler")
local ReadyCheck = Modules.Get("ReadyCheck")

local PlayersReady = ReadyCheck.new()

PlayersReady:WaitForAllReady()
GameController.Start()
PlayersReady = nil 
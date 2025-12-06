local RerollModule = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService.ModuleLoader)
local WaveModule = Modules.Get("WaveModule")


function RerollModule.BasePrice() 
	
	local BasePrice = 3 * (WaveModule.Get())
	return BasePrice
	
end



return RerollModule

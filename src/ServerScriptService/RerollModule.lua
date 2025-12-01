local RerollModule = {}

local ServerScriptService = game:GetService("ServerScriptService")

WaveModule = require(ServerScriptService.WaveModule)


function RerollModule.BasePrice() 
	
	local BasePrice = 3 * (WaveModule.Get())
	return BasePrice
	
end



return RerollModule

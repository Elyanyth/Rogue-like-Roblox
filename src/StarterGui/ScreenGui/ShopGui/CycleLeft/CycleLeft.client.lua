-- UI Cycle
local gui = script.Parent.Parent
local uiList = {gui.Shop, gui.Inventory}
local cycleLeft = gui.CycleLeft
local cycleRight = gui.CycleRight
local currentUI = 1

cycleLeft.MouseButton1Click:Connect(function()

	uiList[currentUI].Visible = false

	currentUI -= 1 
	if currentUI < 1 then
		currentUI = #uiList
	end

	uiList[currentUI].Visible = true

end)

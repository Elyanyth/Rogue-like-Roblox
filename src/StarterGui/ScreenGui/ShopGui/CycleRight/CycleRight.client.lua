-- UI Cycle
local gui = script.Parent.Parent
local uiList = {gui.Shop, gui.Inventory}
local cycleRight = gui.CycleRight
local currentUI = 1

cycleRight.MouseButton1Click:Connect(function()

	uiList[currentUI].Visible = false

	currentUI += 1 
	if currentUI > #uiList then
		currentUI = 1
	end

	uiList[currentUI].Visible = true

end)

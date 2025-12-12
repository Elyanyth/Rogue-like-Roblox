local button = script.Parent
local shopUi = button.Parent:WaitForChild("ShopGui")

local isOpen = true -- Track if the shop is open or closed

button.MouseButton1Click:Connect(function()
	isOpen = not isOpen   -- Flip the state (true/false)
	shopUi.Enabled = isOpen
end)

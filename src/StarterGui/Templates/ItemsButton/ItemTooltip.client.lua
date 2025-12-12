local button = script.Parent
local userInput = game:GetService("UserInputService")
local tooltip = button.Tooltip

local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local ScreenGui = Player.PlayerGui.ScreenGui.ShopGui

-- Text you want to show when hovering
local tooltipText = "This is a tooltip!"

-- When mouse enters the button
button.MouseEnter:Connect(function()
    tooltip.ZIndex = 999
   
    tooltip.Parent = ScreenGui
	tooltip.Text = tooltipText
	tooltip.Visible = true

	-- Update tooltip position to follow mouse
	local moveConn
	moveConn = userInput.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tooltip.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
		end
	end)

	-- Store the connection so we can disconnect it later
	button.MouseLeave:Once(function()
		if moveConn then
			moveConn:Disconnect()
		end
	end)
end)

-- When mouse leaves the button
button.MouseLeave:Connect(function()
    tooltip.Parent = button
	tooltip.Visible = false
end)

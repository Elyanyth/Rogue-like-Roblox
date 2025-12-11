local originalButton = script.Parent
local UIS = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

local shopGui = Player.PlayerGui.ScreenGui.ShopGui

local dragging = false
local dragClone = nil
local offset = Vector2.new()

-- Make a draggable clone
local function createDragClone()
	local clone = originalButton:Clone()
	clone.Parent = shopGui -- same ScreenGui tree
	clone.ZIndex = 999 -- make sure it's on top

	-- FIXED: Convert AbsoluteSize (Vector2) into UDim2
	clone.Size = UDim2.fromOffset(originalButton.AbsoluteSize.X, originalButton.AbsoluteSize.Y)

	-- Position clone exactly where the button is on screen
	clone.Position = UDim2.fromOffset(originalButton.AbsolutePosition.X, originalButton.AbsolutePosition.Y)

	-- Remove layout constraints
	local layout = clone:FindFirstChildWhichIsA("UIGridLayout")
	if layout then layout:Destroy() end

	return clone
end

local hoveredButtons = shopGui.AbilitiesInventory.Abilities.Equiped

local function getHoveredButton()
	for _, ui in pairs(hoveredButtons:GetChildren()) do
		-- Only look for Buttons (TextButton/ImageButton etc.)
		if ui ~= originalButton and ui:IsA("TextButton") then
			local absPos = ui.AbsolutePosition
			local absSize = ui.AbsoluteSize

			local xInRange = Mouse.X >= absPos.X and Mouse.X <= absPos.X + absSize.X
			local yInRange = Mouse.Y >= absPos.Y and Mouse.Y <= absPos.Y + absSize.Y

			if xInRange and yInRange then
				return ui
			end
		end
	end
	return nil
end

originalButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true

		offset = Vector2.new(
			Mouse.X - originalButton.AbsolutePosition.X,
			Mouse.Y - originalButton.AbsolutePosition.Y
		)

		dragClone = createDragClone()

		-- hide original (grid keeps the slot)
		originalButton.Visible = false
	end
end)

originalButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false

		-- Detect what button mouse is over
		local target = getHoveredButton()

		if target then
			-- Copy text into the button you dropped on
			target.Text = originalButton.Text
		end

		-- Remove the drag clone
		if dragClone then
			dragClone:Destroy()
			dragClone = nil
		end

		-- Restore original
		originalButton.Visible = true
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and dragClone and input.UserInputType == Enum.UserInputType.MouseMovement then
		dragClone.Position = UDim2.fromOffset(
			Mouse.X - offset.X,
			Mouse.Y - offset.Y
		)
	end
end)

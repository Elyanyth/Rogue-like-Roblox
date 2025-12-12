-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")

-- Events 
local ItemsAddedEvent = ReplicatedStorage:WaitForChild("ItemsAddedEvent")

-- GUI
local TemplateFolder = StarterGui.Templates
local ScrollingFrame = script.Parent:FindFirstChild("ScrollingFrame")
local ItemBoxTemplate = TemplateFolder.ItemsButton


local function onItemsAdded(items)
	print("Items received:", items)

	-- Keep track of which items we've updated
	local updatedItems = {}

	-- FIRST: Update existing item boxes
	for _, box in ipairs(ScrollingFrame:GetChildren()) do
		if box:IsA("TextButton") and box ~= ItemBoxTemplate then
			local itemName = box:GetAttribute("ItemName")

			if itemName and items[itemName] then
				-- Update quantity
				box.Text = itemName .. " (x" .. items[itemName] .. ")"
				updatedItems[itemName] = true
			else
				-- Item no longer exists → hide it
				box.Visible = false
			end
		end
	end

	-- SECOND: Create boxes for items that don't have a UI yet
	for itemName, itemData in pairs(items) do
		if not updatedItems[itemName] then
			local newBox = ItemBoxTemplate:Clone()
			newBox.Visible = true
			newBox.Name = itemName .. "_Slot"
			newBox.Text = itemName .. " (x" .. itemData[1] .. ")"
			
			local tooltip = newBox.Tooltip
			tooltip.Text = (itemData[2])

			-- Store the item name so we can identify this box later
			newBox:SetAttribute("ItemName", itemName)

			newBox.Parent = ScrollingFrame
		end
	end
end


ItemsAddedEvent.OnClientEvent:Connect(onItemsAdded)

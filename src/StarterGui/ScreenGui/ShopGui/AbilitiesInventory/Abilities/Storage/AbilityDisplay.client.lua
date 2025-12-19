-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")

-- Events 
local AbilityAddedEvent = ReplicatedStorage:WaitForChild("AbilityAddedEvent")

local gameOverEvent = ReplicatedStorage:FindFirstChild("GameOverEvent") or Instance.new("RemoteEvent")
gameOverEvent.Name = "GameOverEvent"
gameOverEvent.Parent = ReplicatedStorage

-- GUI
local TemplateFolder = StarterGui.Templates
local ScrollingFrame = script.Parent:FindFirstChild("ScrollingFrame")
local ItemBoxTemplate = TemplateFolder.AbilitiesButton


local function onItemsAdded(items)
	print("Ability received:", items)

	-- Keep track of which items we've updated
	local updatedItems = {}

	-- FIRST: Update existing item boxes
	for _, box in ipairs(ScrollingFrame:GetChildren()) do
		if box:IsA("TextButton") and box ~= ItemBoxTemplate then
			local itemName = box:GetAttribute("ItemName")

			if itemName and items[itemName] then
				-- Update quantity
				box.Text = itemName
				updatedItems[itemName] = true
			else
				-- Item no longer exists → hide it
				box.Visible = false
			end
		end
	end

	-- SECOND: Create boxes for items that don't have a UI yet
	for itemName, quantity in pairs(items) do
		if not updatedItems[itemName] then
			local newBox = ItemBoxTemplate:Clone()
			newBox.Visible = true
			newBox.Name = itemName .. "_Slot"
			newBox.Text = itemName

			-- Store the item name so we can identify this box later
			newBox:SetAttribute("ItemName", itemName)

			newBox.Parent = ScrollingFrame
		end
	end
end


local function OnRemove()
	for _, box in ipairs(ScrollingFrame:GetChildren()) do
		if box:IsA("TextButton") and box ~= ItemBoxTemplate then
			local itemName = box:GetAttribute("ItemName")

			if itemName ~= "PrimaryAttack" then
				box:Destroy()
			end
		end
	end
end


AbilityAddedEvent.OnClientEvent:Connect(onItemsAdded)
gameOverEvent.OnClientEvent:Connect(OnRemove)
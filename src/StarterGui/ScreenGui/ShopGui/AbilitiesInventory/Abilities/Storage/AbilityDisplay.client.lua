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

-- Equipped slots (Slot1–Slot5 TextButtons inside the sibling Equiped folder)
local EquipedFolder = script.Parent.Parent:WaitForChild("Equiped")

local function getSlotsSorted()
	local slots = {}
	for _, slot in ipairs(EquipedFolder:GetChildren()) do
		if slot:IsA("TextButton") then
			table.insert(slots, slot)
		end
	end
	table.sort(slots, function(a, b) return a.Name < b.Name end)
	return slots
end

local function autoEquip(abilityName)
	local slots = getSlotsSorted()
	-- Don't equip if already in a slot (guards against duplicate event fires)
	for _, slot in ipairs(slots) do
		if slot.Text == abilityName then return end
	end
	for _, slot in ipairs(slots) do
		if slot.Text == "Empty" then
			slot.Text = abilityName
			break
		end
	end
end


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

	-- SECOND: Create boxes for items that don't have a UI yet, then auto-equip
	for itemName, _ in pairs(items) do
		if not updatedItems[itemName] then
			local newBox = ItemBoxTemplate:Clone()
			newBox.Visible = true
			newBox.Name = itemName .. "_Slot"
			newBox.Text = itemName

			-- Store the item name so we can identify this box later
			newBox:SetAttribute("ItemName", itemName)

			newBox.Parent = ScrollingFrame

			-- Auto-assign to the first empty equipped slot
			autoEquip(itemName)
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer

-- Buttons
local gui = script.Parent -- The ScreenGui
local shopGui = gui.ShopGui
local Timer = gui:WaitForChild("Timer")
local nextButton = shopGui:WaitForChild("Next")
local shop = shopGui:WaitForChild("Shop")
local cycleLeft = shopGui:WaitForChild("CycleLeft")
local cycleRight = shopGui:WaitForChild("CycleRight")
local MoneyDisplay = shopGui:WaitForChild("MoneyDisplay")

local timerEvent = ReplicatedStorage:WaitForChild("TimerUpdate")
local lootEvent = ReplicatedStorage:WaitForChild("LootEvent")
local waveEvent = ReplicatedStorage:WaitForChild("NextWave")
local MoneyEvent = ReplicatedStorage:WaitForChild("MoneyEvent")

-- Player Data Vars

local playerDataEvent = ReplicatedStorage:WaitForChild("PlayerDataEvent")
local localPlr = game.Players.LocalPlayer

-- Listen for timer updates from server
timerEvent.OnClientEvent:Connect(function(timeLeft)
	Timer.Text = "Time Left: " .. tostring(timeLeft) .. "s"
	
	if timeLeft == 0 then 
		
		shopGui.Enabled = true
		nextButton.Visible = true
		cycleLeft.Visible = true
		cycleRight.Visible = true
		
		nextButton.Interactable = true
		nextButton. Active = true
		
		MoneyEvent:FireServer("get")
		
	else 
		shopGui.Enabled = false
		nextButton.Visible = false
		cycleLeft.Visible = false
		cycleRight.Visible = false
		
		nextButton.Interactable = false
		nextButton. Active = false
	end 
	
end)

waveEvent.OnClientEvent:Connect(function(waveCount)
	local waveLabel = gui:WaitForChild("WaveCount")
	waveLabel.Text ="Wave " .. tostring(waveCount)

	
end)

lootEvent.OnClientEvent:Connect(function(lootTable)
	
	--print(lootTable[1].id)
	--print(shop:GetChildren())
	for i, button in ipairs(shop.Loot:GetChildren()) do
		if button:IsA("TextButton") then
			button.TextBox.Text = lootTable[i-1].id .. " + " .. lootTable[i-1].amount
		end
	end

end)

MoneyEvent.OnClientEvent:Connect(function(Money, Action)
	
	if Action == "update" then
		MoneyDisplay.Text = "Money : " .. tostring(Money)		
	end
	
end)

-- Cycle UI 

local uiList = {shopGui.Shop, shopGui.Inventory, shopGui.AbilitiesInventory}
local cycleLeft = shopGui.CycleLeft
local cycleRight = shopGui.CycleRight
local currentUI = 1

local Inventory = shopGui:WaitForChild("Inventory")


cycleLeft.MouseButton1Click:Connect(function()

	uiList[currentUI].Visible = false
	uiList[currentUI].Active = false

	currentUI -= 1 
	if currentUI < 1 then
		currentUI = #uiList
	end

	uiList[currentUI].Visible = true
	uiList[currentUI].Active = true
	
	-- fetch plr data when on correct menu
	if Inventory.Visible or Inventory.Active then 
		print("Fired Server")
		playerDataEvent:FireServer(localPlr)
	end

end)

cycleRight.MouseButton1Click:Connect(function()

	uiList[currentUI].Visible = false
	uiList[currentUI].Active = false


	currentUI += 1 
	if currentUI > #uiList then
		currentUI = 1
	end

	uiList[currentUI].Visible = true
	uiList[currentUI].Active = true

	-- fetch plr data when on correct menu
	if Inventory.Visible or Inventory.Active then 
		--print("Fired Server")
		playerDataEvent:FireServer(localPlr)
	end



end)

-- Modify when items are added
local statBoxGenerated = false
 
playerDataEvent.OnClientEvent:Connect(function(plrData)
	
	print(plrData)
	local statsDisplay = Inventory.Stats.ScrollingFrame
	
	for statName, statValue in pairs(plrData) do
		
		local stat
		
		if statBoxGenerated == false then
			
			stat = statsDisplay.TextBox:Clone()
			stat.Name = statName
			stat.Parent = statsDisplay
				
			
		else 
			stat = statsDisplay:FindFirstChild(statName)
		end
		
		stat.Text = statName .. " : " .. tostring(statValue)
	end
	
	if statBoxGenerated == false then 
		statsDisplay.TextBox:Destroy()
	end
	
	statBoxGenerated = true

end)




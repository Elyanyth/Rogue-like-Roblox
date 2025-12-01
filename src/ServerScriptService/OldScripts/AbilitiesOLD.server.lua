local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:getService("ServerStorage")

-- Store cooldown times for each player
-- cooldowns[player] = { ["AbilityName"] = os.clock() + cooldownTime }
local cooldowns = {}
-- Tracks active spawns for each player
local activeSpawns = {}

-- Define cooldown times for each ability
local abilityCooldowns = {
	Fireball = 4,         -- Q
	IceBlast = 7,         -- E
	Heal = 10,            -- R
	PrimaryAttack = 0.5,  -- Left Click
	SecondaryAttack = 2   -- Right Click
}

-- RemoteEvent for client → server
local AbilityEvent = ReplicatedStorage:FindFirstChild("AbilityEvent") or Instance.new("RemoteEvent")
AbilityEvent.Name = "AbilityEvent"
AbilityEvent.Parent = ReplicatedStorage

-- Function to spawn a part in front of the player
local function spawnPartInFront(player, abilityName, mousePos)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local root = player.Character.HumanoidRootPart
	local forward = root.CFrame.LookVector -- Player's facing direction

	-- Create the part
	local part = ServerStorage.Abilitys:FindFirstChild(abilityName):Clone()
	part.CFrame = CFrame.new(root.CFrame.Position, Vector3.new(mousePos.Position.X, root.Position.Y, mousePos.Position.Z)) * CFrame.new(0, 0, -5)
	part.Parent = workspace

	game:GetService("Debris"):AddItem(part, 0.5)
end

-- Helper to start spawning parts as long as ability is on cooldown
local function startSpawningDuringCooldown(player, abilityName)
	-- Prevent multiple loops for the same player/ability
	activeSpawns[player] = activeSpawns[player] or {}
	if activeSpawns[player][abilityName] then
		return
	end

	activeSpawns[player][abilityName] = true

	task.spawn(function()
		while true do
			local now = os.clock()
			local nextUseTime = cooldowns[player] and cooldowns[player][abilityName] or 0
			if now >= nextUseTime then
				break
			end
			spawnPartInFront(player)
			task.wait(0.1)
		end
		if activeSpawns[player] then
			activeSpawns[player][abilityName] = nil
		end
	end)
end

local function SpawnAtMouse(player, abilityName, mousePos)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local root = player.Character.HumanoidRootPart
	local forward = root.CFrame.LookVector -- Player's facing direction
	
	-- Create the part
	local part = ServerStorage.Abilitys:FindFirstChild(abilityName):Clone()
	part.Position = mousePos.Position
	part.Parent = workspace
	
	game:GetService("Debris"):AddItem(part, 0.2)
end

AbilityEvent.OnServerEvent:Connect(function(player, abilityName, mousePos, spawnType)
	local now = os.clock()
	
	-- Validate ability
	local cdTime = abilityCooldowns[abilityName]
	if not cdTime then
		warn("Unknown ability: " .. tostring(abilityName))
		return
	end

	-- Setup cooldown tracking for this player if needed
	cooldowns[player] = cooldowns[player] or {}
	local nextUseTime = cooldowns[player][abilityName] or 0

	-- Check cooldown
	if now < nextUseTime then
		--print(player.Name .. " tried to use " .. abilityName .. " but it's on cooldown.")
		return
	end

	-- Ability is ready — activate it
	--print(player.Name .. " used " .. abilityName)

	-- Set next available time
	cooldowns[player][abilityName] = now + cdTime

	---- Ability effects
	--if abilityName == "PrimaryAttack" then
	--	startSpawningDuringCooldown (player, "PrimaryAttack")
	--elseif abilityName == "IceBlast" then
	--	SpawnAtMouse(player, "IceBlast", mousePos)
	--end
	
	local ability = ServerStorage.Abilitys:FindFirstChild(abilityName)
	if ability then
		if spawnType == "Mouse" then
			SpawnAtMouse(player, abilityName, mousePos)
		else 
			spawnPartInFront(player, abilityName, mousePos)
		end
	end

	-- Tell client to start cooldown UI
	AbilityEvent:FireClient(player, abilityName, cdTime)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil -- cleanup
end)

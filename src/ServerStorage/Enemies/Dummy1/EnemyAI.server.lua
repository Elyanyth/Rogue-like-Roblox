local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local enemy = script.Parent -- Enemy model
local humanoid = enemy:FindFirstChild("Humanoid")
local rootPart = enemy:FindFirstChild("HumanoidRootPart")

local CHASE_RANGE = 1000 -- Detection range
local SPEED = 12 -- Enemy walk speed
local DAMAGE = 20 -- Damage dealt to the player
local HEALTH = 100 
local ATTACK_RANGE = 2 -- How close enemy must be to attack
local ATTACK_COOLDOWN = 1 -- Seconds between attacks

local lastAttackTime = 0
local isAlive = true

humanoid.WalkSpeed = SPEED
humanoid.Health = HEALTH

-- Modules
local playerStatsModule = require(ServerScriptService:WaitForChild("plrDataModule"))
local EnemieAi = ServerScriptService.EnemieAI.ChaseEnemie

-- Check if a character belongs to a real player
local function isPlayerCharacter(character)
	local player = Players:GetPlayerFromCharacter(character)
	return player ~= nil
end

-- Find closest player
local function getClosestPlayer()
	local closestPlayer = nil
	local closestDist = CHASE_RANGE + 1

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
			if dist <= CHASE_RANGE and dist < closestDist then
				closestDist = dist
				closestPlayer = player
			end
		end
	end
	return closestPlayer
end

-- Damage player function (safe)
local function tryAttackPlayer(targetCharacter)
	if not isAlive then return end -- stop if dead
	if targetCharacter == enemy then return end
	if not isPlayerCharacter(targetCharacter) then return end

	if tick() - lastAttackTime >= ATTACK_COOLDOWN then
		local playerHumanoid = targetCharacter:FindFirstChild("Humanoid")
		if playerHumanoid and playerHumanoid ~= humanoid then
			local plr = Players:GetPlayerFromCharacter(targetCharacter)
			local plrStats = playerStatsModule.fetchPlrStatsTable(plr)
			
			playerHumanoid:TakeDamage(math.max(0, DAMAGE - plrStats.armor))
			lastAttackTime = tick()
		end
	end
end

-- Death event
humanoid.Died:Connect(function()
	isAlive = false
	humanoid.WalkSpeed = 0
	-- Remove after 1 seconds
	task.delay(1, function()
		if enemy then
			enemy:Destroy()
		end
	end)
end)

-- Chase Loop
RunService.Heartbeat:Connect(function(dt)
	if not isAlive then return end

	local targetPlayer = getClosestPlayer()

	if targetPlayer then
		local targetHRP = targetPlayer.Character.HumanoidRootPart
		local distToTarget = (targetHRP.Position - rootPart.Position).Magnitude

		if distToTarget <= ATTACK_RANGE then
			tryAttackPlayer(targetPlayer.Character)
		else
			-- Move directly toward the target's position
			humanoid:MoveTo(targetHRP.Position)

			-- Wait until the humanoid reaches the point or something interrupts
			humanoid.MoveToFinished:Wait()

			-- Stop chasing if target is out of range
			if distToTarget > CHASE_RANGE then
				humanoid:MoveTo(rootPart.Position) -- stop moving
				return
			end
		end
	else
		return
	end
end)


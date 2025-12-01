local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ENEMY_FOLDER = workspace:WaitForChild("Enemies") -- Put all enemy models here

local CHASE_RANGE = 1000 -- Detection range
local SPEED = 16 -- Enemy walk speed
local DAMAGE = 20 -- Damage dealt to the player
local ATTACK_RANGE = 2 -- How close enemy must be to attack
local ATTACK_COOLDOWN = 1 -- Seconds between attacks

-- Check if a character belongs to a real player
local function isPlayerCharacter(character)
	local player = Players:GetPlayerFromCharacter(character)
	return player ~= nil
end

-- Damage player function (safe)
local function tryAttackPlayer(enemyHumanoid, targetCharacter, lastAttackTime)
	if not enemyHumanoid or enemyHumanoid.Health <= 0 then return lastAttackTime end
	if targetCharacter == enemyHumanoid.Parent then return lastAttackTime
	end
	if not isPlayerCharacter(targetCharacter) then return lastAttackTime end

	if tick() - lastAttackTime >= ATTACK_COOLDOWN then
		local playerHumanoid = targetCharacter:FindFirstChild("Humanoid")
		if playerHumanoid and playerHumanoid.Health > 0 then
			playerHumanoid:TakeDamage(DAMAGE)
			lastAttackTime = tick()
		end
	end
	return lastAttackTime
end

-- Find closest player to a given enemy
local function getClosestPlayer(enemyRoot)
	local closestPlayer = nil
	local closestDist = CHASE_RANGE + 1

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - enemyRoot.Position).Magnitude
			if dist <= CHASE_RANGE and dist < closestDist then
				closestDist = dist
				closestPlayer = player
			end
		end
	end
	return closestPlayer
end

-- Setup each enemy
for _, enemy in pairs(ENEMY_FOLDER:GetChildren()) do
	if enemy:IsA("Model") then
		local humanoid = enemy:FindFirstChild("Humanoid")
		local rootPart = enemy:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart then
			humanoid.WalkSpeed = SPEED
			local lastAttackTime = 0
			local isAlive = true

			humanoid.Died:Connect(function()
				isAlive = false
				humanoid.WalkSpeed = 0
				task.delay(3, function()
					if enemy then enemy:Destroy() end
				end)
			end)

			-- Heartbeat loop for this enemy
			RunService.Heartbeat:Connect(function()
				if not isAlive then return end

				local targetPlayer = getClosestPlayer(rootPart)
				if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local targetHRP = targetPlayer.Character.HumanoidRootPart
					local distToTarget = (targetHRP.Position - rootPart.Position).Magnitude

					if distToTarget <= ATTACK_RANGE then
						lastAttackTime = tryAttackPlayer(humanoid, targetPlayer.Character, lastAttackTime)
					else
						local path = PathfindingService:CreatePath({
							AgentRadius = 2,
							AgentHeight = 5,
							AgentCanJump = true
						})

						path:ComputeAsync(rootPart.Position, targetHRP.Position)
						local waypoints = path:GetWaypoints()

						for _, waypoint in pairs(waypoints) do
							if not isAlive then break end
							humanoid:MoveTo(waypoint.Position)
							humanoid.MoveToFinished:Wait()
							if (targetHRP.Position - rootPart.Position).Magnitude > CHASE_RANGE then
								break
							end
						end
					end
				end
			end)
		end
	end
end

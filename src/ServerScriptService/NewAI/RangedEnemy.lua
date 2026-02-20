--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy") -- Adjust path to your Enemy superclass
--!strict

local RangedEnemy = setmetatable({}, { __index = Enemy })
RangedEnemy.__index = RangedEnemy

export type RangedEnemyType = Enemy.EnemyType & {
	PreferredDistance: number,
	AttackRange: number,
	AttackCooldown: number,
	LastAttackTime: number,
	ProjectileSpeed: number,
	ProjectileSize: Vector3,
}

function RangedEnemy.new(name: string, speed: number, health: number, damage: number, armor: number): RangedEnemyType
	-- Call parent constructor
	local self = Enemy.new(name, speed, health, damage, armor)
	setmetatable(self, RangedEnemy)
	
	self.PreferredDistance = 15 -- Minimum distance to maintain from player
	self.AttackRange = 20 -- Maximum range for attacks
	self.AttackCooldown = 1 -- Seconds between attacks
	self.LastAttackTime = 0
	self.ProjectileSpeed = 20 -- Studs per second
	self.ProjectileSize = Vector3.new(0.8, 0.8, 0.8) -- Size of projectile
	
	return self
end

-- Override the Chase function to maintain distance and attack
function RangedEnemy:Chase()
	if not self.Model or not self.Humanoid then
		warn("Enemy model not set!")
		return
	end
	
	if not self:IsAlive() then
		return
	end
	
	-- Stop any existing chase
	self:StopChasing()
	
	self.IsChasing = true
	
	-- Chase loop using RunService for smooth updates
	local RunService = game:GetService("RunService")
	
	self.ChaseConnection = RunService.Heartbeat:Connect(function()
		if not self.IsChasing or not self:IsAlive() then
			self:StopChasing()
			return
		end
		
		-- Find nearest player
		local nearestPlayer = self:GetNearestPlayer()
		
		if nearestPlayer and nearestPlayer.Character then
			local targetRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")
			
			if targetRoot and self.Model.PrimaryPart then
				local enemyPosition = self.Model.PrimaryPart.Position
				local targetPosition = targetRoot.Position
				
				-- Calculate distance to target
				local distance = (targetPosition - enemyPosition).Magnitude
				
				if distance > self.AttackRange then
					-- Out of range - move closer to attack range
					self.Humanoid:MoveTo(targetPosition)
				elseif distance < self.PreferredDistance then
					-- Too close - back away to preferred distance
					local retreatDirection = (enemyPosition - targetPosition).Unit
					local retreatPosition = targetPosition + (retreatDirection * self.PreferredDistance)
					self.Humanoid:MoveTo(retreatPosition)
				else
					-- In optimal range (between PreferredDistance and AttackRange)
					-- Stand still and face the player
					self.Humanoid:MoveTo(enemyPosition)
					
					-- Make the enemy face the player
					if self.Model.PrimaryPart then
						local lookDirection = (targetPosition - enemyPosition) * Vector3.new(1, 0, 1) -- Ignore Y
						if lookDirection.Magnitude > 0 then
							self.Model.PrimaryPart.CFrame = CFrame.lookAt(
								self.Model.PrimaryPart.Position,
								self.Model.PrimaryPart.Position + lookDirection
							)
						end
					end
					
					-- Attack if cooldown is ready
					local currentTime = tick()
					if currentTime - self.LastAttackTime >= self.AttackCooldown then
						self:Attack(nearestPlayer.Character)
						self.LastAttackTime = currentTime
					end
				end
			end
		else
			-- No valid target found, stop moving
			if self.Model.PrimaryPart then
				self.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
			end
		end
	end)
end

-- Ranged attack function - only fires projectile
function RangedEnemy:Attack(target: Model)
	if not self.Model or not self.Model.PrimaryPart then
		return
	end
	
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return
	end
	
	-- Check if target is in attack range
	local distance = (targetRoot.Position - self.Model.PrimaryPart.Position).Magnitude
	
	if distance <= self.AttackRange then
		print(self.Name .. " fired a projectile!")
		-- Fire projectile toward player's current position
		self:FireProjectile(targetRoot.Position, target)
	end
end

-- Fire a dodgeable projectile
function RangedEnemy:FireProjectile(targetPosition: Vector3, target: Model)
	if not self.Model or not self.Model.PrimaryPart then
		return
	end
	
	local Debris = game:GetService("Debris")
	
	-- Create projectile
	local projectile = Instance.new("Part")
	projectile.Size = self.ProjectileSize
	projectile.BrickColor = BrickColor.new("Bright red")
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.Shape = Enum.PartType.Ball
	projectile.Parent = self.Model
	
	-- Position projectile at enemy's position
	local startPos = (self.Model.PrimaryPart.CFrame * CFrame.new(0, 0, -5)).Position -- Slightly above
	projectile.Position = startPos
	
	-- Get player's HumanoidRootPart
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end

	local targetVelocity = targetRoot.AssemblyLinearVelocity

	-- Calculate displacement
	local displacement = targetRoot.Position - startPos
	local distance = displacement.Magnitude

	-- Estimate travel time
	local travelTime = (distance / self.ProjectileSpeed) * 1.05

	-- Predict future position
	local predictedPosition = targetRoot.Position + (targetVelocity * travelTime)

	-- Add random offset around predicted position
	local radius = 8 -- adjust for accuracy (smaller = more accurate)
	local randomAngle = math.random() * math.pi * 2
	local randomRadius = math.sqrt(math.random()) * radius -- even distribution

	local randomOffset = Vector3.new(
		math.cos(randomAngle) * randomRadius,
		0,
		math.sin(randomAngle) * randomRadius
	)

	local finalTargetPosition = predictedPosition + randomOffset

	-- Final direction
	local direction = (finalTargetPosition - startPos).Unit

	
	-- Apply velocity to projectile
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = direction * self.ProjectileSpeed
	bodyVelocity.Parent = projectile
	
	-- Optional: Make projectile face direction of travel
	projectile.CFrame = CFrame.lookAt(startPos, startPos + direction)
	
	-- Handle collision detection
	local hitConnection
	hitConnection = projectile.Touched:Connect(function(hit)
		-- Check if hit the target player
		if hit:IsDescendantOf(target) then
			local humanoid = target:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				if not humanoid:GetAttribute("IsInvincible") then
					humanoid:TakeDamage(self.Damage)
					print(self.Name .. "'s projectile hit for " .. self.Damage .. " damage!")
				end
			end
			
			-- Destroy projectile on hit
			hitConnection:Disconnect()
			projectile:Destroy()
		-- elseif hit.CanCollide and not hit:IsDescendantOf(self.Model) then
		-- 	-- Hit a wall or obstacle
		-- 	hitConnection:Disconnect()
		-- 	projectile:Destroy()
		end
	end)
	
	
	-- Automatically destroy projectile after 5 seconds if it hasn't hit anything
	Debris:AddItem(projectile, 5)
end

return RangedEnemy
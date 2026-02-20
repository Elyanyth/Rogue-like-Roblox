--!strict

local Players = game:GetService("Players")

local Enemy = {}
Enemy.__index = Enemy

local activeEnemies: {EnemyType} = {}

export type EnemyType = {
	Name: string,
	Speed: number,
	Health: number,
	MaxHealth: number,
	Damage: number,
	Armor: number,
	Model: Model?,
	Humanoid: Humanoid?,
	IsChasing: boolean,
	ChaseConnection: RBXScriptConnection?,
	DetectionRange: number,
	TakeDamage: (self: EnemyType, damage: number) -> (),
	Heal: (self: EnemyType, amount: number) -> (),
	IsAlive: (self: EnemyType) -> boolean,
	GetHealthPercentage: (self: EnemyType) -> number,
	SetModel: (self: EnemyType, model: Model) -> (),
	Chase: (self: EnemyType) -> (),
	StopChasing: (self: EnemyType) -> (),
	Attack: (self: EnemyType, target: Model) -> (),
	GetNearestPlayer: (self: EnemyType) -> Player?,
}

function Enemy.new(name: string, speed: number, health: number, damage: number, armor: number): EnemyType
	local self = setmetatable({}, Enemy)

	self.Name = name
	self.Speed = speed
	self.Health = health
	self.MaxHealth = health
	self.Damage = damage
	self.Armor = armor
	self.Model = nil
	self.Humanoid = nil
	self.IsChasing = false
	self.ChaseConnection = nil
	self.DetectionRange = math.huge -- Infinite range by default, can be customized
	self.AttackRange = 3 -- Distance at which enemy can attack
	self.AttackCooldown = 1 -- Seconds between attacks
	self.LastAttackTime = 0

	table.insert(activeEnemies, self)

	return self
end

function Enemy:SetModel(model: Model)
	self.Model = model
	self.Humanoid = model:FindFirstChildOfClass("Humanoid")

	if self.Humanoid then
		self.Humanoid.WalkSpeed = self.Speed
		self.Humanoid.MaxHealth = self.MaxHealth
		self.Humanoid.Health = self.Health
	end
end

function Enemy:GetNearestPlayer(): Player?
	if not self.Model or not self.Model.PrimaryPart then
		return nil
	end

	local nearestPlayer = nil
	local shortestDistance = self.DetectionRange

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

			-- Only target alive players
			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - self.Model.PrimaryPart.Position).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					nearestPlayer = player
				end
			end
		end
	end

	return nearestPlayer
end

function Enemy:Chase()
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

	-- Attack cooldown variables


	self.ChaseConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not self.IsChasing or not self:IsAlive() then
			self:StopChasing()
			return
		end

		-- Find nearest player each frame (allows dynamic retargeting)
		local nearestPlayer = self:GetNearestPlayer()

		if nearestPlayer and nearestPlayer.Character then
			local targetRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")

			if targetRoot and self.Model.PrimaryPart then
				local distance = (targetRoot.Position - self.Model.PrimaryPart.Position).Magnitude

				-- Check if close enough to attack
				if distance <= self.AttackRange then
					-- Check cooldown
					local currentTime = tick()
					if currentTime - self.LastAttackTime >= self.AttackCooldown then
						self:Attack(nearestPlayer.Character)
						self.LastAttackTime = currentTime
					end

					-- Stop moving when in attack range
					self.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
				else
					-- Move directly to nearest player
					self.Humanoid:MoveTo(targetRoot.Position)
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

function Enemy:StopChasing()
	self.IsChasing = false

	if self.ChaseConnection then
		self.ChaseConnection:Disconnect()
		self.ChaseConnection = nil
	end

	if self.Humanoid and self.Model and self.Model.PrimaryPart then
		self.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
	end
end

function Enemy:Attack(target: Model)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if targetHumanoid then
		targetHumanoid:TakeDamage(self.Damage)
		print(self.Name .. " attacked for " .. self.Damage .. " damage!")
	end
end

function Enemy:TakeDamage(damage: number)
	-- Apply armor reduction
	local damageReduction = self.Armor / (self.Armor + 100)
	local actualDamage = damage * (1 - damageReduction)

	self.Health = math.max(0, self.Health - actualDamage)

	if self.Humanoid then
		self.Humanoid.Health = self.Health
	end

	if self.Health <= 0 then
		print(self.Name .. " has been defeated!")
		self:Die()  -- replace self:StopChasing() with self:Die()
	end
end

function Enemy:Heal(amount: number)
	self.Health = math.min(self.MaxHealth, self.Health + amount)
	if self.Humanoid then
		self.Humanoid.Health = self.Health
	end
end

function Enemy:IsAlive(): boolean
	return self.Health > 0
end

function Enemy:GetHealthPercentage(): number
	return (self.Health / self.MaxHealth) * 100
end

function Enemy:Die()
	self:StopChasing()

	if self.Model then
		local Debris = game:GetService("Debris")
		Debris:AddItem(self.Model, 5) -- Model will be cleaned up after 5 seconds
		print(self.Name .. " has been removed from the game.")

		local index = table.find(activeEnemies, self)
		if index then
			table.remove(activeEnemies, index)
		end
	end

end

function Enemy.GetFromHumanoid(humanoid: Humanoid): EnemyType?
	for _, enemy in ipairs(activeEnemies) do
		if enemy.Humanoid == humanoid then
			return enemy
		end
	end
	return nil
end

return Enemy
--!strict
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy")  -- Adjust path to your RangedEnemy class
local RangedEnemy = Modules.Get("RangedEnemy")

local SummonerEnemy = setmetatable({}, { __index = RangedEnemy })
SummonerEnemy.__index = SummonerEnemy

export type SummonerEnemyType = RangedEnemy.RangedEnemyType & {
	SummonCooldown: number,
	LastSummonTime: number,
	MaxSummons: number,
	CurrentSummons: number,
	SummonTemplate: Model?,
	SummonClass: any,
	SummonStats: {
		Name: string,
		Speed: number,
		Health: number,
		Damage: number,
		Armor: number,
	},
	ActiveSummons: {any},
}

function SummonerEnemy.new(name: string, speed: number, health: number, damage: number, armor: number): SummonerEnemyType
	-- Call parent constructor (RangedEnemy)
	local self = RangedEnemy.new(name, speed, health, damage, armor)
	setmetatable(self, SummonerEnemy)
	
	self.SummonCooldown = 5 -- Seconds between summons
	self.LastSummonTime = 0
	self.MaxSummons = 3 -- Maximum number of active summons
	self.CurrentSummons = 0
	self.SummonTemplate = nil -- Model to clone for summons
	self.SummonClass = nil -- Enemy class to use for summons
	self.ActiveSummons = {} -- Track active summoned enemies
	
	-- Default stats for summoned enemies
	self.SummonStats = {
		Name = "Summoned Minion",
		Speed = 12,
		Health = 50,
		Damage = 10,
		Armor = 0,
	}
	
	return self
end

-- Override Chase to include summoning behavior
function SummonerEnemy:Chase()
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
		
		-- Clean up dead summons from tracking
		self:CleanupDeadSummons()
		
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
					-- In optimal range
					self.Humanoid:MoveTo(enemyPosition)
					
					-- Make the enemy face the player
					if self.Model.PrimaryPart then
						local lookDirection = (targetPosition - enemyPosition) * Vector3.new(1, 0, 1)
						if lookDirection.Magnitude > 0 then
							self.Model.PrimaryPart.CFrame = CFrame.lookAt(
								self.Model.PrimaryPart.Position,
								self.Model.PrimaryPart.Position + lookDirection
							)
						end
					end
					
					local currentTime = tick()
					
					-- Try to summon if cooldown is ready and under summon limit
					if currentTime - self.LastSummonTime >= self.SummonCooldown 
						and self.CurrentSummons < self.MaxSummons then
						self:SummonEnemy()
						self.LastSummonTime = currentTime
					end
					
					-- Attack if cooldown is ready
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

-- Summon a new enemy
function SummonerEnemy:SummonEnemy()
	if not self.Model or not self.Model.PrimaryPart then
		warn("Summoner model not set!")
		return
	end
	
	if not self.SummonTemplate and not self.SummonClass then
		warn("No summon template or class set!")
		return
	end
	
	-- Calculate spawn position (around the summoner)
	local spawnOffset = Vector3.new(
		math.random(-5, 5),
		0,
		math.random(-5, 5)
	)
	local spawnPosition = self.Model.PrimaryPart.Position + spawnOffset
	
	-- Create the summoned enemy
	local summonedEnemy
	
	if self.SummonTemplate then
		-- Clone the template model
		local summonModel = self.SummonTemplate:Clone()
		summonModel:PivotTo(CFrame.new(spawnPosition))
		summonModel.Parent = workspace
		
		-- Create enemy instance using the specified class or default Enemy class
		if self.SummonClass then
			summonedEnemy = self.SummonClass.new(
				self.SummonStats.Name,
				self.SummonStats.Speed,
				self.SummonStats.Health,
				self.SummonStats.Damage,
				self.SummonStats.Armor
			)
		else
			-- Fallback to basic Enemy class
			local Enemy = require(script.Parent.Enemy) -- Adjust path as needed
			summonedEnemy = Enemy.new(
				self.SummonStats.Name,
				self.SummonStats.Speed,
				self.SummonStats.Health,
				self.SummonStats.Damage,
				self.SummonStats.Armor
			)
		end
		
		summonedEnemy:SetModel(summonModel)
		summonedEnemy:Chase()
		
		-- Add to tracking
		table.insert(self.ActiveSummons, summonedEnemy)
		self.CurrentSummons = self.CurrentSummons + 1
		
		print(self.Name .. " summoned " .. self.SummonStats.Name .. "!")
		
		-- Optional: Add visual effect
		self:CreateSummonEffect(spawnPosition)
	end
end

-- Create a visual effect when summoning
function SummonerEnemy:CreateSummonEffect(position: Vector3)
	local effect = Instance.new("Part")
	effect.Size = Vector3.new(4, 0.5, 4)
	effect.Position = position
	effect.Anchored = true
	effect.CanCollide = false
	effect.Material = Enum.Material.Neon
	effect.BrickColor = BrickColor.new("Dark indigo")
	effect.Transparency = 0.5
	effect.Shape = Enum.PartType.Cylinder
	effect.Orientation = Vector3.new(0, 0, 90)
	effect.Parent = workspace
	
	-- Tween the effect
	local TweenService = game:GetService("TweenService")
	local tween = TweenService:Create(
		effect,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ 
			Size = Vector3.new(8, 0.5, 8),
			Transparency = 1
		}
	)
	
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
end

-- Clean up dead summons from tracking
function SummonerEnemy:CleanupDeadSummons()
	for i = #self.ActiveSummons, 1, -1 do
		local summon = self.ActiveSummons[i]
		if not summon:IsAlive() then
			table.remove(self.ActiveSummons, i)
			self.CurrentSummons = self.CurrentSummons - 1
		end
	end
end

-- Override StopChasing to also stop all summons
function SummonerEnemy:StopChasing()
	-- Call parent StopChasing
	getmetatable(SummonerEnemy).__index.StopChasing(self)
	
	-- Stop all active summons
	for _, summon in ipairs(self.ActiveSummons) do
		if summon:IsAlive() then
			summon:StopChasing()
		end
	end
end

-- Override TakeDamage to potentially despawn summons on death
function SummonerEnemy:TakeDamage(damage: number)
	-- Call parent TakeDamage
	getmetatable(SummonerEnemy).__index.TakeDamage(self, damage)
	
	-- If summoner dies, optionally despawn all summons
	if not self:IsAlive() then
		for _, summon in ipairs(self.ActiveSummons) do
			if summon.Model then
				summon.Model:Destroy()
			end
		end
		self.ActiveSummons = {}
		self.CurrentSummons = 0
	end
end

return SummonerEnemy
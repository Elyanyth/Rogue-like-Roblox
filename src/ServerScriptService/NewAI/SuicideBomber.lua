--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy")

local SuicideBomber = setmetatable({}, { __index = Enemy })
SuicideBomber.__index = SuicideBomber

export type SuicideBomberType = Enemy.EnemyType & {
	ExplosionDamage: number,
	ExplosionRadius: number,
	TriggerRange: number,
	FuseTime: number,
	IsArmed: boolean,
}

function SuicideBomber.new(name: string, speed: number, health: number, damage: number, armor: number): SuicideBomberType
	local self = Enemy.new(name, speed, health, damage, armor)
	setmetatable(self, SuicideBomber)

	self.ExplosionDamage = 40
	self.ExplosionRadius = 10
	self.TriggerRange = 5
	self.FuseTime = 1.5
	self.IsArmed = false

	return self
end

function SuicideBomber:Chase()
	if not self.Model or not self.Humanoid then
		warn("SuicideBomber model not set!")
		return
	end

	if not self:IsAlive() then
		return
	end

	self:StopChasing()
	self.IsChasing = true

	self.ChaseConnection = RunService.Heartbeat:Connect(function()
		if not self.IsChasing or not self:IsAlive() then
			self:StopChasing()
			return
		end

		-- Once armed, just wait for explosion — don't move
		if self.IsArmed then
			return
		end

		local nearestPlayer = self:GetNearestPlayer()

		if nearestPlayer and nearestPlayer.Character then
			local targetRoot = nearestPlayer.Character:FindFirstChild("HumanoidRootPart")

			if targetRoot and self.Model.PrimaryPart then
				local distance = (targetRoot.Position - self.Model.PrimaryPart.Position).Magnitude

				if distance <= self.TriggerRange then
					-- Arm the fuse
					self.IsArmed = true
					self.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
					task.delay(self.FuseTime, function()
						self:Explode()
					end)
				else
					-- Charge toward player
					self.Humanoid:MoveTo(targetRoot.Position)
				end
			end
		else
			if self.Model.PrimaryPart then
				self.Humanoid:MoveTo(self.Model.PrimaryPart.Position)
			end
		end
	end)
end

function SuicideBomber:Explode()
	if not self:IsAlive() then
		return
	end

	if not self.Model or not self.Model.PrimaryPart then
		return
	end

	local explosionCenter = self.Model.PrimaryPart.Position

	-- Damage all players in radius
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - explosionCenter).Magnitude
				if distance <= self.ExplosionRadius then
					if not humanoid:GetAttribute("IsInvincible") then
						humanoid:TakeDamage(self.ExplosionDamage)
						print(self.Name .. " exploded and hit " .. player.Name .. " for " .. self.ExplosionDamage .. " damage!")
					end
				end
			end
		end
	end

	-- Visual explosion effect
	local diameter = self.ExplosionRadius * 2
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Size = Vector3.new(1, 1, 1)
	sphere.Position = explosionCenter
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Material = Enum.Material.Neon
	sphere.BrickColor = BrickColor.new("Bright orange")
	sphere.Transparency = 0
	sphere.Parent = workspace

	local tween = TweenService:Create(
		sphere,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(diameter, diameter, diameter),
			Transparency = 1,
		}
	)
	tween:Play()
	tween.Completed:Connect(function()
		sphere:Destroy()
	end)

	self:Die()
end

return SuicideBomber

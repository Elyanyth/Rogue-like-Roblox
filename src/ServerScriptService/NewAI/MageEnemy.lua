local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy")

local MageEnemy = setmetatable({}, { __index = Enemy })
MageEnemy.__index = MageEnemy

function MageEnemy.new(name: string, speed: number, health: number, damage: number, armor: number)
	local self = Enemy.new(name, speed, health, 0, armor)
	setmetatable(self, MageEnemy)

	self.LightningDamage = damage
	self.LightningRadius = 8
	self.LightningCooldown = 4
	self.LightningWarningTime = 1.5
	self.WanderInterval = 4
	self.LastLightningTime = 0
	self.LastWanderTime = 0

	return self
end

-- Returns a random position anywhere on the map baseplate
function MageEnemy:GetRandomMapPosition(): Vector3
	local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("Base")
	if baseplate then
		local size = baseplate.Size
		local pos = baseplate.Position
		return Vector3.new(
			pos.X + math.random(math.floor(-size.X / 2), math.floor(size.X / 2)),
			pos.Y + size.Y / 2 + 0.5,
			pos.Z + math.random(math.floor(-size.Z / 2), math.floor(size.Z / 2))
		)
	end
	-- Fallback if no baseplate found
	if self.Model and self.Model.PrimaryPart then
		local p = self.Model.PrimaryPart.Position
		return Vector3.new(p.X + math.random(-30, 30), p.Y, p.Z + math.random(-30, 30))
	end
	return Vector3.new(math.random(-50, 50), 3, math.random(-50, 50))
end

-- Picks a random nearby point and walks toward it
function MageEnemy:Wander()
	if not self.Model or not self.Model.PrimaryPart or not self.Humanoid then return end
	local pos = self.Model.PrimaryPart.Position
	local target = pos + Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
	self.Humanoid:MoveTo(target)
end

-- Override Chase: wander randomly + summon lightning periodically, never chase players
function MageEnemy:Chase()
	if not self.Model or not self.Humanoid then
		warn("MageEnemy: model not set!")
		return
	end

	if not self:IsAlive() then return end

	self:StopChasing()
	self.IsChasing = true

	self:Wander()

	self.ChaseConnection = RunService.Heartbeat:Connect(function()
		if not self.IsChasing or not self:IsAlive() or not self.Model or not self.Model.Parent then
			self:StopChasing()
			return
		end

		local now = tick()

		if now - self.LastWanderTime >= self.WanderInterval then
			self:Wander()
			self.LastWanderTime = now
		end

		if now - self.LastLightningTime >= self.LightningCooldown then
			self:SummonLightning()
			self.LastLightningTime = now
		end
	end)
end

function MageEnemy:SummonLightning()
	if not self.Model or not self.Model.Parent then return end
	local strikePos = self:GetRandomMapPosition()
	local radius = self.LightningRadius
	local warningTime = self.LightningWarningTime

	-- Warning circle on the ground: red so the danger zone is clearly readable
	local warning = Instance.new("Part")
	warning.Shape = Enum.PartType.Cylinder
	warning.Size = Vector3.new(0.1, radius * 2 , radius * 2)
	warning.Orientation = Vector3.new(0, 0, 90)
	warning.Position = strikePos
	warning.Anchored = true
	warning.CanCollide = false
	warning.Material = Enum.Material.Neon
	warning.Color = Color3.fromRGB(255, 30, 30)
	warning.Transparency = 0.15
	warning.Parent = workspace

	-- Pulse from opaque → transparent so it flickers urgently
	TweenService:Create(
		warning,
		TweenInfo.new(warningTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.7 }
	):Play()

	task.delay(warningTime, function()
		warning:Destroy()

		-- Abort if the mage was cleaned up during the warning window
		if not self.Model or not self.Model.Parent then return end

		-- Lightning bolt: tall thin block dropping from the sky
		local boltHeight = 60
		local bolt = Instance.new("Part")
		bolt.Size = Vector3.new(1.5, boltHeight, 1.5)
		bolt.CFrame = CFrame.new(strikePos + Vector3.new(0, boltHeight / 2, 0))
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.Material = Enum.Material.Neon
		bolt.BrickColor = BrickColor.new("Bright yellow")
		bolt.Transparency = 0
		bolt.Parent = workspace

		-- Impact flash disc at ground level
		local flash = Instance.new("Part")
		flash.Shape = Enum.PartType.Cylinder
		flash.Size = Vector3.new(0.1, radius, radius)
		flash.Orientation = Vector3.new(0, 0, 90)
		flash.Position = strikePos
		flash.Anchored = true
		flash.CanCollide = false
		flash.Material = Enum.Material.Neon
		flash.Color = Color3.fromRGB(255, 30, 30)
		flash.Transparency = 0
		flash.Parent = workspace

		-- Damage all players inside the radius
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 and rootPart then
					local dist = (rootPart.Position - strikePos).Magnitude
					if dist <= radius then
						if not humanoid:GetAttribute("IsInvincible") then
							humanoid:TakeDamage(self.LightningDamage)
							print("MageEnemy lightning struck " .. player.Name .. " for " .. self.LightningDamage .. " damage!")
						end
					end
				end
			end
		end

		-- Fade out both bolt and flash
		local Debris = game:GetService("Debris")
		TweenService:Create(
			bolt,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1 }
		):Play()
		TweenService:Create(
			flash,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(radius * 3, 0.5, radius * 3), Transparency = 1 }
		):Play()
		Debris:AddItem(bolt, 0.3)
		Debris:AddItem(flash, 0.3)
	end)
end

return MageEnemy

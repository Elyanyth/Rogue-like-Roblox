local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local ServerScriptService = game:GetService("ServerScriptService")
local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy")

local EggEnemy = setmetatable({}, { __index = Enemy })
EggEnemy.__index = EggEnemy

export type EggEnemyType = Enemy.EnemyType & {
	HatchTime: number,
	HasHatched: boolean,
	HatchStats: {
		Name: string,
		Speed: number,
		Health: number,
		Damage: number,
		Armor: number,
		ModelScale: number,
	}?,
}

function EggEnemy.new(name: string, speed: number, health: number, damage: number, armor: number): EggEnemyType
	local self = Enemy.new(name, speed, health, damage, armor)
	setmetatable(self, EggEnemy)

	self.HatchTime = 15
	self.HasHatched = false
	self.HatchStats = nil -- set by Spawner from EnemyDefinitions

	return self
end

-- Builds the egg model in code so no Studio model is required
function EggEnemy.CreateEggModel(health: number): Model
	local model = Instance.new("Model")
	model.Name = "Egg"

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Shape = Enum.PartType.Ball
	rootPart.Size = Vector3.new(3, 4, 3)
	rootPart.BrickColor = BrickColor.new("Pastel yellow")
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Anchored = true -- stays put so physics can't knock it around
	rootPart.CanCollide = true
	rootPart.Parent = model
	model.PrimaryPart = rootPart

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = health
	humanoid.Health = health
	humanoid.Parent = model

	return model
end

-- Egg does not chase — it stands still and waits to hatch
function EggEnemy:Chase()
	if not self.Model or not self.Humanoid then
		warn("EggEnemy: model not set!")
		return
	end

	if not self:IsAlive() then
		return
	end

	self:StopChasing()
	self.IsChasing = true

	-- Ensure the humanoid can't walk (in case something sets WalkSpeed later)
	self.Humanoid.WalkSpeed = 0

	task.delay(self.HatchTime, function()
		if self:IsAlive() and not self.HasHatched then
			self:Hatch()
		end
	end)
end

function EggEnemy:Hatch()
	if self.HasHatched then return end
	self.HasHatched = true

	if not self.Model or not self.Model.PrimaryPart then return end

	local spawnPosition = self.Model.PrimaryPart.Position

	-- Hatch flash effect
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(4, 4, 4)
	flash.Position = spawnPosition
	flash.Anchored = true
	flash.CanCollide = false
	flash.Material = Enum.Material.Neon
	flash.BrickColor = BrickColor.new("Bright yellow")
	flash.Transparency = 0
	flash.Parent = workspace

	local tween = TweenService:Create(
		flash,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(10, 10, 10), Transparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		flash:Destroy()
	end)

	local stats = self.HatchStats
	if not stats then
		warn("EggEnemy: HatchStats not set — cannot hatch!")
		self:Die()
		return
	end

	-- Clone the base Chase (Zombie) model and scale it
	local enemyModels = ServerStorage:FindFirstChild("EnemyModels")
	local chaseTemplate = enemyModels and enemyModels:FindFirstChild("Chase")

	if not chaseTemplate then
		warn("EggEnemy: ServerStorage.EnemyModels.Chase not found — cannot hatch!")
		self:Die()
		return
	end

	local empoweredModel = chaseTemplate:Clone()
	empoweredModel:ScaleTo(stats.ModelScale)
	empoweredModel.Parent = workspace
	empoweredModel:PivotTo(CFrame.new(spawnPosition))

	local empowered = Enemy.new(stats.Name, stats.Speed, stats.Health, stats.Damage, stats.Armor)
	empowered:SetModel(empoweredModel)
	empowered:Chase()

	print("Egg hatched! " .. stats.Name .. " has appeared!")

	self:Die()
end

return EggEnemy

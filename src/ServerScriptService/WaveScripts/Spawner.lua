local Spawner = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
-- local EnemyAI = ServerScriptService.EnemyAI

-- Imports
local Modules = require(ServerScriptService.ModuleLoader)
local Enemy = Modules.Get("BaseEnemy")
local RangedEnemy = Modules.Get("RangedEnemy")
local SummonerEnemy = Modules.Get("SummonerEnemy")
local SuicideBomber = Modules.Get("SuicideBomber")
local EggEnemy = Modules.Get("EggEnemy")
local MageEnemy = Modules.Get("MageEnemy")
local EnemyDefinitions = Modules.Get("EnemyTypes")
local DificultyManager = Modules.Get("DificultyManager")
local WaveModule = Modules.Get("WaveModule")

-- ===============================
-- CONFIGURATION
-- ===============================
local SPAWN_INTERVAL = 0.7
local MAX_ENEMIES = 20
local MIN_SPAWN_DISTANCE = 5  -- studs; enemies won't spawn closer than this to any player

-- ===============================
-- PRIVATE STATE
-- ===============================
local activeEnemies = {}
local spawnerRunning = false
local spawnerThread = nil

-- ===============================
-- PRIVATE FUNCTIONS
-- ===============================

local function isTooCloseToPlayers(pos: Vector3): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - pos).Magnitude < MIN_SPAWN_DISTANCE then
			return true
		end
	end
	return false
end

local function getRandomSpawnPosition()
	local baseplate = workspace:FindFirstChild("Baseplate") or workspace:FindFirstChild("Base")

	if not baseplate then
		warn("Baseplate not found in workspace!")
		return Vector3.new(0, 5, 0)
	end

	local size = baseplate.Size
	local position = baseplate.Position
	local spawnY = position.Y + (size.Y / 2) + 3

	-- Retry up to 10 times to find a position far enough from all players.
	-- If every attempt fails (very unlikely on a large map), use the last candidate.
	local candidate
	for _ = 1, 10 do
		candidate = Vector3.new(
			position.X + math.random(-size.X / 2, size.X / 2),
			spawnY,
			position.Z + math.random(-size.Z / 2, size.Z / 2)
		)
		if not isTooCloseToPlayers(candidate) then
			break
		end
	end

	return candidate
end

local function spawnEnemy(enemyData)
	local enemy

	if enemyData.Type == "Melee" then
		enemy = Enemy.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor, enemyData.AttackCooldown)
	elseif enemyData.Type == "Ranged" then
		enemy = RangedEnemy.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor, enemyData.AttackCooldown)
		enemy.PreferredDistance = enemyData.PreferredDistance or 20
		enemy.AttackRange = enemyData.AttackRange or 30
	elseif enemyData.Type == "Summoner" then
		enemy = SummonerEnemy.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor)
		enemy.MaxSummons = enemyData.MaxSummons or 5
		enemy.SummonCooldown = enemyData.SummonCooldown or 3
		enemy.SummonTemplate = enemyData.SummonTemplate
		enemy.SummonClass = Enemy
		enemy.SummonStats = enemyData.SummonStats
		enemy.PreferredDistance = enemyData.PreferredDistance or 20
		enemy.AttackRange = enemyData.AttackRange or 25
		enemy.AttackCooldown = enemyData.AttackCooldown or 2
		enemy.ProjectileSpeed = enemyData.ProjectileSpeed or 20
	elseif enemyData.Type == "Bomber" then
		enemy = SuicideBomber.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor)
	elseif enemyData.Type == "Mage" then
		enemy = MageEnemy.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor)
	elseif enemyData.Type == "Egg" then
		enemy = EggEnemy.new(enemyData.Name, enemyData.Speed, enemyData.Health, enemyData.Damage, enemyData.Armor)
		enemy.HatchStats = enemyData.HatchStats
		local eggModel = EggEnemy.CreateEggModel(enemyData.Health)
		eggModel.Parent = workspace
		enemy:SetModel(eggModel)
		eggModel:SetPrimaryPartCFrame(CFrame.new(getRandomSpawnPosition()))
	end

	if enemyData.Model then
		local modelClone = enemyData.Model:Clone()
		modelClone.Parent = workspace
		enemy:SetModel(modelClone)

		if enemy.Model and enemy.Model.PrimaryPart then
			enemy.Model:SetPrimaryPartCFrame(CFrame.new(getRandomSpawnPosition()))
		elseif enemy.Model and enemy.Model:FindFirstChild("HumanoidRootPart") then
			enemy.Model.HumanoidRootPart.CFrame = CFrame.new(getRandomSpawnPosition())
		end
	end

	enemy:Chase()

	return enemy
end

local function cleanupDeadEnemies()
	for i = #activeEnemies, 1, -1 do
		local enemy = activeEnemies[i]
		if not enemy.Model or not enemy.Model.Parent or enemy.Health <= 0 then
			table.remove(activeEnemies, i)
		end
	end
end

-- ===============================
-- PUBLIC API
-- ===============================

function Spawner.Start()
	if spawnerRunning then return end
	spawnerRunning = true

	spawnerThread = task.spawn(function()
		while spawnerRunning do
			task.wait(SPAWN_INTERVAL)

			if not spawnerRunning then break end -- Add this check

			cleanupDeadEnemies()

			if #activeEnemies < MAX_ENEMIES then
				local enemyData = EnemyDefinitions.GetWeightedRandom(WaveModule.Get())
				-- local scaledEnemyData = DificultyManager.DifficultySetting(enemyData) -- NEED TO IMPLEMENT WAY TO CHANGE DIFF -- INEFICIENT AND SHOULD BE REWORKED FOR EFFICIENCY IF NEEDED
				local waveScaledEnemyData = DificultyManager.WaveScalling(enemyData) -- INEFICIENT AND SHOULD BE REWORKED FOR EFFICIENCY IF NEEDED
				local newEnemy = spawnEnemy(waveScaledEnemyData)
				table.insert(activeEnemies, newEnemy)
				print("Spawned:", enemyData.Name, "| Active enemies:", #activeEnemies)
			else
				print("Max enemies reached:", MAX_ENEMIES)
			end
		end
	end)
end

function Spawner.Stop()
	spawnerRunning = false
	spawnerThread = nil
	print("Spawner stopped")

	cleanupDeadEnemies()

end

function Spawner.Toggle()
	if spawnerRunning then
		Spawner.Stop()
	else
		Spawner.Start()
		print("Spawner started")
	end
end

function Spawner.IsRunning()
	return spawnerRunning
end

function Spawner.GetActiveEnemyCount()
	return #activeEnemies
end

return Spawner
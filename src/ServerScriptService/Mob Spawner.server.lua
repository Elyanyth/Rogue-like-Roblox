local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local players = game:GetService("Players")

local Spawner = workspace.Baseplate -- The part to spawn entities on
local template = ServerStorage.Enemies.Dummy -- Your entity model to clone
local spawnInterval = 1 -- seconds between each pack spawn
local minPackSize = 3 -- smallest group size
local maxPackSize = 6 -- largest group size
local maxCount = 75
local EnemyCount = 0

-- Get size and position for random placement
local size = Spawner.Size
local topY = Spawner.Position.Y + (size.Y / 2)

-- wait for players to connect.
while #players:GetChildren() < 1 do
	task.wait(0.1)
end

local function randomPosition()

	local offsetX = math.random(-size.X/2, size.X/2)
	local offsetZ = math.random(-size.Z/2, size.Z/2)

	return offsetX, offsetZ
end



-- Modules
local enemyTypes = require(ServerScriptService.EnemieAI:FindFirstChild("enemyTypes"))
local BaseAi = require(ServerScriptService.EnemieAI:WaitForChild("BaseAi"))
local genericFunctions = require(ServerScriptService.GenericFunctions)


while true do

	EnemyCount = #CollectionService:GetTagged("Enemy")

	while EnemyCount >= maxCount do
		task.wait(0.1) -- wait a short time before checking again
		EnemyCount = #CollectionService:GetTagged("Enemy")
	end
	-- Random number of mobs in this pack
	local enemyType = enemyTypes.getWeightedRandomType()
	local packSize = math.random(enemyType.minPackSize, enemyType.maxPackSize)

	local offsetX, offsetZ = randomPosition()

	for i = 1, packSize do
		local validSpawn = false
		local attempts = 0
		local maxAttempts = 10 -- prevent infinite loop

		repeat
			attempts = attempts + 1

			-- Random offsets from center of part
			if enemyType.spawnType == "Spread" then
				offsetX, offsetZ = randomPosition()
			end

			-- Create new entity
			local entity = enemyType.model:Clone()
			entity.PrimaryPart = entity:FindFirstChild("Head")
			local enemyScript = ServerScriptService.EnemieAI.EnemyScript:Clone()
			enemyScript.Parent = entity
			local newCFrame = CFrame.new(
				Spawner.Position.X + offsetX + math.random(-5,5),
				topY + (entity.PrimaryPart.Size.Y / 2) + 2,
				Spawner.Position.Z + offsetZ + math.random(-5,5)
			)
			entity:PivotTo(newCFrame)

			local closestPlayer, distance = genericFunctions.getClosestPlayer(entity)

			if distance > 15 then
				entity.Parent = workspace.Enemies
				BaseAi.Active(entity, enemyType)
				validSpawn = true
			else
				print("Enemy spawned to close trying again.")
				entity:Destroy() -- clean up failed spawn
			end

		until validSpawn or attempts >= maxAttempts

		if not validSpawn then
			warn("Could not find valid spawn position after", maxAttempts, "attempts")
		end

		task.wait(0.1)
	end

	task.wait(spawnInterval)
end

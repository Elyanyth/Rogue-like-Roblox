local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

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

-- Modules
local enemyTypes = require(ServerScriptService.EnemieAI:FindFirstChild("enemyTypes"))

while true do
	
	EnemyCount = #CollectionService:GetTagged("Enemy")
	
	while EnemyCount >= maxCount do
		task.wait(0.1) -- wait a short time before checking again
		EnemyCount = #CollectionService:GetTagged("Enemy")

	end
	-- Random number of mobs in this pack
	local packSize = math.random(minPackSize, maxPackSize)
	local type = enemyTypes.getWeightedRandomType()
	
	for i = 1, packSize do
		-- Random offsets from center of part
		local offsetX = math.random(-size.X/2, size.X/2)
		local offsetZ = math.random(-size.Z/2, size.Z/2)

		local enemyScript = ServerScriptService.EnemieAI.EnemyAi:Clone()

		-- Create new entity
		local entity = enemyTypes[type].model:Clone()
		enemyScript.Parent = entity
		entity.Parent = workspace.Enemies
		local newCFrame = CFrame.new(
			Spawner.Position.X + offsetX,
			topY + (entity.PrimaryPart.Size.Y / 2) + 2,
			Spawner.Position.Z + offsetZ
		)
		entity:PivotTo(newCFrame)

		task.wait(0.1)
		
	end

	task.wait(spawnInterval)
end

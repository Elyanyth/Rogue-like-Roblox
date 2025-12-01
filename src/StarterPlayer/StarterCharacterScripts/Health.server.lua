-- Gradually regenerates the Humanoid's Health over time.

-- Module
local plrStatModule = require(game:GetService("ServerScriptService").plrDataModule)
local plrStats = plrStatModule.fetchPlrStats(game.Players:GetPlayerFromCharacter(script.Parent))

local REGEN_RATE = plrStats.healthRegen.Value -- Regenerate this fraction of MaxHealth per second.
local REGEN_STEP = 1 -- Wait this long between each regeneration step.

--------------------------------------------------------------------------------

local Character = script.Parent
local Humanoid = Character:WaitForChild'Humanoid'

--------------------------------------------------------------------------------

while true do
	while Humanoid.Health < Humanoid.MaxHealth do
		local dt = wait(REGEN_STEP)
		local dh = dt*REGEN_RATE
		Humanoid.Health = math.min(Humanoid.Health + dh, Humanoid.MaxHealth)
	end
	Humanoid.HealthChanged:Wait()
end
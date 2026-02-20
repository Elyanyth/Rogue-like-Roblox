local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DASH_KEY = Enum.KeyCode.LeftShift
local DASH_SPEED = 45       -- studs/second impulse during dash
local DASH_DURATION = 0.2   -- seconds the dash lasts
local DASH_COOLDOWN = 3     -- seconds before next dash

local player = Players.LocalPlayer
local DashEvent = ReplicatedStorage:WaitForChild("DashEvent")

local canDash = true

-- Returns the direction to dash: move direction if moving, otherwise camera forward
local function getDashDirection(hrp, humanoid)
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude > 0.1 then
		return moveDir
	end
	-- Flatten the HRP look vector so the dash stays horizontal
	local look = hrp.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0.001 then
		return flat.Unit
	end
	return hrp.CFrame.LookVector
end

local function performDash(character)
	if not canDash then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	if humanoid.Health <= 0 then return end

	canDash = false

	local dashDir = getDashDirection(hrp, humanoid)

	-- Tell the server to grant I-frames
	DashEvent:FireServer(true)

	-- Apply the dash impulse via BodyVelocity
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = dashDir * DASH_SPEED
	bv.MaxForce = Vector3.new(1e5, 0, 1e5) -- horizontal only, gravity still applies
	bv.P = 1e5
	bv.Parent = hrp

	-- Make character semi-transparent to signal I-frame window
	local savedTransparency = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			savedTransparency[part] = part.Transparency
			part.Transparency = 0.65
		end
	end

	task.delay(DASH_DURATION, function()
		-- End movement impulse
		bv:Destroy()

		-- Tell the server to remove I-frames
		DashEvent:FireServer(false)

		-- Restore original transparencies
		for part, t in pairs(savedTransparency) do
			if part and part.Parent then
				part.Transparency = t
			end
		end
	end)

	-- Reset cooldown
	task.delay(DASH_COOLDOWN, function()
		canDash = true
	end)
end

-- Wire up input; re-grab character on respawn
local function setupCharacter(character)
	canDash = true
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= DASH_KEY then return end

	local character = player.Character
	if character then
		performDash(character)
	end
end)

player.CharacterAdded:Connect(setupCharacter)

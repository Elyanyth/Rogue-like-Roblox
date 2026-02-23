local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DamageIndicator = {}

-- Duration the number stays on screen before fully fading
local RISE_TIME = 0.9
local RISE_HEIGHT = 4
local FADE_DELAY = 0.35 -- seconds after spawn before fade begins
local FADE_TIME = 0.55

-- color defaults to white (enemy damage); pass a Color3 to override (e.g. red for player damage)
function DamageIndicator.Show(position: Vector3, damage: number, color: Color3?)
	local rounded = math.round(damage)
	if rounded <= 0 then return end

	-- Small random horizontal offset so rapid hits don't stack identically
	local ox = (math.random() - 0.5) * 2.5
	local oz = (math.random() - 0.5) * 2.5

	-- Invisible anchor Part that rises upward
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CastShadow = false
	part.Position = position + Vector3.new(ox, 2.5, oz)
	part.Parent = workspace

	-- BillboardGui so the text always faces the camera
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(5, 0, 1.8, 0)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(rounded)
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextTransparency = 0
	label.Parent = billboard

	-- Float upward
	TweenService:Create(
		part,
		TweenInfo.new(RISE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = part.Position + Vector3.new(0, RISE_HEIGHT, 0) }
	):Play()

	-- Fade text out after a short delay
	task.delay(FADE_DELAY, function()
		if label and label.Parent then
			TweenService:Create(
				label,
				TweenInfo.new(FADE_TIME, Enum.EasingStyle.Linear),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			):Play()
		end
	end)

	Debris:AddItem(part, RISE_TIME)
end

return DamageIndicator

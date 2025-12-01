local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Prevent zooming/first-person
player.CameraMinZoomDistance = 20
player.CameraMaxZoomDistance = 20

-- Script-controlled camera
camera.CameraType = Enum.CameraType.Scriptable

-- Camera settings
local distance = 40   -- Distance from player
local angleDeg = 60   -- Tilt angle from horizontal plane (80° ≈ almost top-down)

-- Convert angle to radians for math functions
local angleRad = math.rad(angleDeg)

RunService.RenderStepped:Connect(function()
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local root = player.Character.HumanoidRootPart

		-- Offset calculation: X/Z distance from the player based on angle
		local yOffset = math.sin(angleRad) * distance
		local flatDistance = math.cos(angleRad) * distance
		local Mouse = player:GetMouse()

		-- Here I put the camera behind the player along -Z axis
		local cameraPos = root.Position + Vector3.new(0, yOffset, flatDistance)

		camera.CFrame = CFrame.new(cameraPos, root.Position)
		root.CFrame = CFrame.new(root.Position, Vector3.new(Mouse.Hit.Position.X, root.Position.Y, Mouse.Hit.Position.Z))
	end
end)


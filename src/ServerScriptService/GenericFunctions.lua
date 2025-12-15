local genericFunctions = {}

-- Services 
local players = game:GetService("Players")

function genericFunctions.getClosestPlayer(enemy)
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then
        return nil, math.huge
    end

    local closestPlayer = nil
    local closestDist = math.huge

    for _, player in ipairs(players:GetPlayers()) do
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")

            -- skip dead or invalid characters
            if humanoid and humanoid.Health > 0 and root then
                local dist = (root.Position - enemyRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer, closestDist
end



return genericFunctions
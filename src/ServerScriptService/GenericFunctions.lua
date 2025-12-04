local genericFunctions = {}

-- Services 
local players = game:GetService("Players")

function genericFunctions.getClosestPlayer(enemy)
    
    local rootPart = enemy:FindFirstChild("HumanoidRootPart")

    local closestPlayer = nil
        local closestDist = math.huge
    
        for _, player in ipairs(players:GetPlayers()) do
            local Character = player.Character
            if Character and rootPart  then
                local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
        return closestPlayer, closestDist

end



return genericFunctions
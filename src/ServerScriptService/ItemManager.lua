-- ServerScriptService/ItemManager.lua
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemsFolder = ServerStorage.ItemModules

local Modules = require(ServerScriptService.ModuleLoader)
local PlayerData = Modules.Get("PlayerData")

local ItemManager = {}

function ItemManager:GetSpellModifiers(player, spellName)
    local modifiers = {}

    for _, module in ipairs(ItemsFolder:GetChildren()) do
        local item = require(module)
        local stacks = PlayerData.GetItem(player, item.Name)

        if stacks > 0 and item.Modifiers and item.Modifiers[spellName] then
            table.insert(modifiers, {
                data = item.Modifiers[spellName],
                stacks = stacks
            })
        end
    end

    return modifiers
end


return ItemManager

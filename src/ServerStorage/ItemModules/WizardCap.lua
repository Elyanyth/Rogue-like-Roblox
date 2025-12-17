-- ServerStorage/ItemModules/WizardCap.lua
local WizardCap = {}

WizardCap.Name = "Wizard Cap"

WizardCap.Modifiers = {
    Fireball = {
        SizeMultiplier = function(stacks)
            return 1 + (stacks * 0.1)
        end
    }
}

return WizardCap

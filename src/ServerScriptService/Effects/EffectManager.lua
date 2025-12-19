local EffectManager = {}

-- Active effects per target
-- [Instance] = {
--     [EffectName] = effectObject
-- }
EffectManager.ActiveEffects = {}

-- Apply or refresh an effect
function EffectManager:ApplyEffect(effect)
    local target = effect.Target
    if not target then return end

    self.ActiveEffects[target] = self.ActiveEffects[target] or {}

    local active = self.ActiveEffects[target][effect.Name]

    -- Refresh existing effect
    if active then
        if active.OnRefresh then
            active:OnRefresh(effect)
        end
        return
    end

    -- Apply new effect
    self.ActiveEffects[target][effect.Name] = effect
    effect:OnApply()

    -- Auto-remove after duration
    task.delay(effect.Duration, function()
        self:RemoveEffect(target, effect.Name)
    end)
end

-- Remove an effect manually or after duration
function EffectManager:RemoveEffect(target, effectName)
    local targetEffects = self.ActiveEffects[target]
    if not targetEffects then return end

    local effect = targetEffects[effectName]
    if not effect then return end

    if effect.OnRemove then
        effect:OnRemove()
    end

    targetEffects[effectName] = nil

    -- Cleanup table
    if next(targetEffects) == nil then
        self.ActiveEffects[target] = nil
    end
end

-- Remove all effects (death, cleanse, etc.)
function EffectManager:ClearEffects(target)
    local targetEffects = self.ActiveEffects[target]
    if not targetEffects then return end

    for name, _ in pairs(targetEffects) do
        self:RemoveEffect(target, name)
    end
end

-- Utility
function EffectManager:HasEffect(target, effectName)
    return self.ActiveEffects[target] and self.ActiveEffects[target][effectName] ~= nil
end

return EffectManager

local SlownessEffect = {}
SlownessEffect.__index = SlownessEffect

function SlownessEffect.new(config)
    local self = setmetatable({}, SlownessEffect)

    self.Name = "Slowness"
    self.Magnitude = config.Magnitude or 0.5
    self.Duration = config.Duration or 5
    self.Target = config.Target

    self._originalSpeed = nil

    return self
end

function SlownessEffect:OnApply()
    if not self.Target or not self.Target:IsA("Humanoid") then return end

    self._originalSpeed = self.Target.WalkSpeed
    self.Target.WalkSpeed *= (1 - self.Magnitude)
end

function SlownessEffect:OnRemove()
    if self.Target and self.Target.Parent then
        self.Target.WalkSpeed = self._originalSpeed
    end
end

function SlownessEffect:OnRefresh(newEffect)
    -- Optional: stronger slow wins
    self.Magnitude = math.max(self.Magnitude, newEffect.Magnitude)
end

return SlownessEffect

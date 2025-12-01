local DamageCalcModule = {}

function DamageCalcModule.CalculateDamage(baseDamage, stats)
	local critRate = stats.critRate
	local critDamage = stats.critDamage
	local strength = stats.strength
	
	local damage = baseDamage + stats.strength
	
	math.randomseed(tick())
	local isCritical = math.random(1, 100) < critRate
	
	if isCritical then
		damage = damage * (critDamage/100)
	end
	
	return damage
end


return DamageCalcModule

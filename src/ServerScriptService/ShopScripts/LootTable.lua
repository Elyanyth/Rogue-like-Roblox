local lootTable = {}

lootTable.COMBAT_STATS = {
	{ id = "health",      weight = 200, type = "stat", min = 5,  max = 10 },
	{ id = "strength",    weight = 200, type = "stat", min = 3,  max = 5  },
	{ id = "armor",       weight = 200, type = "stat", min = 1,  max = 5  },
	{ id = "critRate",    weight = 200, type = "stat", min = 5,  max = 15 },
	{ id = "critDamage",  weight = 200, type = "stat", min = 5,  max = 15 },
}

lootTable.UTILITY_STATS = {
	{ id = "speed",              weight = 200, type = "stat", min = 1,  max = 3  },
	{ id = "healthRegen",        weight = 200, type = "stat", min = 1,  max = 2  },
	{ id = "cooldownReduction",  weight = 200, type = "stat", min = 10, max = 25 },
	{ id = "Income",             weight = 200, type = "stat", min = 10, max = 20 },
}

lootTable.SPELLS = {
	{ id = "Fireball", weight = 50, type = "spell", min = 1, max = 1, description = "Shoots a fireball in a straight line when activated." },
	{ id = "IceBlast", weight = 50, type = "spell", min = 1, max = 1, description = "Creates a field of ice damaging enemys inside." },
	{ id = "IceSpear", weight = 50, type = "spell", min = 1, max = 1, description = "Fires an IceSpear that damages and slows enemys." },
	{ id = "Whirlpool", weight = 50, type = "spell", min = 1, max = 1, description = "Creates a whirlpool at the players cursor pulling in enemies" },
	{ id = "ConcussiveBlow", weight = 50, type = "spell", min = 1, max = 1, description = "Hits and stuns enemies in front of the player" },


}

lootTable.ITEMS = {
	{id = "Wizard Cap", weight = 150, type = "item", min = 1, max = 1, description = "Increases Firball size by 10%"},
}

-- Helper to merge all or specific tables
function lootTable.getMergedLoot(...)
	local tablesToMerge = {...}
	if #tablesToMerge == 0 then
		-- Default: merge all
		tablesToMerge = {lootTable.COMBAT_STATS, lootTable.UTILITY_STATS, lootTable.SPELLS, lootTable.ITEMS}
	end
	
	local result = {}
	for _, tbl in ipairs(tablesToMerge) do
		for _, item in ipairs(tbl) do
			table.insert(result, item)
		end
	end
	return result
end

-- Pre-merged table for convenience
lootTable.ALL_LOOT = lootTable.getMergedLoot()

return lootTable
local lootTable = {}

lootTable.COMBAT_STATS = {
	{ id = "health",      weight = 100, type = "stat", min = 5,  max = 10 },
	{ id = "strength",    weight = 100, type = "stat", min = 3,  max = 5  },
	{ id = "armor",       weight = 100, type = "stat", min = 1,  max = 5  },
	{ id = "critRate",    weight = 100, type = "stat", min = 5,  max = 15 },
	{ id = "critDamage",  weight = 100, type = "stat", min = 5,  max = 15 },
}

lootTable.UTILITY_STATS = {
	{ id = "speed",              weight = 100, type = "stat", min = 1,  max = 3  },
	{ id = "healthRegen",        weight = 100, type = "stat", min = 1,  max = 2  },
	{ id = "cooldownReduction",  weight = 100, type = "stat", min = 10, max = 25 },
	{ id = "Income",             weight = 100, type = "stat", min = 10, max = 20 },
}

lootTable.SPELLS = {
	{ id = "Fireball", weight = 100, type = "spell", min = 1, max = 1, description = "Shoots a fireball in a straight line when activated." },
}

lootTable.ITEMS = {
	{id = "Wizard Cap", weight = 100, type = "item", min = 1, max = 1, description = "Increases Firball size by 10%"},
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
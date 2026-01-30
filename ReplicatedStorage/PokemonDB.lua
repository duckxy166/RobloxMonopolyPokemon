--[[
================================================================================
                      💾 POKEMON DATABASE - Central Pokemon Data
================================================================================
]]

local PokemonDB = {}

-- Rarity -> Catch Difficulty (ความยากในการจับ)
PokemonDB.RarityDifficulty = {
	["None"] = 2,    -- จับง่ายสุด
	["Common"] = 3,
	["Uncommon"] = 4,
	["Rare"] = 5,
	["Legend"] = 6
}

-- Tile Encounter Rates (โอกาสเกิดตามสีช่อง)
-- *None ในที่นี้คือโอกาสเจอโปเกม่อนระดับ None (Rattata/Pidgey)
PokemonDB.EncounterRates = {
	["Bright green"] = { None = 60, Common = 40, Uncommon = 0, Rare = 0, Legend = 0 },
	["Forest green"] = { None = 10, Common = 60, Uncommon = 20, Rare = 0, Legend = 0 },
	["Dark green"]   = { None = 0,  Common = 30, Uncommon = 60, Rare = 10, Legend = 0 },
	["Earth green"]  = { None = 0,  Common = 10, Uncommon = 50, Rare = 40, Legend = 0 },
	["Gold"]         = { None = 0,  Common = 0,  Uncommon = 0,  Rare = 0,  Legend = 100 },
	-- Default fallback
	["Default"]      = { None = 100, Common = 0, Uncommon = 0, Rare = 0, Legend = 0 }
}

-- Pokemon Data
PokemonDB.Pokemon = {
	-- ===== NONE POOL (ระดับเกลือ) =====
	["Pidgey"] = { 
		Id = 16, Rarity = "None", Attack = 45, HP = 40, Type = "Normal",
		Model = "Pidgey", Icon = "rbxassetid://0", Image = "rbxassetid://0" 
	},
	["Rattata"] = { 
		Id = 19, Rarity = "None", Attack = 56, HP = 30, Type = "Normal",
		Model = "Rattata", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== COMMON POOL =====
	["Bulbasaur"] = {
		Id = 1, Rarity = "Common", Attack = 49, HP = 45, Type = "Grass",
		Model = "Bulbasaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650"
	},

	-- ===== UNCOMMON POOL =====
	["Ivysaur"] = {
		Id = 2, Rarity = "Uncommon", Attack = 62, HP = 60, Type = "Grass",
		Model = "Ivysaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650"
	},

	-- ===== RARE POOL =====
	["Venusaur"] = {
		Id = 3, Rarity = "Rare", Attack = 82, HP = 80, Type = "Grass",
		Model = "Venusaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650"
	},

	-- ===== LEGENDARY POOL =====
	["Mewtwo"] = {
		Id = 150, Rarity = "Legend", Attack = 110, HP = 106, Type = "Psychic",
		Model = "Mewtwo", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	}
}

-- Helper: Get Pokemon by Rarity
function PokemonDB.GetByRarity(rarity)
	local list = {}
	for name, data in pairs(PokemonDB.Pokemon) do
		if data.Rarity == rarity then
			table.insert(list, {Name = name, Data = data})
		end
	end
	return list
end

-- Core Function: สุ่ม Encounter ตามสีช่อง
function PokemonDB.GetEncounterFromTile(tileColorName)
	local rates = PokemonDB.EncounterRates[tileColorName] or PokemonDB.EncounterRates["Default"]

	-- 1. Roll for Rarity
	local roll = math.random(1, 100)
	local cumulative = 0
	local selectedRarity = "None"

	-- เรียงลำดับโอกาส
	local order = {"None", "Common", "Uncommon", "Rare", "Legend"}
	for _, rarity in ipairs(order) do
		local chance = rates[rarity] or 0
		cumulative = cumulative + chance
		if roll <= cumulative then
			selectedRarity = rarity
			break
		end
	end

	-- 2. Pick Pokemon from Pool (รวมถึง None ด้วย)
	local pool = PokemonDB.GetByRarity(selectedRarity)

	-- ถ้าไม่มีใน Pool (เช่นตั้งค่าผิด) ให้ลองถอยไปหา Common หรือ None
	if #pool == 0 then
		warn("⚠️ No pokemon found for rarity: " .. selectedRarity .. ". Trying fallback.")
		pool = PokemonDB.GetByRarity("None")
	end

	if #pool > 0 then
		local picked = pool[math.random(1, #pool)]
		return picked -- ส่งข้อมูลกลับไปเพื่อเริ่ม Battle/Encounter
	end

	return nil -- กรณี Database ว่างเปล่าจริงๆ
end

-- (คงฟังก์ชันเดิมไว้)
function PokemonDB.GetPokemon(name) return PokemonDB.Pokemon[name] end
function PokemonDB.GetCatchDifficulty(name) 
	local p = PokemonDB.Pokemon[name]
	return p and PokemonDB.RarityDifficulty[p.Rarity] or 2
end
function PokemonDB.GetRandomEncounter() 
	local all = {}
	for n, d in pairs(PokemonDB.Pokemon) do table.insert(all, {Name=n, Data=d}) end
	return all[math.random(1, #all)]
end

return PokemonDB
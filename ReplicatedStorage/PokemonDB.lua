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
	-- ===== NONE POOL (Creeps) =====
	["Caterpie"] = { 
		Id = 10, Rarity = "None", Attack = 4, HP = 5, Type = "Bug",
		Model = "010 - Caterpie", EvolveTo = "Metapod", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Pidgey"] = { 
		Id = 16, Rarity = "None", Attack = 5, HP = 5, Type = "Normal",
		Model = "016 - Pidgey", EvolveTo = "Pidgeotto", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Rattata"] = { 
		Id = 19, Rarity = "None", Attack = 6, HP = 5, Type = "Normal",
		Model = "019 - Rattata", EvolveTo = "Raticate", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Magikarp"] = { 
		Id = 129, Rarity = "None", Attack = 1, HP = 5, Type = "Water",
		Model = "129 - Magikarp", EvolveTo = "Gyarados", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== COMMON POOL (Base Forms) =====
	["Charmander"] = {
		Id = 4, Rarity = "Common", Attack = 10, HP = 10, Type = "Fire",
		Model = "004 - Charmander", EvolveTo = "Charmeleon", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Squirtle"] = {
		Id = 7, Rarity = "Common", Attack = 9, HP = 11, Type = "Water",
		Model = "007 - Squirtle", EvolveTo = "Wartortle", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Pikachu"] = {
		Id = 25, Rarity = "Common", Attack = 12, HP = 8, Type = "Electric",
		Model = "025 - Pikachu", EvolveTo = "Raichu", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Meowth"] = {
		Id = 52, Rarity = "Common", Attack = 8, HP = 8, Type = "Normal",
		Model = "052 - Meowth", EvolveTo = "Persian", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Gastly"] = {
		Id = 92, Rarity = "Common", Attack = 12, HP = 6, Type = "Ghost",
		Model = "092 - Gastly", EvolveTo = "Haunter", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Dratini"] = {
		Id = 147, Rarity = "Common", Attack = 10, HP = 10, Type = "Dragon",
		Model = "147 - Dratini", EvolveTo = "Dragonair", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Chikorita"] = {
		Id = 152, Rarity = "Common", Attack = 8, HP = 10, Type = "Grass",
		Model = "152 - Chikorita", EvolveTo = "Bayleef", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Cyndaquil"] = {
		Id = 155, Rarity = "Common", Attack = 10, HP = 8, Type = "Fire",
		Model = "155 - Cyndaquil", EvolveTo = "Quilava", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Totodile"] = {
		Id = 158, Rarity = "Common", Attack = 10, HP = 10, Type = "Water",
		Model = "158 - Totodile", EvolveTo = "Croconaw", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== UNCOMMON POOL (Stage 1) =====
	["Metapod"] = {
		Id = 11, Rarity = "Uncommon", Attack = 6, HP = 10, Type = "Bug",
		Model = "011 - Metapod", EvolveTo = "Butterfree", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Pidgeotto"] = {
		Id = 17, Rarity = "Uncommon", Attack = 12, HP = 12, Type = "Normal",
		Model = "017 - Pidgeotto", EvolveTo = "Pidgeot", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Raticate"] = {
		Id = 20, Rarity = "Uncommon", Attack = 14, HP = 10, Type = "Normal",
		Model = "020 - Raticate", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Charmeleon"] = {
		Id = 5, Rarity = "Uncommon", Attack = 16, HP = 14, Type = "Fire",
		Model = "005 - Charmeleon", EvolveTo = "Charizard", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Wartortle"] = {
		Id = 8, Rarity = "Uncommon", Attack = 14, HP = 16, Type = "Water",
		Model = "008 - Wartortle", EvolveTo = "Blastoise", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Persian"] = {
		Id = 53, Rarity = "Uncommon", Attack = 14, HP = 12, Type = "Normal",
		Model = "053 - Persian", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Haunter"] = {
		Id = 93, Rarity = "Uncommon", Attack = 18, HP = 10, Type = "Ghost",
		Model = "093 - Haunter", EvolveTo = "Gengar", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Dragonair"] = {
		Id = 148, Rarity = "Uncommon", Attack = 16, HP = 16, Type = "Dragon",
		Model = "148 - Dragonair", EvolveTo = "Dragonite", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Bayleef"] = {
		Id = 153, Rarity = "Uncommon", Attack = 14, HP = 16, Type = "Grass",
		Model = "153 - Bayleef", EvolveTo = "Meganium", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Quilava"] = {
		Id = 156, Rarity = "Uncommon", Attack = 16, HP = 14, Type = "Fire",
		Model = "156 - Quilava", EvolveTo = "Typhlosion", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Croconaw"] = {
		Id = 159, Rarity = "Uncommon", Attack = 16, HP = 16, Type = "Water",
		Model = "159 - Croconaw", EvolveTo = "Feraligatr", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== RARE POOL (Stage 2 / Single Strong) =====
	["Venusaur"] = {
		Id = 3, Rarity = "Rare", Attack = 22, HP = 24, Type = "Grass",
		Model = "003 - Venusaur", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Charizard"] = {
		Id = 6, Rarity = "Rare", Attack = 25, HP = 20, Type = "Fire",
		Model = "006 - Charizard", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Blastoise"] = {
		Id = 9, Rarity = "Rare", Attack = 22, HP = 25, Type = "Water",
		Model = "009 - Blastoise", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Butterfree"] = {
		Id = 12, Rarity = "Rare", Attack = 15, HP = 15, Type = "Bug",
		Model = "012 - Butterfree", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Pidgeot"] = {
		Id = 18, Rarity = "Rare", Attack = 18, HP = 18, Type = "Normal",
		Model = "018 - Pidgeot", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Raichu"] = {
		Id = 26, Rarity = "Rare", Attack = 20, HP = 18, Type = "Electric",
		Model = "026 - Raichu", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Gengar"] = {
		Id = 94, Rarity = "Rare", Attack = 25, HP = 16, Type = "Ghost",
		Model = "094 - Gengar", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Gyarados"] = {
		Id = 130, Rarity = "Rare", Attack = 25, HP = 22, Type = "Water",
		Model = "130 - Gyarados", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Lapras"] = {
		Id = 131, Rarity = "Rare", Attack = 20, HP = 28, Type = "Water",
		Model = "131 - Lapras", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Dragonite"] = {
		Id = 149, Rarity = "Rare", Attack = 28, HP = 25, Type = "Dragon",
		Model = "149 - Dragonite", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Meganium"] = {
		Id = 154, Rarity = "Rare", Attack = 22, HP = 26, Type = "Grass",
		Model = "154 - Meganium", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Typhlosion"] = {
		Id = 157, Rarity = "Rare", Attack = 25, HP = 22, Type = "Fire",
		Model = "157 - Typhlosion", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
	["Feraligatr"] = {
		Id = 160, Rarity = "Rare", Attack = 24, HP= 24, Type = "Water",
		Model = "160 - Feraligatr", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== LEGENDARY POOL =====
	["Mewtwo"] = {
		Id = 150, Rarity = "Legend", Attack = 35, HP = 30, Type = "Psychic",
		Model = "150 - Mewtwo", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},
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

-- New Helper: Get Random Single Pokemon by Rarity
function PokemonDB.GetRandomByRarity(rarity)
	local pool = PokemonDB.GetByRarity(rarity)
	if #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

-- (คงฟังก์ชันเดิมไว้)
function PokemonDB.GetPokemon(name) return PokemonDB.Pokemon[name] end
function PokemonDB.GetCatchDifficulty(name) 
	local p = PokemonDB.Pokemon[name]
	return p and PokemonDB.RarityDifficulty[p.Rarity] or 2
end

PokemonDB.Starters = {
	"Charmander", "Squirtle", "Pikachu", 
	"Chikorita", "Cyndaquil", "Totodile",
	"Dratini", "Gastly", "Meowth"
}

function PokemonDB.GetRandomEncounter() 
	local all = {}
	for n, d in pairs(PokemonDB.Pokemon) do table.insert(all, {Name=n, Data=d}) end
	return all[math.random(1, #all)]
end

return PokemonDB
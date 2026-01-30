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
	-- ===== NONE POOL (Level 1 / Creep) =====
	["Pidgey"] = { 
		Id = 16, Rarity = "None", Attack = 5, HP = 5, Type = "Normal",
		Model = "Pidgey", Icon = "rbxassetid://0", Image = "rbxassetid://0" 
	},
	["Rattata"] = { 
		Id = 19, Rarity = "None", Attack = 6, HP = 5, Type = "Normal",
		Model = "Rattata", Icon = "rbxassetid://0", Image = "rbxassetid://0"
	},

	-- ===== COMMON POOL (Base Forms - Atk ~8-10) =====
	["Bulbasaur"] = {
		Id = 1, Rarity = "Common", Attack = 8, HP = 10, Type = "Grass",
		Model = "Bulbasaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650",
		EvolveTo = "Ivysaur"
	},
	["Gible"] = { Id=443, Rarity="Common", Attack=9, HP=8, Type="Dragon", Model="Gible", EvolveTo="Gabite", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Larvitar"] = { Id=246, Rarity="Common", Attack=9, HP=8, Type="Rock", Model="Larvitar", EvolveTo="Pupitar", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Bagon"] = { Id=371, Rarity="Common", Attack=9, HP=8, Type="Dragon", Model="Bagon", EvolveTo="Shelgon", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Axew"] = { Id=610, Rarity="Common", Attack=9, HP=8, Type="Dragon", Model="Axew", EvolveTo="Fraxure", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Deino"] = { Id=633, Rarity="Common", Attack=8, HP=8, Type="Dragon", Model="Deino", EvolveTo="Zweilous", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Ralts"] = { Id=280, Rarity="Common", Attack=6, HP=6, Type="Psychic", Model="Ralts", EvolveTo="Kirlia", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Pichu"] = { Id=172, Rarity="Common", Attack=6, HP=6, Type="Electric", Model="Pichu", EvolveTo="Pikachu", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Machop"] = { Id=66, Rarity="Common", Attack=10, HP=10, Type="Fighting", Model="Machop", EvolveTo="Machoke", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Gastly"] = { Id=92, Rarity="Common", Attack=10, HP=6, Type="Ghost", Model="Gastly", EvolveTo="Haunter", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Litwick"] = { Id=607, Rarity="Common", Attack=8, HP=8, Type="Ghost", Model="Litwick", EvolveTo="Lampent", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Dratini"] = { Id=147, Rarity="Common", Attack=8, HP=8, Type="Dragon", Model="Dratini", EvolveTo="Dragonair", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Magnemite"] = { Id=81, Rarity="Common", Attack=7, HP=7, Type="Electric", Model="Magnemite", EvolveTo="Magneton", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Swinub"] = { Id=220, Rarity="Common", Attack=7, HP=8, Type="Ice", Model="Swinub", EvolveTo="Piloswine", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Abra"] = { Id=63, Rarity="Common", Attack=10, HP=5, Type="Psychic", Model="Abra", EvolveTo="Kadabra", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Jangmo-o"] = { Id=782, Rarity="Common", Attack=8, HP=8, Type="Dragon", Model="Jangmo-o", EvolveTo="Hakamo-o", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },

	-- ===== UNCOMMON POOL (Stage 1 - Atk ~12-15) =====
	["Ivysaur"] = {
		Id = 2, Rarity = "Uncommon", Attack = 14, HP = 15, Type = "Grass",
		Model = "Ivysaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650",
		EvolveTo = "Venusaur"
	},
	["Gabite"] = { Id=444, Rarity="Uncommon", Attack=15, HP=14, Type="Dragon", Model="Gabite", EvolveTo="Garchomp", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Pupitar"] = { Id=247, Rarity="Uncommon", Attack=14, HP=15, Type="Rock", Model="Pupitar", EvolveTo="Tyranitar", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Shelgon"] = { Id=372, Rarity="Uncommon", Attack=14, HP=16, Type="Dragon", Model="Shelgon", EvolveTo="Salamence", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Fraxure"] = { Id=611, Rarity="Uncommon", Attack=15, HP=12, Type="Dragon", Model="Fraxure", EvolveTo="Haxorus", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Zweilous"] = { Id=634, Rarity="Uncommon", Attack=14, HP=14, Type="Dragon", Model="Zweilous", EvolveTo="Hydreigon", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Kirlia"] = { Id=281, Rarity="Uncommon", Attack=12, HP=12, Type="Psychic", Model="Kirlia", EvolveTo="Gardevoir", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Pikachu"] = { Id=25, Rarity="Uncommon", Attack=12, HP=10, Type="Electric", Model="Pikachu", EvolveTo="Raichu", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Machoke"] = { Id=67, Rarity="Uncommon", Attack=16, HP=16, Type="Fighting", Model="Machoke", EvolveTo="Machamp", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Haunter"] = { Id=93, Rarity="Uncommon", Attack=16, HP=10, Type="Ghost", Model="Haunter", EvolveTo="Gengar", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Lampent"] = { Id=608, Rarity="Uncommon", Attack=14, HP=12, Type="Ghost", Model="Lampent", EvolveTo="Chandelure", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Dragonair"] = { Id=148, Rarity="Uncommon", Attack=14, HP=14, Type="Dragon", Model="Dragonair", EvolveTo="Dragonite", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Magneton"] = { Id=82, Rarity="Uncommon", Attack=13, HP=12, Type="Electric", Model="Magneton", EvolveTo="Magnezone", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Piloswine"] = { Id=221, Rarity="Uncommon", Attack=14, HP=15, Type="Ice", Model="Piloswine", EvolveTo="Mamoswine", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Kadabra"] = { Id=64, Rarity="Uncommon", Attack=16, HP=10, Type="Psychic", Model="Kadabra", EvolveTo="Alakazam", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Hakamo-o"] = { Id=783, Rarity="Uncommon", Attack=14, HP=14, Type="Dragon", Model="Hakamo-o", EvolveTo="Kommo-o", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },

	-- ===== RARE POOL (Stage 2 - Atk ~18-20) =====
	["Venusaur"] = {
		Id = 3, Rarity = "Rare", Attack = 20, HP = 22, Type = "Grass",
		Model = "Venusaur", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650"
	},
	["Garchomp"] = { Id=445, Rarity="Rare", Attack=21, HP=20, Type="Dragon", Model="Garchomp", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Tyranitar"] = { Id=248, Rarity="Rare", Attack=22, HP=22, Type="Rock", Model="Tyranitar", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Salamence"] = { Id=373, Rarity="Rare", Attack=21, HP=19, Type="Dragon", Model="Salamence", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Haxorus"] = { Id=612, Rarity="Rare", Attack=22, HP=18, Type="Dragon", Model="Haxorus", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Hydreigon"] = { Id=635, Rarity="Rare", Attack=20, HP=20, Type="Dragon", Model="Hydreigon", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Gardevoir"] = { Id=282, Rarity="Rare", Attack=20, HP=16, Type="Psychic", Model="Gardevoir", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Raichu"] = { Id=26, Rarity="Rare", Attack=18, HP=16, Type="Electric", Model="Raichu", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Machamp"] = { Id=68, Rarity="Rare", Attack=22, HP=22, Type="Fighting", Model="Machamp", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Gengar"] = { Id=94, Rarity="Rare", Attack=22, HP=16, Type="Ghost", Model="Gengar", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Chandelure"] = { Id=609, Rarity="Rare", Attack=21, HP=16, Type="Ghost", Model="Chandelure", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Dragonite"] = { Id=149, Rarity="Rare", Attack=22, HP=20, Type="Dragon", Model="Dragonite", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Magnezone"] = { Id=462, Rarity="Rare", Attack=19, HP=18, Type="Electric", Model="Magnezone", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Mamoswine"] = { Id=473, Rarity="Rare", Attack=20, HP=22, Type="Ice", Model="Mamoswine", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Alakazam"] = { Id=65, Rarity="Rare", Attack=22, HP=14, Type="Psychic", Model="Alakazam", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },
	["Kommo-o"] = { Id=784, Rarity="Rare", Attack=19, HP=20, Type="Dragon", Model="Kommo-o", Icon = "rbxassetid://131802015396239", Image = "rbxassetid://71744981746650" },

	-- ===== LEGENDARY POOL (Max ~25) =====
	["Mewtwo"] = {
		Id = 150, Rarity = "Legend", Attack = 25, HP = 25, Type = "Psychic",
		Model = "Mewtwo", Icon = "rbxassetid://0", Image = "rbxassetid://0"
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
	"Gible", "Larvitar", "Bagon", "Axew", "Deino", 
	"Ralts", "Pichu", "Machop", "Gastly", "Litwick", "Dratini"
}

function PokemonDB.GetRandomEncounter() 
	local all = {}
	for n, d in pairs(PokemonDB.Pokemon) do table.insert(all, {Name=n, Data=d}) end
	return all[math.random(1, #all)]
end

return PokemonDB
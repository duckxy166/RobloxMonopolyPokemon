--[[
================================================================================
                      🐾 POKEMON DATABASE - Central Pokemon Data
================================================================================
    📌 Location: ReplicatedStorage (accessible by Server & Client)
    📌 Data Structure:
        - Id, Rarity, Attack, HP, Type, Ability
        - Evolution chain, Model, Icon
================================================================================
--]]

local PokemonDB = {}

-- Rarity -> Catch Difficulty (dice roll needed)
PokemonDB.RarityDifficulty = {
	["None"] = 2,
	["Common"] = 3,
	["Uncommon"] = 4,
	["Rare"] = 5,
	["Legend"] = 6
}

-- Type effectiveness (for future battle system)
PokemonDB.Types = {
	"Normal", "Fire", "Water", "Grass", "Electric",
	"Ice", "Fighting", "Poison", "Ground", "Flying",
	"Psychic", "Bug", "Rock", "Ghost", "Dragon",
	"Dark", "Steel", "Fairy"
}

-- Pokemon Data
PokemonDB.Pokemon = {
	-- ===== STARTER: BULBASAUR LINE =====
	["Bulbasaur"] = {
		Id = 1,
		Rarity = "Common",
		Attack = 49,
		HP = 45,
		Type = "Grass",
		Ability = "Overgrow",
		CanEvolve = true,
		EvolvesTo = "Ivysaur",
		EvolveLevel = 16,

		Model = "Bulbasaur",
		Icon = "rbxassetid://131802015396239", -- Small Icon (HUD)
		Image = "rbxassetid://71744981746650" -- Full Art (Encounter)
	},
	["Ivysaur"] = {
		Id = 2,
		Rarity = "Uncommon",
		Attack = 62,
		HP = 60,
		Type = "Grass",
		Ability = "Overgrow",
		CanEvolve = true,
		EvolvesTo = "Venusaur",
		EvolveLevel = 32,

		Model = "Ivysaur",
		Icon = "rbxassetid://131802015396239",
		Image = "rbxassetid://71744981746650"
	},
	["Venusaur"] = {
		Id = 3,
		Rarity = "Rare",
		Attack = 82,
		HP = 80,
		Type = "Grass",
		Ability = "Overgrow",
		CanEvolve = false,
		EvolvesTo = nil,

		Model = "Venusaur",
		Icon = "rbxassetid://131802015396239",
		Image = "rbxassetid://71744981746650"
	},

	-- ===== STARTER: CHARMANDER LINE ===== (DISABLED)
	--[[ 
	["Charmander"] = {
		Id = 4,
		Rarity = "Common",
		Attack = 52,
		HP = 39,
		Type = "Fire",
		Ability = "Blaze",
		CanEvolve = true,
		EvolvesTo = "Charmeleon",
		EvolveLevel = 16,
		Model = "Charmander",
		Icon = "rbxassetid://0"
	},
	["Charmeleon"] = {
		Id = 5,
		Rarity = "Uncommon",
		Attack = 64,
		HP = 58,
		Type = "Fire",
		Ability = "Blaze",
		CanEvolve = true,
		EvolvesTo = "Charizard",
		EvolveLevel = 36,
		Model = "Charmeleon",
		Icon = "rbxassetid://0"
	},
	["Charizard"] = {
		Id = 6,
		Rarity = "Rare",
		Attack = 84,
		HP = 78,
		Type = "Fire",
		Ability = "Blaze",
		CanEvolve = false,
		EvolvesTo = nil,
		Model = "Charizard",
		Icon = "rbxassetid://0"
	},
	
	-- ===== STARTER: SQUIRTLE LINE =====
	["Squirtle"] = {
		Id = 7,
		Rarity = "Common",
		Attack = 48,
		HP = 44,
		Type = "Water",
		Ability = "Torrent",
		CanEvolve = true,
		EvolvesTo = "Wartortle",
		EvolveLevel = 16,
		Model = "Squirtle",
		Icon = "rbxassetid://0"
	},
	["Wartortle"] = {
		Id = 8,
		Rarity = "Uncommon",
		Attack = 63,
		HP = 59,
		Type = "Water",
		Ability = "Torrent",
		CanEvolve = true,
		EvolvesTo = "Blastoise",
		EvolveLevel = 36,
		Model = "Wartortle",
		Icon = "rbxassetid://0"
	},
	["Blastoise"] = {
		Id = 9,
		Rarity = "Rare",
		Attack = 83,
		HP = 79,
		Type = "Water",
		Ability = "Torrent",
		CanEvolve = false,
		EvolvesTo = nil,
		Model = "Blastoise",
		Icon = "rbxassetid://0"
	},
	
	-- ===== PIKACHU LINE =====
	["Pikachu"] = {
		Id = 25,
		Rarity = "Rare",
		Attack = 55,
		HP = 35,
		Type = "Electric",
		Ability = "Static",
		CanEvolve = true,
		EvolvesTo = "Raichu",
		EvolveLevel = 0, -- Thunder Stone
		Model = "Pikachu",
		Icon = "rbxassetid://0"
	},
	["Raichu"] = {
		Id = 26,
		Rarity = "Rare",
		Attack = 90,
		HP = 60,
		Type = "Electric",
		Ability = "Static",
		CanEvolve = false,
		EvolvesTo = nil,
		Model = "Raichu",
		Icon = "rbxassetid://0"
	},
	
	-- ===== LEGENDARY =====
	["Mewtwo"] = {
		Id = 150,
		Rarity = "Legend",
		Attack = 110,
		HP = 106,
		Type = "Psychic",
		Ability = "Pressure",
		CanEvolve = false,
		EvolvesTo = nil,
		Model = "Mewtwo",
		Icon = "rbxassetid://0"
	},
	["Mew"] = {
		Id = 151,
		Rarity = "Legend",
		Attack = 100,
		HP = 100,
		Type = "Psychic",
		Ability = "Synchronize",
		CanEvolve = false,
		EvolvesTo = nil,
		Model = "Mew",
		Icon = "rbxassetid://0"
	}
	--]]
}

-- ===== HELPER FUNCTIONS =====

-- Get Pokemon data by name
function PokemonDB.GetPokemon(name)
	return PokemonDB.Pokemon[name]
end

-- Get catch difficulty for a pokemon
function PokemonDB.GetCatchDifficulty(pokemonName)
	local poke = PokemonDB.Pokemon[pokemonName]
	if poke then
		return PokemonDB.RarityDifficulty[poke.Rarity] or 3
	end
	return 3
end

-- Get all Pokemon of a specific rarity
function PokemonDB.GetByRarity(rarity)
	local result = {}
	for name, data in pairs(PokemonDB.Pokemon) do
		if data.Rarity == rarity then
			table.insert(result, {Name = name, Data = data})
		end
	end
	return result
end

-- Get random Pokemon for encounter (weighted by rarity)
function PokemonDB.GetRandomEncounter()
	local pool = {}
	for name, data in pairs(PokemonDB.Pokemon) do
		local weight = 1
		if data.Rarity == "Common" then weight = 50
		elseif data.Rarity == "Uncommon" then weight = 30
		elseif data.Rarity == "Rare" then weight = 15
		elseif data.Rarity == "Legend" then weight = 5
		end
		for i = 1, weight do
			table.insert(pool, {Name = name, Data = data})
		end
	end
	return pool[math.random(1, #pool)]
end

-- Check if Pokemon can evolve
function PokemonDB.CanEvolve(pokemonName)
	local poke = PokemonDB.Pokemon[pokemonName]
	return poke and poke.CanEvolve
end

-- Get evolution target
function PokemonDB.GetEvolution(pokemonName)
	local poke = PokemonDB.Pokemon[pokemonName]
	if poke and poke.CanEvolve then
		return poke.EvolvesTo
	end
	return nil
end

return PokemonDB


--================================================================================
--                      💾 POKEMON DATABASE - Central Pokemon Data
--================================================================================

local PokemonDB = {}

-- Rarity -> Catch Difficulty (ความยากในการจับ)
-- SYSTEM: Common=1, Uncommon=2, Rare=3, Epic=4, Divine=5, Legend=6
PokemonDB.RarityDifficulty = {
	["Common"] = 1,    -- จับง่ายสุด (1 ลูก)
	["Uncommon"] = 2,
	["Rare"] = 3,
	["Epic"] = 4,
	["Divine"] = 5,    -- NEW!
	["Legend"] = 6     -- ยากสุด (6 ลูก)
}

-- Tile Encounter Rates (โอกาสเกิดตามสีช่อง)
-- NEW: Common is base tier, Epic/Divine/Legend as higher tiers
PokemonDB.EncounterRates = {
	["Bright green"] = { Common = 60, Uncommon = 30, Rare = 8, Epic = 2, Divine = 0, Legend = 0 },
	["Forest green"] = { Common = 35, Uncommon = 40, Rare = 20, Epic = 5, Divine = 0, Legend = 0 },
	["Dark green"]   = { Common = 15, Uncommon = 35, Rare = 35, Epic = 12, Divine = 3, Legend = 0 },
	["Earth green"]  = { Common = 5,  Uncommon = 15, Rare = 35, Epic = 30, Divine = 15, Legend = 0 },
	["Gold"]         = { Common = 0,  Uncommon = 0,  Rare = 0,  Epic = 0, Divine = 0, Legend = 100 },
	-- Default fallback
	["Default"]      = { Common = 80, Uncommon = 15, Rare = 5, Epic = 0, Divine = 0, Legend = 0 }
}

-- Pokemon Data
PokemonDB.Pokemon = {
	-- ===== COMMON POOL (Base Creeps - formerly "None") =====
	["Caterpie"] = { 
		Id = 10, Rarity = "Common", Attack = 4, HP = 5, Type = "Bug",
		Model = "010 - Caterpie", EvolveTo = "Metapod", Icon = "rbxassetid://104608486929955", Image = "rbxassetid://104608486929955"
	},
	["Pidgey"] = { 
		Id = 16, Rarity = "Common", Attack = 5, HP = 5, Type = "Normal",
		Model = "016 - Pidgey", EvolveTo = "Pidgeotto", Icon = "rbxassetid://79968359884209", Image = "rbxassetid://79968359884209"
	},
	["Rattata"] = { 
		Id = 19, Rarity = "Common", Attack = 6, HP = 5, Type = "Normal",
		Model = "019 - Rattata", EvolveTo = "Raticate", Icon = "rbxassetid://103265419643338", Image = "rbxassetid://103265419643338"
	},
	["Magikarp"] = { 
		Id = 129, Rarity = "Common", Attack = 1, HP = 5, Type = "Water",
		Model = "129 - Magikarp", EvolveTo = "Gyarados", Icon = "rbxassetid://102675286979211", Image = "rbxassetid://102675286979211"
	},

	-- ===== UNCOMMON POOL (Starter Forms) =====
	["Charmander"] = {
		Id = 4, Rarity = "Common", Attack = 10, HP = 10, Type = "Fire",
		Model = "004 - Charmander", EvolveTo = "Charmeleon", Icon = "rbxassetid://121436913614801", Image = "rbxassetid://121436913614801"
	},
	["Squirtle"] = {
		Id = 7, Rarity = "Common", Attack = 9, HP = 11, Type = "Water",
		Model = "007 - Squirtle", EvolveTo = "Wartortle", Icon = "rbxassetid://88623806301254", Image = "rbxassetid://88623806301254"
	},
	["Pikachu"] = {
		Id = 25, Rarity = "Common", Attack = 12, HP = 8, Type = "Electric",
		Model = "025 - Pikachu", EvolveTo = "Raichu", Icon = "rbxassetid://124567385949746", Image = "rbxassetid://124567385949746"
	},
	["Meowth"] = {
		Id = 52, Rarity = "Common", Attack = 8, HP = 8, Type = "Normal",
		Model = "052 - Meowth", EvolveTo = "Persian", Icon = "rbxassetid://125524212010581", Image = "rbxassetid://125524212010581"
	},
	["Gastly"] = {
		Id = 92, Rarity = "Common", Attack = 12, HP = 6, Type = "Ghost",
		Model = "092 - Gastly", EvolveTo = "Haunter", Icon = "rbxassetid://70628851155055", Image = "rbxassetid://70628851155055"
	},
	["Dratini"] = {
		Id = 147, Rarity = "Common", Attack = 10, HP = 10, Type = "Dragon",
		Model = "147 - Dratini", EvolveTo = "Dragonair", Icon = "rbxassetid://129382301073001", Image = "rbxassetid://129382301073001"
	},
	["Chikorita"] = {
		Id = 152, Rarity = "Common", Attack = 8, HP = 10, Type = "Grass",
		Model = "152 - Chikorita", EvolveTo = "Bayleef", Icon = "rbxassetid://135823310394175", Image = "rbxassetid://135823310394175"
	},
	["Cyndaquil"] = {
		Id = 155, Rarity = "Common", Attack = 10, HP = 8, Type = "Fire",
		Model = "155 - Cyndaquil", EvolveTo = "Quilava", Icon = "rbxassetid://113760601834003", Image = "rbxassetid://113760601834003"
	},
	["Totodile"] = {
		Id = 158, Rarity = "Common", Attack = 10, HP = 10, Type = "Water",
		Model = "158 - Totodile", EvolveTo = "Croconaw", Icon = "rbxassetid://116559786008726", Image = "rbxassetid://116559786008726"
	},

	-- ===== UNCOMMON POOL (Stage 1) =====
	["Metapod"] = {
		Id = 11, Rarity = "Uncommon", Attack = 6, HP = 10, Type = "Bug",
		Model = "011 - Metapod", EvolveTo = "Butterfree", Icon = "rbxassetid://84270961427126", Image = "rbxassetid://84270961427126"
	},
	["Pidgeotto"] = {
		Id = 17, Rarity = "Uncommon", Attack = 12, HP = 12, Type = "Normal",
		Model = "017 - Pidgeotto", EvolveTo = "Pidgeot", Icon = "rbxassetid://118010329073205", Image = "rbxassetid://118010329073205"
	},
	["Raticate"] = {
		Id = 20, Rarity = "Uncommon", Attack = 14, HP = 10, Type = "Normal",
		Model = "020 - Raticate", Icon = "rbxassetid://125901990339195", Image = "rbxassetid://125901990339195"
	},
	["Charmeleon"] = {
		Id = 5, Rarity = "Uncommon", Attack = 16, HP = 14, Type = "Fire",
		Model = "005 - Charmeleon", EvolveTo = "Charizard", Icon = "rbxassetid://100927466566921", Image = "rbxassetid://100927466566921"
	},
	["Wartortle"] = {
		Id = 8, Rarity = "Uncommon", Attack = 14, HP = 16, Type = "Water",
		Model = "008 - Wartortle", EvolveTo = "Blastoise", Icon = "rbxassetid://120381686356356", Image = "rbxassetid://120381686356356"
	},
	["Persian"] = {
		Id = 53, Rarity = "Uncommon", Attack = 14, HP = 12, Type = "Normal",
		Model = "053 - Persian", Icon = "rbxassetid://123983202327080", Image = "rbxassetid://123983202327080"
	},
	["Haunter"] = {
		Id = 93, Rarity = "Uncommon", Attack = 18, HP = 10, Type = "Ghost",
		Model = "093 - Haunter", EvolveTo = "Gengar", Icon = "rbxassetid://76183676056817", Image = "rbxassetid://76183676056817"
	},
	["Dragonair"] = {
		Id = 148, Rarity = "Uncommon", Attack = 16, HP = 16, Type = "Dragon",
		Model = "148 - Dragonair", EvolveTo = "Dragonite", Icon = "rbxassetid://121255668090770", Image = "rbxassetid://121255668090770"
	},
	["Bayleef"] = {
		Id = 153, Rarity = "Uncommon", Attack = 14, HP = 16, Type = "Grass",
		Model = "153 - Bayleef", EvolveTo = "Meganium", Icon = "rbxassetid://120922274497392", Image = "rbxassetid://120922274497392"
	},
	["Quilava"] = {
		Id = 156, Rarity = "Uncommon", Attack = 16, HP = 14, Type = "Fire",
		Model = "156 - Quilava", EvolveTo = "Typhlosion", Icon = "rbxassetid://136395142842992", Image = "rbxassetid://136395142842992"
	},
	["Croconaw"] = {
		Id = 159, Rarity = "Uncommon", Attack = 16, HP = 16, Type = "Water",
		Model = "159 - Croconaw", EvolveTo = "Feraligatr", Icon = "rbxassetid://130063042186099", Image = "rbxassetid://130063042186099"
	},

	-- ===== RARE POOL (Stage 2 / Single Strong) =====
	["Venusaur"] = {
		Id = 3, Rarity = "Rare", Attack = 22, HP = 24, Type = "Grass",
		Model = "003 - Venusaur", Icon = "rbxassetid://136798929875157", Image = "rbxassetid://136798929875157"
	},
	["Charizard"] = {
		Id = 6, Rarity = "Rare", Attack = 25, HP = 20, Type = "Fire",
		Model = "006 - Charizard", Icon = "rbxassetid://121771857774500", Image = "rbxassetid://121771857774500"
	},
	["Blastoise"] = {
		Id = 9, Rarity = "Rare", Attack = 22, HP = 25, Type = "Water",
		Model = "009 - Blastoise", Icon = "rbxassetid://134654930089233", Image = "rbxassetid://134654930089233"
	},
	["Butterfree"] = {
		Id = 12, Rarity = "Rare", Attack = 15, HP = 15, Type = "Bug",
		Model = "012 - Butterfree", Icon = "rbxassetid://118728004248606", Image = "rbxassetid://118728004248606"
	},
	["Pidgeot"] = {
		Id = 18, Rarity = "Rare", Attack = 18, HP = 18, Type = "Normal",
		Model = "018 - Pidgeot", Icon = "rbxassetid://117482560415072", Image = "rbxassetid://117482560415072"
	},
	["Raichu"] = {
		Id = 26, Rarity = "Rare", Attack = 20, HP = 18, Type = "Electric",
		Model = "026 - Raichu", Icon = "rbxassetid://92110987263227", Image = "rbxassetid://92110987263227"
	},
	["Gengar"] = {
		Id = 94, Rarity = "Rare", Attack = 25, HP = 16, Type = "Ghost",
		Model = "094 - Gengar", Icon = "rbxassetid://73487593240517", Image = "rbxassetid://73487593240517"
	},
	["Gyarados"] = {
		Id = 130, Rarity = "Rare", Attack = 25, HP = 22, Type = "Water",
		Model = "130 - Gyarados", Icon = "rbxassetid://121398576898364", Image = "rbxassetid://121398576898364"
	},
	["Lapras"] = {
		Id = 131, Rarity = "Rare", Attack = 20, HP = 28, Type = "Water",
		Model = "131 - Lapras", Icon = "rbxassetid://90620155620612", Image = "rbxassetid://90620155620612"
	},
	["Dragonite"] = {
		Id = 149, Rarity = "Rare", Attack = 28, HP = 25, Type = "Dragon",
		Model = "149 - Dragonite", Icon = "rbxassetid://121255668090770", Image = "rbxassetid://121255668090770"
	},
	["Meganium"] = {
		Id = 154, Rarity = "Rare", Attack = 22, HP = 26, Type = "Grass",
		Model = "154 - Meganium", Icon = "rbxassetid://139094067753742", Image = "rbxassetid://139094067753742"
	},
	["Typhlosion"] = {
		Id = 157, Rarity = "Rare", Attack = 25, HP = 22, Type = "Fire",
		Model = "157 - Typhlosion", Icon = "rbxassetid://122073354990414", Image = "rbxassetid://122073354990414"
	},
	["Feraligatr"] = {
		Id = 160, Rarity = "Rare", Attack = 24, HP= 24, Type = "Water",
		Model = "160 - Feraligatr", Icon = "rbxassetid://114382229506668", Image = "rbxassetid://114382229506668"
	},
	-- ===== GEN 1-2 ADDITIONS =====
	["Zubat"] = {
		Id = 41, Rarity = "Common", Attack = 5, HP = 5, Type = "Poison",
		Model = "041 - Zubat", EvolveTo = "Golbat", Icon = "rbxassetid://135969606810652", Image = "rbxassetid://135969606810652"
	},
	["Golbat"] = {
		Id = 42, Rarity = "Uncommon", Attack = 14, HP = 15, Type = "Poison",
		Model = "042 - Golbat", Icon = "rbxassetid://124032175965383", Image = "rbxassetid://124032175965383"
	},
	["Psyduck"] = {
		Id = 54, Rarity = "Common", Attack = 8, HP = 10, Type = "Water",
		Model = "054 - Psyduck", EvolveTo = "Golduck", Icon = "rbxassetid://126712195495804", Image = "rbxassetid://126712195495804"
	},
	["Golduck"] = {
		Id = 55, Rarity = "Rare", Attack = 20, HP = 22, Type = "Water",
		Model = "055 - Golduck", Icon = "rbxassetid://128832364021033", Image = "rbxassetid://128832364021033"
	},
	["Togepi"] = {
		Id = 175, Rarity = "Common", Attack = 5, HP = 8, Type = "Fairy",
		Model = "175 - Togepi", EvolveTo = "Togetic", Icon = "rbxassetid://106030051140231", Image = "rbxassetid://106030051140231"
	},
	["Togetic"] = {
		Id = 176, Rarity = "Uncommon", Attack = 12, HP = 15, Type = "Fairy",
		Model = "176 - Togetic", EvolveTo = "Togekiss", Icon = "rbxassetid://82713062671052", Image = "rbxassetid://82713062671052"
	},
	["Marill"] = {
		Id = 183, Rarity = "Common", Attack = 7, HP = 12, Type = "Water",
		Model = "183 - Marill", EvolveTo = "Azumarill", Icon = "rbxassetid://137444889144126", Image = "rbxassetid://137444889144126"
	},
	["Azumarill"] = {
		Id = 184, Rarity = "Rare", Attack = 18, HP = 26, Type = "Water",
		Model = "184 - Azumarill", Icon = "rbxassetid://85928060428521", Image = "rbxassetid://85928060428521"
	},
	["Larvitar"] = {
		Id = 246, Rarity = "Common", Attack = 12, HP = 12, Type = "Rock",
		Model = "246 - Larvitar", EvolveTo = "Pupitar", Icon = "rbxassetid://114738621370195", Image = "rbxassetid://114738621370195"
	},
	["Pupitar"] = {
		Id = 247, Rarity = "Uncommon", Attack = 18, HP = 18, Type = "Rock",
		Model = "247 - Pupitar", EvolveTo = "Tyranitar", Icon = "rbxassetid://108993508354994", Image = "rbxassetid://108993508354994"
	},
	["Tyranitar"] = {
		Id = 248, Rarity = "Rare", Attack = 28, HP = 28, Type = "Rock",
		Model = "248 - Tyranitar", Icon = "rbxassetid://85138698243117", Image = "rbxassetid://85138698243117"
	},

	-- ===== GEN 3 HOENN =====
	["Treecko"] = {
		Id = 252, Rarity = "Common", Attack = 10, HP = 9, Type = "Grass",
		Model = "252 - Treecko", EvolveTo = "Grovyle", Icon = "rbxassetid://77427423767316", Image = "rbxassetid://77427423767316"
	},
	["Grovyle"] = {
		Id = 253, Rarity = "Uncommon", Attack = 16, HP = 14, Type = "Grass",
		Model = "253 - Grovyle", EvolveTo = "Sceptile", Icon = "rbxassetid://124309669203410", Image = "rbxassetid://124309669203410"
	},
	["Sceptile"] = {
		Id = 254, Rarity = "Rare", Attack = 25, HP = 20, Type = "Grass",
		Model = "254 - Sceptile", Icon = "rbxassetid://101625010299924", Image = "rbxassetid://101625010299924"
	},
	["Torchic"] = {
		Id = 255, Rarity = "Common", Attack = 11, HP = 8, Type = "Fire",
		Model = "255 - Torchic", EvolveTo = "Combusken", Icon = "rbxassetid://134722738127378", Image = "rbxassetid://134722738127378"
	},
	["Combusken"] = {
		Id = 256, Rarity = "Uncommon", Attack = 17, HP = 13, Type = "Fire",
		Model = "256 - Combusken", EvolveTo = "Blaziken", Icon = "rbxassetid://138557250718542", Image = "rbxassetid://138557250718542"
	},
	["Blaziken"] = {
		Id = 257, Rarity = "Rare", Attack = 27, HP = 18, Type = "Fire",
		Model = "257 - Blaziken", Icon = "rbxassetid://116477204045832", Image = "rbxassetid://116477204045832"
	},
	["Mudkip"] = {
		Id = 258, Rarity = "Common", Attack = 9, HP = 11, Type = "Water",
		Model = "258 - Mudkip", EvolveTo = "Marshtomp", Icon = "rbxassetid://100021812634842", Image = "rbxassetid://100021812634842"
	},
	["Marshtomp"] = {
		Id = 259, Rarity = "Uncommon", Attack = 15, HP = 16, Type = "Water",
		Model = "259 - Marshtomp", EvolveTo = "Swampert", Icon = "rbxassetid://86400581791610", Image = "rbxassetid://86400581791610"
	},
	["Swampert"] = {
		Id = 260, Rarity = "Rare", Attack = 24, HP = 24, Type = "Water",
		Model = "260 - Swampert", Icon = "rbxassetid://77088904470441", Image = "rbxassetid://77088904470441"
	},
	["Ralts"] = {
		Id = 280, Rarity = "Common", Attack = 8, HP = 7, Type = "Psychic",
		Model = "280 - Ralts", EvolveTo = "Kirlia", Icon = "rbxassetid://140515787121102", Image = "rbxassetid://140515787121102"
	},
	["Kirlia"] = {
		Id = 281, Rarity = "Uncommon", Attack = 14, HP = 12, Type = "Psychic",
		Model = "281 - Kirlia", EvolveTo = "Gardevoir", Icon = "rbxassetid://89729947355098", Image = "rbxassetid://89729947355098"
	},
	["Gardevoir"] = {
		Id = 282, Rarity = "Rare", Attack = 26, HP = 20, Type = "Psychic",
		Model = "282 - Gardevoir", Icon = "rbxassetid://137706749143481", Image = "rbxassetid://137706749143481"
	},
	["Beldum"] = {
		Id = 374, Rarity = "Common", Attack = 10, HP = 12, Type = "Steel",
		Model = "374 - Beldum", EvolveTo = "Metang", Icon = "rbxassetid://81670992056922", Image = "rbxassetid://81670992056922"
	},
	["Metang"] = {
		Id = 375, Rarity = "Uncommon", Attack = 16, HP = 18, Type = "Steel",
		Model = "375 - Metang", EvolveTo = "Metagross", Icon = "rbxassetid://130088362064615", Image = "rbxassetid://130088362064615"
	},
	["Metagross"] = {
		Id = 376, Rarity = "Rare", Attack = 28, HP = 26, Type = "Steel",
		Model = "376 - Metagross", Icon = "rbxassetid://122380520580963", Image = "rbxassetid://122380520580963"
	},

	-- ===== GEN 4 SINNOH =====
	["Turtwig"] = {
		Id = 387, Rarity = "Common", Attack = 9, HP = 11, Type = "Grass",
		Model = "387 - Turtwig", EvolveTo = "Grotle", Icon = "rbxassetid://71071979111881", Image = "rbxassetid://71071979111881"
	},
	["Grotle"] = {
		Id = 388, Rarity = "Uncommon", Attack = 15, HP = 16, Type = "Grass",
		Model = "388 - Grotle", EvolveTo = "Torterra", Icon = "rbxassetid://130619327200511", Image = "rbxassetid://130619327200511"
	},
	["Torterra"] = {
		Id = 389, Rarity = "Rare", Attack = 24, HP = 25, Type = "Grass",
		Model = "389 - Torterra", Icon = "rbxassetid://131467317357548", Image = "rbxassetid://131467317357548"
	},
	["Chimchar"] = {
		Id = 390, Rarity = "Common", Attack = 11, HP = 8, Type = "Fire",
		Model = "390 - Chimchar", EvolveTo = "Monferno", Icon = "rbxassetid://94161775033579", Image = "rbxassetid://94161775033579"
	},
	["Monferno"] = {
		Id = 391, Rarity = "Uncommon", Attack = 17, HP = 12, Type = "Fire",
		Model = "391 - Monferno", EvolveTo = "Infernape", Icon = "rbxassetid://77951844859229", Image = "rbxassetid://77951844859229"
	},
	["Infernape"] = {
		Id = 392, Rarity = "Rare", Attack = 26, HP = 18, Type = "Fire",
		Model = "392 - Infernape", Icon = "rbxassetid://85398480998557", Image = "rbxassetid://85398480998557"
	},
	["Piplup"] = {
		Id = 393, Rarity = "Common", Attack = 9, HP = 10, Type = "Water",
		Model = "393 - Piplup", EvolveTo = "Prinplup", Icon = "rbxassetid://108986699929048", Image = "rbxassetid://108986699929048"
	},
	["Prinplup"] = {
		Id = 394, Rarity = "Uncommon", Attack = 15, HP = 15, Type = "Water",
		Model = "394 - Prinplup", EvolveTo = "Empoleon", Icon = "rbxassetid://80912630264598", Image = "rbxassetid://80912630264598"
	},
	["Empoleon"] = {
		Id = 395, Rarity = "Rare", Attack = 23, HP = 23, Type = "Water",
		Model = "395 - Empoleon", Icon = "rbxassetid://90435442302767", Image = "rbxassetid://90435442302767"
	},
	["Bidoof"] = {
		Id = 399, Rarity = "Common", Attack = 4, HP = 6, Type = "Normal",
		Model = "399 - Bidoof", EvolveTo = "Bibarel", Icon = "rbxassetid://88041120791602", Image = "rbxassetid://88041120791602"
	},
	["Bibarel"] = {
		Id = 400, Rarity = "Uncommon", Attack = 14, HP = 18, Type = "Normal",
		Model = "400 - Bibarel", Icon = "rbxassetid://79576768503406", Image = "rbxassetid://79576768503406"
	},
	["Gible"] = {
		Id = 443, Rarity = "Common", Attack = 12, HP = 12, Type = "Dragon",
		Model = "443 - Gible", EvolveTo = "Gabite", Icon = "rbxassetid://102990550229282", Image = "rbxassetid://102990550229282"
	},
	["Gabite"] = {
		Id = 444, Rarity = "Uncommon", Attack = 18, HP = 18, Type = "Dragon",
		Model = "444 - Gabite", EvolveTo = "Garchomp", Icon = "rbxassetid://90858868001482", Image = "rbxassetid://90858868001482"
	},
	["Garchomp"] = {
		Id = 445, Rarity = "Rare", Attack = 30, HP = 28, Type = "Dragon",
		Model = "445 - Garchomp", Icon = "rbxassetid://78500346251469", Image = "rbxassetid://78500346251469"
	},
	["Togekiss"] = {
		Id = 468, Rarity = "Rare", Attack = 24, HP = 26, Type = "Fairy",
		Model = "468 - Togekiss", Icon = "rbxassetid://118137851339500", Image = "rbxassetid://118137851339500"
	},

	-- ===== GEN 5-6 =====
	["Ferroseed"] = {
		Id = 597, Rarity = "Common", Attack = 8, HP = 12, Type = "Grass",
		Model = "597 - Ferroseed", EvolveTo = "Ferrothorn", Icon = "rbxassetid://128079895836937", Image = "rbxassetid://128079895836937"
	},
	["Ferrothorn"] = {
		Id = 598, Rarity = "Rare", Attack = 18, HP = 28, Type = "Grass",
		Model = "598 - Ferrothorn", Icon = "rbxassetid://88295237814419", Image = "rbxassetid://88295237814419"
	},
	["Litwick"] = {
		Id = 607, Rarity = "Common", Attack = 12, HP = 6, Type = "Ghost",
		Model = "607 - Litwick", EvolveTo = "Lampent", Icon = "rbxassetid://130744569715962", Image = "rbxassetid://130744569715962"
	},
	["Lampent"] = {
		Id = 608, Rarity = "Uncommon", Attack = 18, HP = 10, Type = "Ghost",
		Model = "608 - Lampent", EvolveTo = "Chandelure", Icon = "rbxassetid://72361105976188", Image = "rbxassetid://72361105976188"
	},

	-- ===== GEN 9 PALDEA =====
	["Sprigatito"] = {
		Id = 906, Rarity = "Common", Attack = 11, HP = 9, Type = "Grass",
		Model = "906 - Sprigatito", EvolveTo = "Floragato", Icon = "rbxassetid://99267429164006", Image = "rbxassetid://99267429164006"
	},
	["Floragato"] = {
		Id = 907, Rarity = "Uncommon", Attack = 18, HP = 19, Type = "Grass",
		Model = "907 - Floragato", EvolveTo = "Floragato", Icon = "rbxassetid://119093547471933", Image = "rbxassetid://119093547471933"
	},
	["Meowscarada"] = {
		Id = 908, Rarity = "Rare", Attack = 27, HP = 20, Type = "Grass",
		Model = "908 - Meowscarada", Icon = "rbxassetid://76132205154349", Image = "rbxassetid://76132205154349"
	},
	["Fuecoco"] = {
		Id = 909, Rarity = "Common", Attack = 19, HP = 19, Type = "Fire",
		Model = "909 - Fuecoco", EvolveTo = "Crocalor", Icon = "rbxassetid://100643239328472", Image = "rbxassetid://100643239328472"
	},
	["Skeledirge"] = {
		Id = 911, Rarity = "Rare", Attack = 24, HP = 28, Type = "Fire",
		Model = "911 - Skeledirge", Icon = "rbxassetid://133636351324480", Image = "rbxassetid://133636351324480"
	},
	["Quaxly"] = {
		Id = 912, Rarity = "Common", Attack = 11, HP = 10, Type = "Water",
		Model = "912 - Quaxly", EvolveTo = "Quaxwell", Icon = "rbxassetid://139219172128335", Image = "rbxassetid://139219172128335"
	},
	["Quaxwell"] = {
		Id = 913, Rarity = "Uncommon", Attack = 21, HP = 18, Type = "Water",
		Model = "913 - Quaxwell", EvolveTo = "Quaquaval", Icon = "rbxassetid://81551061112201", Image = "rbxassetid://81551061112201"
	},
	["Quaquaval"] = {
		Id = 914, Rarity = "Rare", Attack = 26, HP = 22, Type = "Water",
		Model = "914 - Quaquaval", Icon = "rbxassetid://108393314003706", Image = "rbxassetid://108393314003706"
	},
	-- ===== EPIC POOL (Powerful Stage 2) =====
	["Charizard"] = {
		Id = 6, Rarity = "Epic", Attack = 25, HP = 20, Type = "Fire",
		Model = "006 - Charizard", Icon = "rbxassetid://121771857774500", Image = "rbxassetid://121771857774500"
	},
	["Blastoise"] = {
		Id = 9, Rarity = "Epic", Attack = 22, HP = 25, Type = "Water",
		Model = "009 - Blastoise", Icon = "rbxassetid://134654930089233", Image = "rbxassetid://134654930089233"
	},
	["Venusaur"] = {
		Id = 3, Rarity = "Epic", Attack = 22, HP = 24, Type = "Grass",
		Model = "003 - Venusaur", Icon = "rbxassetid://136798929875157", Image = "rbxassetid://136798929875157"
	},
	["Dragonite"] = {
		Id = 149, Rarity = "Epic", Attack = 28, HP = 25, Type = "Dragon",
		Model = "149 - Dragonite", Icon = "rbxassetid://121255668090770", Image = "rbxassetid://121255668090770"
	},
	["Tyranitar"] = {
		Id = 248, Rarity = "Epic", Attack = 28, HP = 28, Type = "Rock",
		Model = "248 - Tyranitar", Icon = "rbxassetid://85138698243117", Image = "rbxassetid://85138698243117"
	},
	["Garchomp"] = {
		Id = 445, Rarity = "Epic", Attack = 30, HP = 28, Type = "Dragon",
		Model = "445 - Garchomp", Icon = "rbxassetid://78500346251469", Image = "rbxassetid://78500346251469"
	},
	["Metagross"] = {
		Id = 376, Rarity = "Epic", Attack = 28, HP = 26, Type = "Steel",
		Model = "376 - Metagross", Icon = "rbxassetid://122380520580963", Image = "rbxassetid://122380520580963"
	},

	-- ===== LEGENDARY POOL =====
	["Mewtwo"] = {
		Id = 150, Rarity = "Legend", Attack = 35, HP = 30, Type = "Psychic",
		Model = "150 - Mewtwo", Icon = "rbxassetid://140657668203910", Image = "rbxassetid://140657668203910"
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

	-- เรียงลำดับโอกาส (Updated with Divine)
	local order = {"Common", "Uncommon", "Rare", "Epic", "Divine", "Legend"}
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

	-- ถ้าไม่มีใน Pool (เช่นตั้งค่าผิด) ให้ลองถอยไปหา Common
	if #pool == 0 then
		warn("⚠️ No pokemon found for rarity: " .. selectedRarity .. ". Trying fallback.")
		pool = PokemonDB.GetByRarity("Common")
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
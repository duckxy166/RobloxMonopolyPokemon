--================================================================================
--                      💾 POKEMON DATABASE - Central Pokemon Data (BALANCED)
--================================================================================
-- ✅ Changes per your request:
-- 1) ลบ Pokemon Gen 2 ทั้งหมด (152-251)
-- 2) ลบ Eevee + Ditto ออก
-- 3) Divine = เฉพาะ Pseudo เท่านั้น (Dragonite / Metagross / Garchomp)
-- 4) ปรับค่า Attack/HP “รายตัว” ให้เหมาะกับระบบทอยเต๋า RPG (ไม่มี crit)
-- 5) แก้ข้อมูล evolve ที่ผิด (เช่น Floragato)
--================================================================================

local PokemonDB = {}

-- Rarity -> Catch Difficulty (ความยากในการจับ)
-- SYSTEM: Common=1, Uncommon=2, Rare=3, Epic=4, Divine=5, Legend=6
PokemonDB.RarityDifficulty = {
	["Common"] = 1,
	["Uncommon"] = 2,
	["Rare"] = 3,
	["Epic"] = 4,
	["Divine"] = 5,
	["Legend"] = 6
}

-- Tile Encounter Rates (โอกาสเกิดตามสีช่อง) - tuned for Divine(Pseudo)
PokemonDB.EncounterRates = {
	["Bright green"] = { Common = 65, Uncommon = 30, Rare = 5,  Epic = 0, Divine = 0, Legend = 0 },
	["Forest green"] = { Common = 40, Uncommon = 40, Rare = 18, Epic = 2, Divine = 0, Legend = 0 },
	["Dark green"]   = { Common = 18, Uncommon = 35, Rare = 40, Epic = 5, Divine = 2, Legend = 0 },
	["Earth green"]  = { Common = 6,  Uncommon = 16, Rare = 50, Epic = 22, Divine = 6, Legend = 0 },
	["Gold"]         = { Common = 0,  Uncommon = 0,  Rare = 0,  Epic = 0,  Divine = 0, Legend = 100 },
	["Default"]      = { Common = 80, Uncommon = 15, Rare = 5,  Epic = 0,  Divine = 0, Legend = 0 }
}

-- Pokemon Data (รายตัว)
PokemonDB.Pokemon = {
	--================================================================================
	-- GEN 1 COMPLETE (1-151)  ✅ (แต่ Eevee/Ditto ถูกลบแล้วตามที่ขอ)
	-- NOTE: ตัวที่ไม่มี asset ของคุณ -> ใส่ Icon/Image เป็น 0 ก่อน
	--================================================================================

	-- #001-003 Bulbasaur line
	["Bulbasaur"] = { Id=1, Rarity="Uncommon", Attack=11, HP=14, Type="Grass", Model="001 - Bulbasaur", EvolveTo="Ivysaur", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Ivysaur"]   = { Id=2, Rarity="Rare",     Attack=15, HP=20, Type="Grass", Model="002 - Ivysaur",   EvolveTo="Venusaur", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Venusaur"]  = { Id=3, Rarity="Epic",     Attack=21, HP=28, Type="Grass", Model="003 - Venusaur",  Icon="rbxassetid://136798929875157", Image="rbxassetid://136798929875157" },

	-- #004-006 Charmander line
	["Charmander"] = { Id=4, Rarity="Uncommon", Attack=12, HP=13, Type="Fire", Model="004 - Charmander", EvolveTo="Charmeleon", Icon="rbxassetid://121436913614801", Image="rbxassetid://121436913614801" },
	["Charmeleon"] = { Id=5, Rarity="Rare",     Attack=15, HP=18, Type="Fire", Model="005 - Charmeleon", EvolveTo="Charizard", Icon="rbxassetid://100927466566921", Image="rbxassetid://100927466566921" },
	["Charizard"]  = { Id=6, Rarity="Epic",     Attack=22, HP=26, Type="Fire", Model="006 - Charizard",  Icon="rbxassetid://121771857774500", Image="rbxassetid://121771857774500" },

	-- #007-009 Squirtle line
	["Squirtle"]  = { Id=7, Rarity="Uncommon", Attack=11, HP=15, Type="Water", Model="007 - Squirtle", EvolveTo="Wartortle", Icon="rbxassetid://88623806301254", Image="rbxassetid://88623806301254" },
	["Wartortle"] = { Id=8, Rarity="Rare",     Attack=14, HP=20, Type="Water", Model="008 - Wartortle", EvolveTo="Blastoise", Icon="rbxassetid://120381686356356", Image="rbxassetid://120381686356356" },
	["Blastoise"] = { Id=9, Rarity="Epic",     Attack=20, HP=30, Type="Water", Model="009 - Blastoise", Icon="rbxassetid://134654930089233", Image="rbxassetid://134654930089233" },

	-- #010-012 Caterpie line
	["Caterpie"]   = { Id=10, Rarity="Common",   Attack=7,  HP=9,  Type="Bug",    Model="010 - Caterpie", EvolveTo="Metapod", Icon="rbxassetid://104608486929955", Image="rbxassetid://104608486929955" },
	["Metapod"]    = { Id=11, Rarity="Uncommon", Attack=10, HP=14, Type="Bug",    Model="011 - Metapod",  EvolveTo="Butterfree", Icon="rbxassetid://84270961427126", Image="rbxassetid://84270961427126" },
	["Butterfree"] = { Id=12, Rarity="Rare",     Attack=15, HP=18, Type="Bug",    Model="012 - Butterfree", Icon="rbxassetid://118728004248606", Image="rbxassetid://118728004248606" },

	-- #013-015 Weedle line
	["Weedle"]   = { Id=13, Rarity="Common",   Attack=7,  HP=9,  Type="Bug", Model="013 - Weedle", EvolveTo="Kakuna", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Kakuna"]   = { Id=14, Rarity="Uncommon", Attack=10, HP=14, Type="Bug", Model="014 - Kakuna", EvolveTo="Beedrill", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Beedrill"] = { Id=15, Rarity="Rare",     Attack=16, HP=18, Type="Bug", Model="015 - Beedrill", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #016-018 Pidgey line
	["Pidgey"]    = { Id=16, Rarity="Common",   Attack=8,  HP=10, Type="Normal", Model="016 - Pidgey", EvolveTo="Pidgeotto", Icon="rbxassetid://79968359884209", Image="rbxassetid://79968359884209" },
	["Pidgeotto"] = { Id=17, Rarity="Uncommon", Attack=12, HP=16, Type="Normal", Model="017 - Pidgeotto", EvolveTo="Pidgeot", Icon="rbxassetid://118010329073205", Image="rbxassetid://118010329073205" },
	["Pidgeot"]   = { Id=18, Rarity="Rare",     Attack=16, HP=22, Type="Normal", Model="018 - Pidgeot", Icon="rbxassetid://117482560415072", Image="rbxassetid://117482560415072" },

	-- #019-020 Rattata line
	["Rattata"]  = { Id=19, Rarity="Common",   Attack=8,  HP=9,  Type="Normal", Model="019 - Rattata", EvolveTo="Raticate", Icon="rbxassetid://103265419643338", Image="rbxassetid://103265419643338" },
	["Raticate"] = { Id=20, Rarity="Uncommon", Attack=12, HP=16, Type="Normal", Model="020 - Raticate", Icon="rbxassetid://125901990339195", Image="rbxassetid://125901990339195" },

	-- #021-022 Spearow line
	["Spearow"] = { Id=21, Rarity="Common",   Attack=9,  HP=9,  Type="Normal", Model="021 - Spearow", EvolveTo="Fearow", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Fearow"]  = { Id=22, Rarity="Uncommon", Attack=13, HP=16, Type="Normal", Model="022 - Fearow", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #023-024 Ekans line
	["Ekans"] = { Id=23, Rarity="Common",   Attack=9,  HP=10, Type="Poison", Model="023 - Ekans", EvolveTo="Arbok", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Arbok"] = { Id=24, Rarity="Uncommon", Attack=13, HP=17, Type="Poison", Model="024 - Arbok", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #025-026 Pikachu line
	["Pikachu"] = { Id=25, Rarity="Uncommon", Attack=13, HP=12, Type="Electric", Model="025 - Pikachu", EvolveTo="Raichu", Icon="rbxassetid://124567385949746", Image="rbxassetid://124567385949746" },
	["Raichu"]  = { Id=26, Rarity="Rare",     Attack=17, HP=18, Type="Electric", Model="026 - Raichu", Icon="rbxassetid://92110987263227", Image="rbxassetid://92110987263227" },

	-- #027-028 Sandshrew line
	["Sandshrew"] = { Id=27, Rarity="Common",   Attack=9,  HP=12, Type="Ground", Model="027 - Sandshrew", EvolveTo="Sandslash", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Sandslash"] = { Id=28, Rarity="Uncommon", Attack=14, HP=18, Type="Ground", Model="028 - Sandslash", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #029-031 NidoranF line
	["NidoranF"] = { Id=29, Rarity="Common",   Attack=9,  HP=12, Type="Poison", Model="029 - NidoranF", EvolveTo="Nidorina", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Nidorina"] = { Id=30, Rarity="Uncommon", Attack=12, HP=17, Type="Poison", Model="030 - Nidorina", EvolveTo="Nidoqueen", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Nidoqueen"]= { Id=31, Rarity="Rare",     Attack=16, HP=24, Type="Poison", Model="031 - Nidoqueen", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #032-034 NidoranM line
	["NidoranM"] = { Id=32, Rarity="Common",   Attack=10, HP=11, Type="Poison", Model="032 - NidoranM", EvolveTo="Nidorino", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Nidorino"] = { Id=33, Rarity="Uncommon", Attack=13, HP=17, Type="Poison", Model="033 - Nidorino", EvolveTo="Nidoking", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Nidoking"] = { Id=34, Rarity="Rare",     Attack=17, HP=23, Type="Poison", Model="034 - Nidoking", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #035-036 Clefairy line
	["Clefairy"] = { Id=35, Rarity="Uncommon", Attack=11, HP=18, Type="Fairy", Model="035 - Clefairy", EvolveTo="Clefable", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Clefable"] = { Id=36, Rarity="Rare",     Attack=15, HP=24, Type="Fairy", Model="036 - Clefable", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #037-038 Vulpix line
	["Vulpix"]   = { Id=37, Rarity="Common",   Attack=9,  HP=12, Type="Fire", Model="037 - Vulpix", EvolveTo="Ninetales", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Ninetales"]= { Id=38, Rarity="Rare",     Attack=16, HP=23, Type="Fire", Model="038 - Ninetales", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #039-040 Jigglypuff line
	["Jigglypuff"] = { Id=39, Rarity="Common",   Attack=9,  HP=15, Type="Fairy", Model="039 - Jigglypuff", EvolveTo="Wigglytuff", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Wigglytuff"] = { Id=40, Rarity="Rare",     Attack=14, HP=26, Type="Fairy", Model="040 - Wigglytuff", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #041-042 Zubat line
	["Zubat"]  = { Id=41, Rarity="Common",   Attack=8,  HP=10, Type="Poison", Model="041 - Zubat", EvolveTo="Golbat", Icon="rbxassetid://135969606810652", Image="rbxassetid://135969606810652" },
	["Golbat"] = { Id=42, Rarity="Uncommon", Attack=12, HP=17, Type="Poison", Model="042 - Golbat", Icon="rbxassetid://124032175965383", Image="rbxassetid://124032175965383" },

	-- #043-045 Oddish line
	["Oddish"]    = { Id=43, Rarity="Common",   Attack=8,  HP=12, Type="Grass", Model="043 - Oddish", EvolveTo="Gloom", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Gloom"]     = { Id=44, Rarity="Uncommon", Attack=11, HP=17, Type="Grass", Model="044 - Gloom", EvolveTo="Vileplume", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Vileplume"] = { Id=45, Rarity="Rare",     Attack=15, HP=23, Type="Grass", Model="045 - Vileplume", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #046-047 Paras line
	["Paras"]   = { Id=46, Rarity="Common",   Attack=9,  HP=11, Type="Bug", Model="046 - Paras", EvolveTo="Parasect", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Parasect"]= { Id=47, Rarity="Uncommon", Attack=13, HP=18, Type="Bug", Model="047 - Parasect", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #048-049 Venonat line
	["Venonat"] = { Id=48, Rarity="Common",   Attack=8,  HP=12, Type="Bug", Model="048 - Venonat", EvolveTo="Venomoth", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Venomoth"]= { Id=49, Rarity="Uncommon", Attack=12, HP=17, Type="Bug", Model="049 - Venomoth", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #050-051 Diglett line
	["Diglett"] = { Id=50, Rarity="Common",   Attack=10, HP=9,  Type="Ground", Model="050 - Diglett", EvolveTo="Dugtrio", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Dugtrio"] = { Id=51, Rarity="Uncommon", Attack=14, HP=15, Type="Ground", Model="051 - Dugtrio", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #052-053 Meowth line
	["Meowth"]  = { Id=52, Rarity="Uncommon", Attack=11, HP=12, Type="Normal", Model="052 - Meowth", EvolveTo="Persian", Icon="rbxassetid://125524212010581", Image="rbxassetid://125524212010581" },
	["Persian"] = { Id=53, Rarity="Rare",     Attack=14, HP=17, Type="Normal", Model="053 - Persian", Icon="rbxassetid://123983202327080", Image="rbxassetid://123983202327080" },

	-- #054-055 Psyduck line
	["Psyduck"] = { Id=54, Rarity="Common", Attack=10, HP=12, Type="Water", Model="054 - Psyduck", EvolveTo="Golduck", Icon="rbxassetid://126712195495804", Image="rbxassetid://126712195495804" },
	["Golduck"] = { Id=55, Rarity="Rare",   Attack=16, HP=22, Type="Water", Model="055 - Golduck", Icon="rbxassetid://128832364021033", Image="rbxassetid://128832364021033" },

	-- #056-057 Mankey line
	["Mankey"]   = { Id=56, Rarity="Common",   Attack=10, HP=11, Type="Fighting", Model="056 - Mankey", EvolveTo="Primeape", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Primeape"] = { Id=57, Rarity="Uncommon", Attack=14, HP=17, Type="Fighting", Model="057 - Primeape", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #058-059 Growlithe line
	["Growlithe"] = { Id=58, Rarity="Uncommon", Attack=12, HP=14, Type="Fire", Model="058 - Growlithe", EvolveTo="Arcanine", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Arcanine"]  = { Id=59, Rarity="Rare",     Attack=18, HP=24, Type="Fire", Model="059 - Arcanine", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #060-062 Poliwag line
	["Poliwag"]   = { Id=60, Rarity="Common",   Attack=9,  HP=12, Type="Water", Model="060 - Poliwag", EvolveTo="Poliwhirl", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Poliwhirl"] = { Id=61, Rarity="Uncommon", Attack=12, HP=17, Type="Water", Model="061 - Poliwhirl", EvolveTo="Poliwrath", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Poliwrath"] = { Id=62, Rarity="Rare",     Attack=16, HP=24, Type="Water", Model="062 - Poliwrath", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #063-065 Abra line
	["Abra"]     = { Id=63, Rarity="Common",   Attack=10, HP=9,  Type="Psychic", Model="063 - Abra", EvolveTo="Kadabra", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Kadabra"]  = { Id=64, Rarity="Uncommon", Attack=13, HP=14, Type="Psychic", Model="064 - Kadabra", EvolveTo="Alakazam", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Alakazam"] = { Id=65, Rarity="Rare",     Attack=18, HP=18, Type="Psychic", Model="065 - Alakazam", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #066-068 Machop line
	["Machop"]  = { Id=66, Rarity="Common",   Attack=10, HP=12, Type="Fighting", Model="066 - Machop", EvolveTo="Machoke", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Machoke"] = { Id=67, Rarity="Uncommon", Attack=13, HP=17, Type="Fighting", Model="067 - Machoke", EvolveTo="Machamp", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Machamp"] = { Id=68, Rarity="Rare",     Attack=18, HP=24, Type="Fighting", Model="068 - Machamp", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #069-071 Bellsprout line
	["Bellsprout"]  = { Id=69, Rarity="Common",   Attack=9,  HP=11, Type="Grass", Model="069 - Bellsprout", EvolveTo="Weepinbell", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Weepinbell"]  = { Id=70, Rarity="Uncommon", Attack=12, HP=16, Type="Grass", Model="070 - Weepinbell", EvolveTo="Victreebel", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Victreebel"]  = { Id=71, Rarity="Rare",     Attack=16, HP=22, Type="Grass", Model="071 - Victreebel", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #072-073 Tentacool line
	["Tentacool"]  = { Id=72, Rarity="Common", Attack=9,  HP=12, Type="Water", Model="072 - Tentacool", EvolveTo="Tentacruel", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Tentacruel"] = { Id=73, Rarity="Rare",   Attack=15, HP=24, Type="Water", Model="073 - Tentacruel", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #074-076 Geodude line
	["Geodude"]  = { Id=74, Rarity="Common",   Attack=10, HP=12, Type="Rock", Model="074 - Geodude", EvolveTo="Graveler", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Graveler"] = { Id=75, Rarity="Uncommon", Attack=13, HP=17, Type="Rock", Model="075 - Graveler", EvolveTo="Golem", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Golem"]    = { Id=76, Rarity="Rare",     Attack=17, HP=24, Type="Rock", Model="076 - Golem", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #077-078 Ponyta line
	["Ponyta"]   = { Id=77, Rarity="Common",   Attack=10, HP=11, Type="Fire", Model="077 - Ponyta", EvolveTo="Rapidash", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Rapidash"] = { Id=78, Rarity="Uncommon", Attack=13, HP=17, Type="Fire", Model="078 - Rapidash", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #079-080 Slowpoke line
	["Slowpoke"] = { Id=79, Rarity="Common", Attack=8,  HP=15, Type="Water", Model="079 - Slowpoke", EvolveTo="Slowbro", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Slowbro"]  = { Id=80, Rarity="Rare",   Attack=14, HP=26, Type="Water", Model="080 - Slowbro", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #081-082 Magnemite line
	["Magnemite"] = { Id=81, Rarity="Common",   Attack=9,  HP=11, Type="Electric", Model="081 - Magnemite", EvolveTo="Magneton", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Magneton"]  = { Id=82, Rarity="Rare",     Attack=15, HP=18, Type="Electric", Model="082 - Magneton", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #083 Farfetch'd
	["Farfetch'd"] = { Id=83, Rarity="Uncommon", Attack=12, HP=15, Type="Normal", Model="083 - Farfetch'd", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #084-085 Doduo line
	["Doduo"]  = { Id=84, Rarity="Common",   Attack=10, HP=11, Type="Normal", Model="084 - Doduo", EvolveTo="Dodrio", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Dodrio"] = { Id=85, Rarity="Uncommon", Attack=14, HP=17, Type="Normal", Model="085 - Dodrio", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #086-087 Seel line
	["Seel"]    = { Id=86, Rarity="Common",   Attack=9,  HP=13, Type="Water", Model="086 - Seel", EvolveTo="Dewgong", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Dewgong"] = { Id=87, Rarity="Uncommon", Attack=12, HP=19, Type="Water", Model="087 - Dewgong", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #088-089 Grimer line
	["Grimer"] = { Id=88, Rarity="Common",   Attack=9,  HP=14, Type="Poison", Model="088 - Grimer", EvolveTo="Muk", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Muk"]    = { Id=89, Rarity="Uncommon", Attack=13, HP=20, Type="Poison", Model="089 - Muk", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #090-091 Shellder line
	["Shellder"] = { Id=90, Rarity="Common", Attack=9,  HP=11, Type="Water", Model="090 - Shellder", EvolveTo="Cloyster", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Cloyster"] = { Id=91, Rarity="Rare",   Attack=16, HP=20, Type="Water", Model="091 - Cloyster", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #092-094 Gastly line
	["Gastly"]  = { Id=92, Rarity="Uncommon", Attack=12, HP=12, Type="Ghost", Model="092 - Gastly", EvolveTo="Haunter", Icon="rbxassetid://70628851155055", Image="rbxassetid://70628851155055" },
	["Haunter"] = { Id=93, Rarity="Rare",     Attack=15, HP=16, Type="Ghost", Model="093 - Haunter", EvolveTo="Gengar", Icon="rbxassetid://76183676056817", Image="rbxassetid://76183676056817" },
	["Gengar"]  = { Id=94, Rarity="Rare",     Attack=18, HP=20, Type="Ghost", Model="094 - Gengar", Icon="rbxassetid://73487593240517", Image="rbxassetid://73487593240517" },

	-- #095 Onix
	["Onix"] = { Id=95, Rarity="Uncommon", Attack=12, HP=19, Type="Rock", Model="095 - Onix", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #096-097 Drowzee line
	["Drowzee"] = { Id=96, Rarity="Common",   Attack=9,  HP=13, Type="Psychic", Model="096 - Drowzee", EvolveTo="Hypno", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Hypno"]   = { Id=97, Rarity="Uncommon", Attack=13, HP=19, Type="Psychic", Model="097 - Hypno", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #098-099 Krabby line
	["Krabby"]  = { Id=98, Rarity="Common",   Attack=10, HP=11, Type="Water", Model="098 - Krabby", EvolveTo="Kingler", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Kingler"] = { Id=99, Rarity="Uncommon", Attack=14, HP=18, Type="Water", Model="099 - Kingler", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #100-101 Voltorb line
	["Voltorb"]  = { Id=100, Rarity="Common",   Attack=9,  HP=11, Type="Electric", Model="100 - Voltorb", EvolveTo="Electrode", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Electrode"]= { Id=101, Rarity="Uncommon", Attack=12, HP=17, Type="Electric", Model="101 - Electrode", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #102-103 Exeggcute line
	["Exeggcute"] = { Id=102, Rarity="Common", Attack=9,  HP=13, Type="Grass", Model="102 - Exeggcute", EvolveTo="Exeggutor", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Exeggutor"] = { Id=103, Rarity="Rare",   Attack=16, HP=24, Type="Grass", Model="103 - Exeggutor", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #104-105 Cubone line
	["Cubone"]  = { Id=104, Rarity="Common",   Attack=10, HP=13, Type="Ground", Model="104 - Cubone", EvolveTo="Marowak", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Marowak"] = { Id=105, Rarity="Uncommon", Attack=13, HP=19, Type="Ground", Model="105 - Marowak", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #106-107 Hitmons
	["Hitmonlee"]  = { Id=106, Rarity="Rare", Attack=18, HP=20, Type="Fighting", Model="106 - Hitmonlee", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Hitmonchan"] = { Id=107, Rarity="Rare", Attack=16, HP=22, Type="Fighting", Model="107 - Hitmonchan", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #108 Lickitung
	["Lickitung"] = { Id=108, Rarity="Uncommon", Attack=12, HP=20, Type="Normal", Model="108 - Lickitung", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #109-110 Koffing line
	["Koffing"] = { Id=109, Rarity="Common",   Attack=9,  HP=13, Type="Poison", Model="109 - Koffing", EvolveTo="Weezing", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Weezing"] = { Id=110, Rarity="Uncommon", Attack=13, HP=19, Type="Poison", Model="110 - Weezing", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #111-112 Rhyhorn line
	["Rhyhorn"] = { Id=111, Rarity="Uncommon", Attack=12, HP=18, Type="Ground", Model="111 - Rhyhorn", EvolveTo="Rhydon", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Rhydon"]  = { Id=112, Rarity="Rare",     Attack=17, HP=25, Type="Ground", Model="112 - Rhydon", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #113 Chansey
	["Chansey"] = { Id=113, Rarity="Rare", Attack=14, HP=26, Type="Normal", Model="113 - Chansey", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #114 Tangela
	["Tangela"] = { Id=114, Rarity="Uncommon", Attack=12, HP=19, Type="Grass", Model="114 - Tangela", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #115 Kangaskhan
	["Kangaskhan"] = { Id=115, Rarity="Rare", Attack=16, HP=26, Type="Normal", Model="115 - Kangaskhan", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #116-117 Horsea line
	["Horsea"] = { Id=116, Rarity="Common",   Attack=9,  HP=11, Type="Water", Model="116 - Horsea", EvolveTo="Seadra", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Seadra"] = { Id=117, Rarity="Uncommon", Attack=12, HP=17, Type="Water", Model="117 - Seadra", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #118-119 Goldeen line
	["Goldeen"] = { Id=118, Rarity="Common",   Attack=9,  HP=12, Type="Water", Model="118 - Goldeen", EvolveTo="Seaking", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Seaking"] = { Id=119, Rarity="Uncommon", Attack=12, HP=18, Type="Water", Model="119 - Seaking", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #120-121 Staryu line
	["Staryu"]  = { Id=120, Rarity="Common", Attack=10, HP=11, Type="Water", Model="120 - Staryu", EvolveTo="Starmie", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Starmie"] = { Id=121, Rarity="Rare",   Attack=16, HP=20, Type="Water", Model="121 - Starmie", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #122-128 specials
	["Mr. Mime"] = { Id=122, Rarity="Rare", Attack=15, HP=22, Type="Psychic", Model="122 - Mr. Mime", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Scyther"]  = { Id=123, Rarity="Rare", Attack=18, HP=20, Type="Bug",     Model="123 - Scyther", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Jynx"]     = { Id=124, Rarity="Rare", Attack=16, HP=20, Type="Ice",     Model="124 - Jynx", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Electabuzz"]= { Id=125, Rarity="Rare", Attack=17, HP=20, Type="Electric", Model="125 - Electabuzz", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Magmar"]   = { Id=126, Rarity="Rare", Attack=17, HP=20, Type="Fire",    Model="126 - Magmar", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Pinsir"]   = { Id=127, Rarity="Rare", Attack=17, HP=22, Type="Bug",     Model="127 - Pinsir", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Tauros"]   = { Id=128, Rarity="Rare", Attack=16, HP=24, Type="Normal",  Model="128 - Tauros", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #129-130 Magikarp line
	["Magikarp"] = { Id=129, Rarity="Common", Attack=6,  HP=10, Type="Water", Model="129 - Magikarp", EvolveTo="Gyarados", Icon="rbxassetid://102675286979211", Image="rbxassetid://102675286979211" },
	["Gyarados"] = { Id=130, Rarity="Rare",   Attack=19, HP=26, Type="Water", Model="130 - Gyarados", Icon="rbxassetid://121398576898364", Image="rbxassetid://121398576898364" },

	-- #131 Lapras
	["Lapras"] = { Id=131, Rarity="Rare", Attack=16, HP=26, Type="Water", Model="131 - Lapras", Icon="rbxassetid://90620155620612", Image="rbxassetid://90620155620612" },

	-- #132 Ditto (REMOVED)
	-- #133-136 Eevee line (REMOVED)

	-- #137 Porygon
	["Porygon"] = { Id=137, Rarity="Rare", Attack=14, HP=20, Type="Normal", Model="137 - Porygon", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #138-141 Fossils
	["Omanyte"] = { Id=138, Rarity="Uncommon", Attack=12, HP=16, Type="Rock", Model="138 - Omanyte", EvolveTo="Omastar", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Omastar"] = { Id=139, Rarity="Rare",     Attack=16, HP=24, Type="Rock", Model="139 - Omastar", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Kabuto"]  = { Id=140, Rarity="Uncommon", Attack=12, HP=16, Type="Rock", Model="140 - Kabuto", EvolveTo="Kabutops", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Kabutops"]= { Id=141, Rarity="Rare",     Attack=18, HP=22, Type="Rock", Model="141 - Kabutops", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #142 Aerodactyl
	["Aerodactyl"] = { Id=142, Rarity="Rare", Attack=19, HP=22, Type="Rock", Model="142 - Aerodactyl", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #143 Snorlax
	["Snorlax"] = { Id=143, Rarity="Rare", Attack=15, HP=26, Type="Normal", Model="143 - Snorlax", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #144-146 Legendary birds
	["Articuno"] = { Id=144, Rarity="Legend", Attack=25, HP=34, Type="Ice",      Model="144 - Articuno", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Zapdos"]   = { Id=145, Rarity="Legend", Attack=26, HP=32, Type="Electric", Model="145 - Zapdos",   Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Moltres"]  = { Id=146, Rarity="Legend", Attack=26, HP=32, Type="Fire",     Model="146 - Moltres",  Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- #147-149 Dratini line (Pseudo => Divine final)
	["Dratini"]   = { Id=147, Rarity="Uncommon", Attack=12, HP=14, Type="Dragon", Model="147 - Dratini", EvolveTo="Dragonair", Icon="rbxassetid://129382301073001", Image="rbxassetid://129382301073001" },
	["Dragonair"] = { Id=148, Rarity="Rare",     Attack=15, HP=20, Type="Dragon", Model="148 - Dragonair", EvolveTo="Dragonite", Icon="rbxassetid://121255668090770", Image="rbxassetid://121255668090770" },
	["Dragonite"] = { Id=149, Rarity="Divine",   Attack=23, HP=32, Type="Dragon", Model="149 - Dragonite", Icon="rbxassetid://121255668090770", Image="rbxassetid://121255668090770" },

	-- #150-151 Mewtwo + Mew (Divine ห้ามใช้กับ Mew ตามที่ขอ -> ให้เป็น Legend)
	["Mewtwo"] = { Id=150, Rarity="Legend", Attack=27, HP=36, Type="Psychic", Model="150 - Mewtwo", Icon="rbxassetid://140657668203910", Image="rbxassetid://140657668203910" },
	["Mew"]    = { Id=151, Rarity="Legend", Attack=24, HP=32, Type="Psychic", Model="151 - Mew",    Icon="rbxassetid://0", Image="rbxassetid://0" },

	--================================================================================
	-- GEN 3+ (ที่คุณมีในไฟล์เดิม) ✅ คงไว้ + ปรับบาลานซ์รายตัว
	--================================================================================

	-- GEN 3
	["Treecko"] = { Id=252, Rarity="Uncommon", Attack=12, HP=13, Type="Grass", Model="252 - Treecko", EvolveTo="Grovyle", Icon="rbxassetid://77427423767316", Image="rbxassetid://77427423767316" },
	["Grovyle"] = { Id=253, Rarity="Rare",     Attack=15, HP=18, Type="Grass", Model="253 - Grovyle", EvolveTo="Sceptile", Icon="rbxassetid://124309669203410", Image="rbxassetid://124309669203410" },
	["Sceptile"]= { Id=254, Rarity="Rare",     Attack=18, HP=22, Type="Grass", Model="254 - Sceptile", Icon="rbxassetid://101625010299924", Image="rbxassetid://101625010299924" },

	["Torchic"]   = { Id=255, Rarity="Uncommon", Attack=12, HP=12, Type="Fire", Model="255 - Torchic", EvolveTo="Combusken", Icon="rbxassetid://134722738127378", Image="rbxassetid://134722738127378" },
	["Combusken"] = { Id=256, Rarity="Rare",     Attack=15, HP=17, Type="Fire", Model="256 - Combusken", EvolveTo="Blaziken", Icon="rbxassetid://138557250718542", Image="rbxassetid://138557250718542" },
	["Blaziken"]  = { Id=257, Rarity="Rare",     Attack=19, HP=22, Type="Fire", Model="257 - Blaziken", Icon="rbxassetid://116477204045832", Image="rbxassetid://116477204045832" },

	["Mudkip"]    = { Id=258, Rarity="Uncommon", Attack=11, HP=15, Type="Water", Model="258 - Mudkip", EvolveTo="Marshtomp", Icon="rbxassetid://100021812634842", Image="rbxassetid://100021812634842" },
	["Marshtomp"] = { Id=259, Rarity="Rare",     Attack=14, HP=20, Type="Water", Model="259 - Marshtomp", EvolveTo="Swampert", Icon="rbxassetid://86400581791610", Image="rbxassetid://86400581791610" },
	["Swampert"]  = { Id=260, Rarity="Rare",     Attack=18, HP=26, Type="Water", Model="260 - Swampert", Icon="rbxassetid://77088904470441", Image="rbxassetid://77088904470441" },

	["Ralts"]     = { Id=280, Rarity="Uncommon", Attack=11, HP=12, Type="Psychic", Model="280 - Ralts", EvolveTo="Kirlia", Icon="rbxassetid://140515787121102", Image="rbxassetid://140515787121102" },
	["Kirlia"]    = { Id=281, Rarity="Rare",     Attack=14, HP=17, Type="Psychic", Model="281 - Kirlia", EvolveTo="Gardevoir", Icon="rbxassetid://89729947355098", Image="rbxassetid://89729947355098" },
	["Gardevoir"] = { Id=282, Rarity="Rare",     Attack=18, HP=22, Type="Psychic", Model="282 - Gardevoir", Icon="rbxassetid://137706749143481", Image="rbxassetid://137706749143481" },

	["Beldum"]    = { Id=374, Rarity="Uncommon", Attack=12, HP=16, Type="Steel", Model="374 - Beldum", EvolveTo="Metang", Icon="rbxassetid://81670992056922", Image="rbxassetid://81670992056922" },
	["Metang"]    = { Id=375, Rarity="Rare",     Attack=15, HP=22, Type="Steel", Model="375 - Metang", EvolveTo="Metagross", Icon="rbxassetid://130088362064615", Image="rbxassetid://130088362064615" },
	["Metagross"] = { Id=376, Rarity="Divine",   Attack=22, HP=32, Type="Steel", Model="376 - Metagross", Icon="rbxassetid://122380520580963", Image="rbxassetid://122380520580963" },

	-- GEN 4
	["Turtwig"]  = { Id=387, Rarity="Uncommon", Attack=11, HP=15, Type="Grass", Model="387 - Turtwig", EvolveTo="Grotle", Icon="rbxassetid://71071979111881", Image="rbxassetid://71071979111881" },
	["Grotle"]   = { Id=388, Rarity="Rare",     Attack=14, HP=20, Type="Grass", Model="388 - Grotle", EvolveTo="Torterra", Icon="rbxassetid://130619327200511", Image="rbxassetid://130619327200511" },
	["Torterra"] = { Id=389, Rarity="Rare",     Attack=18, HP=26, Type="Grass", Model="389 - Torterra", Icon="rbxassetid://131467317357548", Image="rbxassetid://131467317357548" },

	["Chimchar"]  = { Id=390, Rarity="Uncommon", Attack=12, HP=12, Type="Fire", Model="390 - Chimchar", EvolveTo="Monferno", Icon="rbxassetid://94161775033579", Image="rbxassetid://94161775033579" },
	-- เหตุผลที่ Infernape เป็น Rare: เป็น final evo starter -> อยู่ชั้นเดียวกับ final evo ปกติ ไม่ชน pseudo/legend
	["Monferno"]  = { Id=391, Rarity="Rare",     Attack=15, HP=17, Type="Fire", Model="391 - Monferno", EvolveTo="Infernape", Icon="rbxassetid://77951844859229", Image="rbxassetid://77951844859229" },
	["Infernape"] = { Id=392, Rarity="Rare",     Attack=19, HP=22, Type="Fire", Model="392 - Infernape", Icon="rbxassetid://85398480998557", Image="rbxassetid://85398480998557" },

	["Piplup"]   = { Id=393, Rarity="Uncommon", Attack=11, HP=14, Type="Water", Model="393 - Piplup", EvolveTo="Prinplup", Icon="rbxassetid://108986699929048", Image="rbxassetid://108986699929048" },
	["Prinplup"] = { Id=394, Rarity="Rare",     Attack=14, HP=19, Type="Water", Model="394 - Prinplup", EvolveTo="Empoleon", Icon="rbxassetid://80912630264598", Image="rbxassetid://80912630264598" },
	["Empoleon"] = { Id=395, Rarity="Rare",     Attack=18, HP=26, Type="Water", Model="395 - Empoleon", Icon="rbxassetid://90435442302767", Image="rbxassetid://90435442302767" },

	["Bidoof"]  = { Id=399, Rarity="Common",   Attack=7,  HP=10, Type="Normal", Model="399 - Bidoof", EvolveTo="Bibarel", Icon="rbxassetid://88041120791602", Image="rbxassetid://88041120791602" },
	["Bibarel"] = { Id=400, Rarity="Uncommon", Attack=12, HP=18, Type="Normal", Model="400 - Bibarel", Icon="rbxassetid://79576768503406", Image="rbxassetid://79576768503406" },

	["Gible"]    = { Id=443, Rarity="Uncommon", Attack=12, HP=16, Type="Dragon", Model="443 - Gible", EvolveTo="Gabite", Icon="rbxassetid://102990550229282", Image="rbxassetid://102990550229282" },
	["Gabite"]   = { Id=444, Rarity="Rare",     Attack=15, HP=22, Type="Dragon", Model="444 - Gabite", EvolveTo="Garchomp", Icon="rbxassetid://90858868001482", Image="rbxassetid://90858868001482" },
	["Garchomp"] = { Id=445, Rarity="Divine",   Attack=23, HP=32, Type="Dragon", Model="445 - Garchomp", Icon="rbxassetid://78500346251469", Image="rbxassetid://78500346251469" },

	-- GEN 5
	["Ferroseed"]  = { Id=597, Rarity="Uncommon", Attack=11, HP=16, Type="Grass", Model="597 - Ferroseed", EvolveTo="Ferrothorn", Icon="rbxassetid://128079895836937", Image="rbxassetid://128079895836937" },
	["Ferrothorn"] = { Id=598, Rarity="Rare",     Attack=15, HP=26, Type="Grass", Model="598 - Ferrothorn", Icon="rbxassetid://88295237814419", Image="rbxassetid://88295237814419" },

	["Litwick"]  = { Id=607, Rarity="Uncommon", Attack=12, HP=12, Type="Ghost", Model="607 - Litwick", EvolveTo="Lampent", Icon="rbxassetid://130744569715962", Image="rbxassetid://130744569715962" },
	["Lampent"]  = { Id=608, Rarity="Rare",     Attack=15, HP=17, Type="Ghost", Model="608 - Lampent", EvolveTo="Chandelure", Icon="rbxassetid://72361105976188", Image="rbxassetid://72361105976188" },
	["Chandelure"] = { Id=609, Rarity="Rare",   Attack=19, HP=22, Type="Ghost", Model="609 - Chandelure", Icon="rbxassetid://0", Image="rbxassetid://0" },

	-- GEN 9
	["Sprigatito"] = { Id=906, Rarity="Uncommon", Attack=12, HP=13, Type="Grass", Model="906 - Sprigatito", EvolveTo="Floragato", Icon="rbxassetid://99267429164006", Image="rbxassetid://99267429164006" },
	["Floragato"]  = { Id=907, Rarity="Rare",     Attack=15, HP=18, Type="Grass", Model="907 - Floragato", EvolveTo="Meowscarada", Icon="rbxassetid://119093547471933", Image="rbxassetid://119093547471933" },
	["Meowscarada"]= { Id=908, Rarity="Rare",     Attack=19, HP=22, Type="Grass", Model="908 - Meowscarada", Icon="rbxassetid://76132205154349", Image="rbxassetid://76132205154349" },

	["Fuecoco"]   = { Id=909, Rarity="Uncommon", Attack=12, HP=15, Type="Fire", Model="909 - Fuecoco", EvolveTo="Crocalor", Icon="rbxassetid://100643239328472", Image="rbxassetid://100643239328472" },
	["Crocalor"]  = { Id=910, Rarity="Rare",     Attack=15, HP=20, Type="Fire", Model="910 - Crocalor", EvolveTo="Skeledirge", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Skeledirge"] = { Id=911, Rarity="Rare",    Attack=18, HP=26, Type="Fire", Model="911 - Skeledirge", Icon="rbxassetid://133636351324480", Image="rbxassetid://133636351324480" },

	["Quaxly"]    = { Id=912, Rarity="Uncommon", Attack=12, HP=14, Type="Water", Model="912 - Quaxly", EvolveTo="Quaxwell", Icon="rbxassetid://139219172128335", Image="rbxassetid://139219172128335" },
	["Quaxwell"]  = { Id=913, Rarity="Rare",     Attack=15, HP=19, Type="Water", Model="913 - Quaxwell", EvolveTo="Quaquaval", Icon="rbxassetid://81551061112201", Image="rbxassetid://81551061112201" },
	["Quaquaval"] = { Id=914, Rarity="Rare",     Attack=19, HP=24, Type="Water", Model="914 - Quaquaval", Icon="rbxassetid://108393314003706", Image="rbxassetid://108393314003706" },

	-- Cyclizar (Gen9)
	["Cyclizar"] = { Id=967, Rarity="Rare", Attack=16, HP=22, Type="Dragon", Model="967 - Cyclizar", Icon="rbxassetid://0", Image="rbxassetid://0" },
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

	local roll = math.random(1, 100)
	local cumulative = 0
	local selectedRarity = "Common"

	local order = {"Common", "Uncommon", "Rare", "Epic", "Divine", "Legend"}
	for _, rarity in ipairs(order) do
		local chance = rates[rarity] or 0
		cumulative = cumulative + chance
		if roll <= cumulative then
			selectedRarity = rarity
			break
		end
	end

	local pool = PokemonDB.GetByRarity(selectedRarity)
	if #pool == 0 then
		warn("⚠️ No pokemon found for rarity: " .. selectedRarity .. ". Trying fallback.")
		pool = PokemonDB.GetByRarity("Common")
	end

	if #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

-- New Helper: Get Random Single Pokemon by Rarity
function PokemonDB.GetRandomByRarity(rarity)
	local pool = PokemonDB.GetByRarity(rarity)
	if #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

function PokemonDB.GetPokemon(name) return PokemonDB.Pokemon[name] end
function PokemonDB.GetCatchDifficulty(name)
	local p = PokemonDB.Pokemon[name]
	return p and PokemonDB.RarityDifficulty[p.Rarity] or 2
end

PokemonDB.Starters = {
	-- ✅ ลบ Gen2 + ลบ Eevee แล้ว
	"Bulbasaur", "Charmander", "Squirtle",
	"Pikachu", "Gastly", "Dratini", "Meowth"
}

function PokemonDB.GetRandomEncounter()
	local all = {}
	for n, d in pairs(PokemonDB.Pokemon) do
		table.insert(all, {Name=n, Data=d})
	end
	return all[math.random(1, #all)]
end

return PokemonDB

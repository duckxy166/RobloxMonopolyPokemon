--================================================================================
--                      💾 POKEMON DATABASE - FILTERED BY IMAGES
--================================================================================

local PokemonDB = {}

-- Rarity Hierarchy:
-- [Common]   = ร่าง 1 ทั่วไป / หนอน
-- [Uncommon] = ร่าง 1 เก่ง / ร่าง 2 ทั่วไป
-- [Rare]     = ร่าง 2 ตัวเทพ / ร่าง 3 มอนป่า
-- [Epic]     = ร่าง 3 (Starter / สายโหด)
-- [Divine]   = Pseudo Legendaries (4 เทพ)
-- [Legend]   = True Legendaries

PokemonDB.RarityDifficulty = {
	["Common"]   = 1,
	["Uncommon"] = 2,
	["Rare"]     = 3,
	["Epic"]     = 4,
	["Divine"]   = 5,
	["Legend"]   = 6
}

PokemonDB.EncounterRates = {
	["Bright green"] = { Common = 65, Uncommon = 30, Rare = 5,  Epic = 0, Divine = 0, Legend = 0 },
	["Forest green"] = { Common = 40, Uncommon = 40, Rare = 18, Epic = 2, Divine = 0, Legend = 0 },
	["Dark green"]   = { Common = 18, Uncommon = 35, Rare = 40, Epic = 5, Divine = 2, Legend = 0 },
	["Earth green"]  = { Common = 6,  Uncommon = 16, Rare = 50, Epic = 22, Divine = 6, Legend = 0 },
	["Gold"]         = { Common = 0,  Uncommon = 0,  Rare = 0,  Epic = 0,  Divine = 0, Legend = 100 },
	["Default"]      = { Common = 80, Uncommon = 15, Rare = 5,  Epic = 0,  Divine = 0, Legend = 0 }
}

PokemonDB.Pokemon = {
	--================================================================================
	-- GEN 1 (FILTERED)
	--================================================================================
	["Bulbasaur"] = { Id=1, Rarity="Uncommon", Attack=11, HP=15, Type="Grass", Model="001 - Bulbasaur", EvolveTo="Ivysaur", Icon="rbxassetid://114311723585803", Image="rbxassetid://114311723585803" },
	["Ivysaur"]   = { Id=2, Rarity="Rare",     Attack=16, HP=22, Type="Grass", Model="002 - Ivysaur",   EvolveTo="Venusaur", Icon="rbxassetid://108266117261837", Image="rbxassetid://108266117261837" },
	["Venusaur"]  = { Id=3, Rarity="Epic",     Attack=22, HP=34, Type="Grass", Model="003 - Venusaur",  Icon="rbxassetid://136798929875157", Image="rbxassetid://136798929875157" },

	["Charmander"] = { Id=4, Rarity="Uncommon", Attack=13, HP=12, Type="Fire", Model="004 - Charmander", EvolveTo="Charmeleon", Icon="rbxassetid://121436913614801", Image="rbxassetid://121436913614801" },
	["Charmeleon"] = { Id=5, Rarity="Rare",     Attack=17, HP=18, Type="Fire", Model="005 - Charmeleon", EvolveTo="Charizard", Icon="rbxassetid://100927466566921", Image="rbxassetid://100927466566921" },
	["Charizard"]  = { Id=6, Rarity="Epic",     Attack=26, HP=26, Type="Fire", Model="006 - Charizard",  Icon="rbxassetid://121771857774500", Image="rbxassetid://121771857774500" },

	["Squirtle"]  = { Id=7, Rarity="Uncommon", Attack=11, HP=16, Type="Water", Model="007 - Squirtle", EvolveTo="Wartortle", Icon="rbxassetid://88623806301254", Image="rbxassetid://88623806301254" },
	["Wartortle"] = { Id=8, Rarity="Rare",     Attack=15, HP=24, Type="Water", Model="008 - Wartortle", EvolveTo="Blastoise", Icon="rbxassetid://120381686356356", Image="rbxassetid://120381686356356" },
	["Blastoise"] = { Id=9, Rarity="Epic",     Attack=21, HP=36, Type="Water", Model="009 - Blastoise", Icon="rbxassetid://134654930089233", Image="rbxassetid://134654930089233" },

	["Caterpie"]   = { Id=10, Rarity="Common",   Attack=6,  HP=9,  Type="Bug", Model="010 - Caterpie", EvolveTo="Metapod", Icon="rbxassetid://104608486929955", Image="rbxassetid://104608486929955" },
	["Metapod"]    = { Id=11, Rarity="Uncommon", Attack=5,  HP=18, Type="Bug", Model="011 - Metapod",  EvolveTo="Butterfree", Icon="rbxassetid://84270961427126", Image="rbxassetid://84270961427126" },
	["Butterfree"] = { Id=12, Rarity="Rare",     Attack=15, HP=20, Type="Bug", Model="012 - Butterfree", Icon="rbxassetid://118728004248606", Image="rbxassetid://118728004248606" },

	["Weedle"]   = { Id=13, Rarity="Common",   Attack=7,  HP=9,  Type="Bug", Model="013 - Weedle", EvolveTo="Kakuna", Icon="rbxassetid://98265220558629", Image="rbxassetid://98265220558629" },
	["Kakuna"]   = { Id=14, Rarity="Uncommon", Attack=6,  HP=17, Type="Bug", Model="014 - Kakuna", EvolveTo="Beedrill", Icon="rbxassetid://80590740820140", Image="rbxassetid://80590740820140" },
	["Beedrill"] = { Id=15, Rarity="Rare",     Attack=18, HP=18, Type="Bug", Model="015 - Beedrill", Icon="rbxassetid://111084090769636", Image="rbxassetid://111084090769636" },

	["Pidgey"]    = { Id=16, Rarity="Common",   Attack=9,  HP=10, Type="Normal", Model="016 - Pidgey", EvolveTo="Pidgeotto", Icon="rbxassetid://79968359884209", Image="rbxassetid://79968359884209" },
	["Pidgeotto"] = { Id=17, Rarity="Uncommon", Attack=13, HP=16, Type="Normal", Model="017 - Pidgeotto", EvolveTo="Pidgeot", Icon="rbxassetid://118010329073205", Image="rbxassetid://118010329073205" },
	["Pidgeot"]   = { Id=18, Rarity="Rare",     Attack=18, HP=24, Type="Normal", Model="018 - Pidgeot", Icon="rbxassetid://117482560415072", Image="rbxassetid://117482560415072" },

	["Rattata"]  = { Id=19, Rarity="Common",   Attack=9,  HP=9,  Type="Normal", Model="019 - Rattata", EvolveTo="Raticate", Icon="rbxassetid://103265419643338", Image="rbxassetid://103265419643338" },
	["Raticate"] = { Id=20, Rarity="Uncommon", Attack=15, HP=16, Type="Normal", Model="020 - Raticate", Icon="rbxassetid://125901990339195", Image="rbxassetid://125901990339195" },

	["Spearow"] = { Id=21, Rarity="Common",   Attack=10, HP=9,  Type="Normal", Model="021 - Spearow", EvolveTo="Fearow", Icon="rbxassetid://135990520008313", Image="rbxassetid://135990520008313" },
	["Fearow"]  = { Id=22, Rarity="Uncommon", Attack=16, HP=18, Type="Normal", Model="022 - Fearow", Icon="rbxassetid://98705714923276", Image="rbxassetid://98705714923276" },

	["Ekans"] = { Id=23, Rarity="Common",   Attack=10, HP=11, Type="Poison", Model="023 - Ekans", EvolveTo="Arbok", Icon="rbxassetid://132913693212373", Image="rbxassetid://132913693212373" },
	["Arbok"] = { Id=24, Rarity="Uncommon", Attack=14, HP=19, Type="Poison", Model="024 - Arbok", Icon="rbxassetid://87473610305805", Image="rbxassetid://87473610305805" },

	["Pikachu"] = { Id=25, Rarity="Uncommon", Attack=14, HP=12, Type="Electric", Model="025 - Pikachu", EvolveTo="Raichu", Icon="rbxassetid://124567385949746", Image="rbxassetid://124567385949746" },
	["Raichu"]  = { Id=26, Rarity="Rare",     Attack=19, HP=19, Type="Electric", Model="026 - Raichu", Icon="rbxassetid://92110987263227", Image="rbxassetid://92110987263227" },

	["Sandshrew"] = { Id=27, Rarity="Common",   Attack=10, HP=13, Type="Ground", Model="027 - Sandshrew", EvolveTo="Sandslash", Icon="rbxassetid://95341789232342", Image="rbxassetid://95341789232342" },
	["Sandslash"] = { Id=28, Rarity="Uncommon", Attack=15, HP=20, Type="Ground", Model="028 - Sandslash", Icon="rbxassetid://73311045277116", Image="rbxassetid://73311045277116" },

	["NidoranF"]  = { Id=29, Rarity="Common",   Attack=9,  HP=13, Type="Poison", Model="029 - NidoranF", EvolveTo="Nidorina", Icon="rbxassetid://119638951347635", Image="rbxassetid://119638951347635" },
	["Nidorina"]  = { Id=30, Rarity="Uncommon", Attack=13, HP=18, Type="Poison", Model="030 - Nidorina", EvolveTo="Nidoqueen", Icon="rbxassetid://114529166574966", Image="rbxassetid://114529166574966" },
	["Nidoqueen"] = { Id=31, Rarity="Epic",     Attack=19, HP=30, Type="Poison", Model="031 - Nidoqueen", Icon="rbxassetid://100153511329577", Image="rbxassetid://100153511329577" },

	["NidoranM"] = { Id=32, Rarity="Common",   Attack=10, HP=11, Type="Poison", Model="032 - NidoranM", EvolveTo="Nidorino", Icon="rbxassetid://121872069158809", Image="rbxassetid://121872069158809" },
	["Nidorino"] = { Id=33, Rarity="Uncommon", Attack=14, HP=16, Type="Poison", Model="033 - Nidorino", EvolveTo="Nidoking", Icon="rbxassetid://123995774974835", Image="rbxassetid://123995774974835" },
	["Nidoking"] = { Id=34, Rarity="Epic",     Attack=21, HP=25, Type="Poison", Model="034 - Nidoking", Icon="rbxassetid://122238906916863", Image="rbxassetid://122238906916863" },

	["Clefairy"] = { Id=35, Rarity="Uncommon", Attack=10, HP=20, Type="Fairy", Model="035 - Clefairy", EvolveTo="Clefable", Icon="rbxassetid://80546831748574", Image="rbxassetid://80546831748574" },
	["Clefable"] = { Id=36, Rarity="Rare",     Attack=15, HP=28, Type="Fairy", Model="036 - Clefable", Icon="rbxassetid://82059686065561", Image="rbxassetid://82059686065561" },

	["Vulpix"]    = { Id=37, Rarity="Common",   Attack=10, HP=11, Type="Fire", Model="037 - Vulpix", EvolveTo="Ninetales", Icon="rbxassetid://92853818783105", Image="rbxassetid://92853818783105" },
	["Ninetales"] = { Id=38, Rarity="Rare",     Attack=16, HP=22, Type="Fire", Model="038 - Ninetales", Icon="rbxassetid://81264957610321", Image="rbxassetid://81264957610321" },

	["Jigglypuff"] = { Id=39, Rarity="Common",   Attack=8,  HP=18, Type="Fairy", Model="039 - Jigglypuff", EvolveTo="Wigglytuff", Icon="rbxassetid://108702788831480", Image="rbxassetid://108702788831480" },
	["Wigglytuff"] = { Id=40, Rarity="Rare",     Attack=13, HP=32, Type="Fairy", Model="040 - Wigglytuff", Icon="rbxassetid://132553701795578", Image="rbxassetid://132553701795578" },

	["Zubat"]  = { Id=41, Rarity="Common",   Attack=9,  HP=10, Type="Poison", Model="041 - Zubat", EvolveTo="Golbat", Icon="rbxassetid://135969606810652", Image="rbxassetid://135969606810652" },
	["Golbat"] = { Id=42, Rarity="Uncommon", Attack=13, HP=18, Type="Poison", Model="042 - Golbat", Icon="rbxassetid://124032175965383", Image="rbxassetid://124032175965383" },

	["Oddish"]    = { Id=43, Rarity="Common",   Attack=9,  HP=12, Type="Grass", Model="043 - Oddish", EvolveTo="Gloom", Icon="rbxassetid://122885518307781", Image="rbxassetid://122885518307781" },
	["Gloom"]     = { Id=44, Rarity="Uncommon", Attack=12, HP=17, Type="Grass", Model="044 - Gloom", EvolveTo="Vileplume", Icon="rbxassetid://100626428921181", Image="rbxassetid://100626428921181" },
	["Vileplume"] = { Id=45, Rarity="Rare",     Attack=17, HP=24, Type="Grass", Model="045 - Vileplume", Icon="rbxassetid://122977932765667", Image="rbxassetid://122977932765667" },

	["Paras"]    = { Id=46, Rarity="Common",   Attack=10, HP=10, Type="Bug", Model="046 - Paras", EvolveTo="Parasect", Icon="rbxassetid://78068105484045", Image="rbxassetid://78068105484045" },
	["Parasect"] = { Id=47, Rarity="Uncommon", Attack=14, HP=18, Type="Bug", Model="047 - Parasect", Icon="rbxassetid://77204612210612", Image="rbxassetid://77204612210612" },

	["Venonat"]  = { Id=48, Rarity="Common",   Attack=9,  HP=12, Type="Bug", Model="048 - Venonat", EvolveTo="Venomoth", Icon="rbxassetid://135243827653295", Image="rbxassetid://135243827653295" },
	["Venomoth"] = { Id=49, Rarity="Uncommon", Attack=14, HP=18, Type="Bug", Model="049 - Venomoth", Icon="rbxassetid://82456953531623", Image="rbxassetid://82456953531623" },

	["Diglett"] = { Id=50, Rarity="Common",   Attack=10, HP=8,  Type="Ground", Model="050 - Diglett", EvolveTo="Dugtrio", Icon="rbxassetid://131298290121897", Image="rbxassetid://131298290121897" },
	["Dugtrio"] = { Id=51, Rarity="Uncommon", Attack=16, HP=14, Type="Ground", Model="051 - Dugtrio", Icon="rbxassetid://96882979862778", Image="rbxassetid://96882979862778" },

	["Meowth"]  = { Id=52, Rarity="Uncommon", Attack=11, HP=12, Type="Normal", Model="052 - Meowth", EvolveTo="Persian", Icon="rbxassetid://125524212010581", Image="rbxassetid://125524212010581" },
	["Persian"] = { Id=53, Rarity="Rare",     Attack=16, HP=18, Type="Normal", Model="053 - Persian", Icon="rbxassetid://123983202327080", Image="rbxassetid://123983202327080" },

	["Psyduck"] = { Id=54, Rarity="Common", Attack=10, HP=13, Type="Water", Model="054 - Psyduck", EvolveTo="Golduck", Icon="rbxassetid://126712195495804", Image="rbxassetid://126712195495804" },
	["Golduck"] = { Id=55, Rarity="Rare",   Attack=17, HP=22, Type="Water", Model="055 - Golduck", Icon="rbxassetid://128832364021033", Image="rbxassetid://128832364021033" },

	-- MANKEY (056-057) DELETED (Not in image)

	["Growlithe"] = { Id=58, Rarity="Uncommon", Attack=13, HP=14, Type="Fire", Model="058 - Growlithe", EvolveTo="Arcanine", Icon="rbxassetid://92046456866750", Image="rbxassetid://92046456866750" },
	["Arcanine"]  = { Id=59, Rarity="Rare",     Attack=20, HP=24, Type="Fire", Model="059 - Arcanine", Icon="rbxassetid://139200062371791", Image="rbxassetid://139200062371791" },

	["Poliwag"]   = { Id=60, Rarity="Common",   Attack=9,  HP=12, Type="Water", Model="060 - Poliwag", EvolveTo="Poliwhirl", Icon="rbxassetid://125788015653840", Image="rbxassetid://125788015653840" },
	["Poliwhirl"] = { Id=61, Rarity="Uncommon", Attack=13, HP=17, Type="Water", Model="061 - Poliwhirl", EvolveTo="Poliwrath", Icon="rbxassetid://108380053308330", Image="rbxassetid://108380053308330" },
	["Poliwrath"] = { Id=62, Rarity="Rare",     Attack=18, HP=26, Type="Water", Model="062 - Poliwrath", Icon="rbxassetid://102038995556415", Image="rbxassetid://102038995556415" },

	["Abra"]     = { Id=63, Rarity="Common",   Attack=12, HP=8,  Type="Psychic", Model="063 - Abra", EvolveTo="Kadabra", Icon="rbxassetid://103450733708732", Image="rbxassetid://103450733708732" },
	["Kadabra"]  = { Id=64, Rarity="Uncommon", Attack=17, HP=14, Type="Psychic", Model="064 - Kadabra", EvolveTo="Alakazam", Icon="rbxassetid://118862992618273", Image="rbxassetid://118862992618273" },
	["Alakazam"] = { Id=65, Rarity="Epic",     Attack=25, HP=20, Type="Psychic", Model="065 - Alakazam", Icon="rbxassetid://79457826854547", Image="rbxassetid://79457826854547" },

	["Machop"]  = { Id=66, Rarity="Common",   Attack=11, HP=13, Type="Fighting", Model="066 - Machop", EvolveTo="Machoke", Icon="rbxassetid://86852185734252", Image="rbxassetid://86852185734252" },
	["Machoke"] = { Id=67, Rarity="Uncommon", Attack=16, HP=18, Type="Fighting", Model="067 - Machoke", EvolveTo="Machamp", Icon="rbxassetid://124352935408578", Image="rbxassetid://124352935408578" },
	["Machamp"] = { Id=68, Rarity="Epic",     Attack=23, HP=28, Type="Fighting", Model="068 - Machamp", Icon="rbxassetid://128583553114522", Image="rbxassetid://128583553114522" },

	["Bellsprout"]  = { Id=69, Rarity="Common",   Attack=10, HP=10, Type="Grass", Model="069 - Bellsprout", EvolveTo=nil, Icon="rbxassetid://96808883972645", Image="rbxassetid://96808883972645" }, -- Weepinbell (070) Missing in image
	["Victreebel"]  = { Id=71, Rarity="Rare",     Attack=19, HP=22, Type="Grass", Model="071 - Victreebel", Icon="rbxassetid://86837269586329", Image="rbxassetid://86837269586329" },

	["Tentacool"]  = { Id=72, Rarity="Common", Attack=9,  HP=12, Type="Water", Model="072 - Tentacool", EvolveTo="Tentacruel", Icon="rrbxassetid://120603087166192", Image="rbxassetid://120603087166192" },
	["Tentacruel"] = { Id=73, Rarity="Rare",   Attack=16, HP=25, Type="Water", Model="073 - Tentacruel", Icon="rbxassetid://115780938634985", Image="rbxassetid://115780938634985" },

	["Geodude"]  = { Id=74, Rarity="Common",   Attack=10, HP=14, Type="Rock", Model="074 - Geodude", EvolveTo="Graveler", Icon="rbxassetid://79016681152490", Image="rbxassetid://79016681152490" },
	["Graveler"] = { Id=75, Rarity="Uncommon", Attack=14, HP=20, Type="Rock", Model="075 - Graveler", EvolveTo="Golem", Icon="rbxassetid://137594701676986", Image="rbxassetid://137594701676986" },
	["Golem"]    = { Id=76, Rarity="Epic",     Attack=20, HP=30, Type="Rock", Model="076 - Golem", Icon="rbxassetid://73937058613214", Image="rbxassetid://73937058613214" },

	["Ponyta"]   = { Id=77, Rarity="Common",   Attack=11, HP=11, Type="Fire", Model="077 - Ponyta", EvolveTo="Rapidash", Icon="rbxassetid://90829159718469", Image="rbxassetid://90829159718469" },
	["Rapidash"] = { Id=78, Rarity="Uncommon", Attack=17, HP=19, Type="Fire", Model="078 - Rapidash", Icon="rbxassetid://92714633319780", Image="rbxassetid://92714633319780" },

	["Slowpoke"] = { Id=79, Rarity="Common", Attack=9,  HP=16, Type="Water", Model="079 - Slowpoke", EvolveTo="Slowbro", Icon="rbxassetid://99195017539150", Image="rbxassetid://99195017539150" },
	["Slowbro"]  = { Id=80, Rarity="Rare",   Attack=15, HP=28, Type="Water", Model="080 - Slowbro", Icon="rbxassetid://84527208555085", Image="rbxassetid://84527208555085" },

	-- MAGNEMITE (081) - SHELLDER (091) DELETED (Not in image)

	["Gastly"]  = { Id=92, Rarity="Uncommon", Attack=13, HP=10, Type="Ghost", Model="092 - Gastly", EvolveTo="Haunter", Icon="rbxassetid://70628851155055", Image="rbxassetid://70628851155055" },
	["Haunter"] = { Id=93, Rarity="Rare",     Attack=17, HP=15, Type="Ghost", Model="093 - Haunter", EvolveTo="Gengar", Icon="rbxassetid://76183676056817", Image="rbxassetid://76183676056817" },
	["Gengar"]  = { Id=94, Rarity="Epic",     Attack=24, HP=20, Type="Ghost", Model="094 - Gengar", Icon="rbxassetid://73487593240517", Image="rbxassetid://73487593240517" },

	-- ONIX (095) - TAUROS (128) DELETED (Not in image)

	["Magikarp"] = { Id=129, Rarity="Common", Attack=5,  HP=8,  Type="Water", Model="129 - Magikarp", EvolveTo="Gyarados", Icon="rbxassetid://102675286979211", Image="rbxassetid://102675286979211" },
	["Gyarados"] = { Id=130, Rarity="Epic",   Attack=23, HP=30, Type="Water", Model="130 - Gyarados", Icon="rbxassetid://121398576898364", Image="rbxassetid://121398576898364" },

	["Lapras"] = { Id=131, Rarity="Rare", Attack=16, HP=34, Type="Water", Model="131 - Lapras", Icon="rbxassetid://90620155620612", Image="rbxassetid://90620155620612" },

	-- DITTO/EEVEE/PORYGON/FOSSILS/SNORLAX/BIRDS DELETED (Not in image)

	["Dratini"]   = { Id=147, Rarity="Uncommon", Attack=12, HP=14, Type="Dragon", Model="147 - Dratini", EvolveTo="Dragonair", Icon="rbxassetid://129382301073001", Image="rbxassetid://129382301073001" },
	["Dragonair"] = { Id=148, Rarity="Rare",     Attack=17, HP=22, Type="Dragon", Model="148 - Dragonair", EvolveTo="Dragonite", Icon="rbxassetid://121255668090770", Image="rbxassetid://121255668090770" },
	["Dragonite"] = { Id=149, Rarity="Divine",   Attack=25, HP=36, Type="Dragon", Model="149 - Dragonite", Icon="rbxassetid://121255668090770", Image="rbxassetid://121255668090770" },

	["Mewtwo"] = { Id=150, Rarity="Legend", Attack=32, HP=38, Type="Psychic", Model="150 - Mewtwo", Icon="rbxassetid://140657668203910", Image="rbxassetid://140657668203910" },
	-- MEW (151) DELETED (Not in image)

	--================================================================================
	-- GEN 2 (ONLY Larvitar Line) - Chikorita etc are in image but you deleted Gen 2 earlier.
	-- I kept only Larvitar line per your previous logic + it IS in the image.
	--================================================================================
	["Larvitar"]  = { Id=246, Rarity="Uncommon", Attack=13, HP=15, Type="Rock", Model="246 - Larvitar", EvolveTo="Pupitar", Icon="rbxassetid://114738621370195", Image="rbxassetid://114738621370195" },
	["Pupitar"]   = { Id=247, Rarity="Rare",     Attack=17, HP=24, Type="Rock", Model="247 - Pupitar", EvolveTo="Tyranitar", Icon="rbxassetid://108993508354994", Image="rbxassetid://108993508354994" },
	["Tyranitar"] = { Id=248, Rarity="Divine",   Attack=26, HP=38, Type="Rock", Model="248 - Tyranitar", Icon="rbxassetid://85138698243117", Image="rbxassetid://85138698243117" },

	--================================================================================
	-- GEN 3
	--================================================================================
	["Treecko"]  = { Id=252, Rarity="Uncommon", Attack=12, HP=12, Type="Grass", Model="252 - Treecko", EvolveTo="Grovyle", Icon="rbxassetid://77427423767316", Image="rbxassetid://77427423767316" },
	["Grovyle"]  = { Id=253, Rarity="Rare",     Attack=17, HP=18, Type="Grass", Model="253 - Grovyle", EvolveTo="Sceptile", Icon="rbxassetid://124309669203410", Image="rbxassetid://124309669203410" },
	["Sceptile"] = { Id=254, Rarity="Epic",     Attack=24, HP=22, Type="Grass", Model="254 - Sceptile", Icon="rbxassetid://101625010299924", Image="rbxassetid://101625010299924" },

	["Torchic"]   = { Id=255, Rarity="Uncommon", Attack=13, HP=11, Type="Fire", Model="255 - Torchic", EvolveTo="Combusken", Icon="rbxassetid://134722738127378", Image="rbxassetid://134722738127378" },
	["Combusken"] = { Id=256, Rarity="Rare",     Attack=18, HP=17, Type="Fire", Model="256 - Combusken", EvolveTo="Blaziken", Icon="rbxassetid://138557250718542", Image="rbxassetid://138557250718542" },
	["Blaziken"]  = { Id=257, Rarity="Epic",     Attack=25, HP=22, Type="Fire", Model="257 - Blaziken", Icon="rbxassetid://116477204045832", Image="rbxassetid://116477204045832" },

	["Mudkip"]    = { Id=258, Rarity="Uncommon", Attack=12, HP=14, Type="Water", Model="258 - Mudkip", EvolveTo="Marshtomp", Icon="rbxassetid://100021812634842", Image="rbxassetid://100021812634842" },
	["Marshtomp"] = { Id=259, Rarity="Rare",     Attack=16, HP=22, Type="Water", Model="259 - Marshtomp", EvolveTo="Swampert", Icon="rbxassetid://86400581791610", Image="rbxassetid://86400581791610" },
	["Swampert"]  = { Id=260, Rarity="Epic",     Attack=23, HP=30, Type="Water", Model="260 - Swampert", Icon="rbxassetid://77088904470441", Image="rbxassetid://77088904470441" },

	["Ralts"]     = { Id=280, Rarity="Uncommon", Attack=10, HP=10, Type="Psychic", Model="280 - Ralts", EvolveTo="Kirlia", Icon="rbxassetid://83061697860452", Image="rbxassetid://83061697860452" },
	["Kirlia"]    = { Id=281, Rarity="Rare",     Attack=15, HP=16, Type="Psychic", Model="281 - Kirlia", EvolveTo="Gardevoir", Icon="rbxassetid://74815497777104", Image="rbxassetid://74815497777104" },
	["Gardevoir"] = { Id=282, Rarity="Epic",     Attack=24, HP=22, Type="Psychic", Model="282 - Gardevoir", Icon="rbxassetid://94936736403279", Image="rbxassetid://94936736403279" },

	["Beldum"]    = { Id=374, Rarity="Uncommon", Attack=12, HP=16, Type="Steel", Model="374 - Beldum", EvolveTo="Metang", Icon="rbxassetid://81670992056922", Image="rbxassetid://81670992056922" },
	["Metang"]    = { Id=375, Rarity="Rare",     Attack=16, HP=24, Type="Steel", Model="375 - Metang", EvolveTo="Metagross", Icon="rbxassetid://130088362064615", Image="rbxassetid://130088362064615" },
	["Metagross"] = { Id=376, Rarity="Divine",   Attack=25, HP=38, Type="Steel", Model="376 - Metagross", Icon="rbxassetid://122380520580963", Image="rbxassetid://122380520580963" },

	--================================================================================
	-- GEN 4
	--================================================================================
	["Turtwig"]  = { Id=387, Rarity="Uncommon", Attack=11, HP=15, Type="Grass", Model="387 - Turtwig", EvolveTo="Grotle", Icon="rbxassetid://71071979111881", Image="rbxassetid://71071979111881" },
	["Grotle"]   = { Id=388, Rarity="Rare",     Attack=16, HP=24, Type="Grass", Model="388 - Grotle", EvolveTo="Torterra", Icon="rbxassetid://130619327200511", Image="rbxassetid://130619327200511" },
	["Torterra"] = { Id=389, Rarity="Epic",     Attack=22, HP=34, Type="Grass", Model="389 - Torterra", Icon="rbxassetid://131467317357548", Image="rbxassetid://131467317357548" },

	["Chimchar"]  = { Id=390, Rarity="Uncommon", Attack=13, HP=11, Type="Fire", Model="390 - Chimchar", EvolveTo="Monferno", Icon="rbxassetid://94161775033579", Image="rbxassetid://94161775033579" },
	["Monferno"]  = { Id=391, Rarity="Rare",     Attack=18, HP=16, Type="Fire", Model="391 - Monferno", EvolveTo="Infernape", Icon="rbxassetid://77951844859229", Image="rbxassetid://77951844859229" },
	["Infernape"] = { Id=392, Rarity="Epic",     Attack=25, HP=20, Type="Fire", Model="392 - Infernape", Icon="rbxassetid://85398480998557", Image="rbxassetid://85398480998557" },

	["Piplup"]   = { Id=393, Rarity="Uncommon", Attack=11, HP=14, Type="Water", Model="393 - Piplup", EvolveTo="Prinplup", Icon="rbxassetid://108986699929048", Image="rbxassetid://108986699929048" },
	["Prinplup"] = { Id=394, Rarity="Rare",     Attack=16, HP=20, Type="Water", Model="394 - Prinplup", EvolveTo="Empoleon", Icon="rbxassetid://80912630264598", Image="rbxassetid://80912630264598" },
	["Empoleon"] = { Id=395, Rarity="Epic",     Attack=23, HP=30, Type="Water", Model="395 - Empoleon", Icon="rbxassetid://90435442302767", Image="rbxassetid://90435442302767" },

	["Bidoof"]  = { Id=399, Rarity="Common",   Attack=8,  HP=12, Type="Normal", Model="399 - Bidoof", EvolveTo="Bibarel", Icon="rbxassetid://88041120791602", Image="rbxassetid://88041120791602" },
	["Bibarel"] = { Id=400, Rarity="Uncommon", Attack=14, HP=22, Type="Normal", Model="400 - Bibarel", Icon="rbxassetid://79576768503406", Image="rbxassetid://79576768503406" },

	["Gible"]    = { Id=443, Rarity="Uncommon", Attack=13, HP=14, Type="Dragon", Model="443 - Gible", EvolveTo="Gabite", Icon="rbxassetid://102990550229282", Image="rbxassetid://102990550229282" },
	["Gabite"]   = { Id=444, Rarity="Rare",     Attack=18, HP=22, Type="Dragon", Model="444 - Gabite", EvolveTo="Garchomp", Icon="rbxassetid://90858868001482", Image="rbxassetid://90858868001482" },
	["Garchomp"] = { Id=445, Rarity="Divine",   Attack=27, HP=34, Type="Dragon", Model="445 - Garchomp", Icon="rbxassetid://78500346251469", Image="rbxassetid://78500346251469" },

	--================================================================================
	-- GEN 5
	--================================================================================
	["Ferroseed"]  = { Id=597, Rarity="Uncommon", Attack=11, HP=18, Type="Grass", Model="597 - Ferroseed", EvolveTo="Ferrothorn", Icon="rbxassetid://128079895836937", Image="rbxassetid://128079895836937" },
	["Ferrothorn"] = { Id=598, Rarity="Rare",     Attack=16, HP=32, Type="Grass", Model="598 - Ferrothorn", Icon="rbxassetid://88295237814419", Image="rbxassetid://88295237814419" },

	["Litwick"]    = { Id=607, Rarity="Uncommon", Attack=12, HP=11, Type="Ghost", Model="607 - Litwick", EvolveTo="Lampent", Icon="rbxassetid://130744569715962", Image="rbxassetid://130744569715962" },
	["Lampent"]    = { Id=608, Rarity="Rare",     Attack=17, HP=16, Type="Ghost", Model="608 - Lampent", EvolveTo="Chandelure", Icon="rbxassetid://72361105976188", Image="rbxassetid://72361105976188" },
	["Chandelure"] = { Id=609, Rarity="Epic",     Attack=26, HP=20, Type="Ghost", Model="609 - Chandelure", Icon="rbxassetid://0", Image="rbxassetid://0" },

	--================================================================================
	-- GEN 9
	--================================================================================
	["Sprigatito"]  = { Id=906, Rarity="Uncommon", Attack=12, HP=12, Type="Grass", Model="906 - Sprigatito", EvolveTo="Floragato", Icon="rbxassetid://99267429164006", Image="rbxassetid://99267429164006" },
	["Floragato"]   = { Id=907, Rarity="Rare",     Attack=17, HP=17, Type="Grass", Model="907 - Floragato", EvolveTo="Meowscarada", Icon="rbxassetid://119093547471933", Image="rbxassetid://119093547471933" },
	["Meowscarada"] = { Id=908, Rarity="Epic",     Attack=24, HP=22, Type="Grass", Model="908 - Meowscarada", Icon="rbxassetid://76132205154349", Image="rbxassetid://76132205154349" },

	["Fuecoco"]    = { Id=909, Rarity="Uncommon", Attack=12, HP=15, Type="Fire", Model="909 - Fuecoco", EvolveTo="Crocalor", Icon="rbxassetid://100643239328472", Image="rbxassetid://100643239328472" },
	["Crocalor"]   = { Id=910, Rarity="Rare",     Attack=17, HP=24, Type="Fire", Model="910 - Crocalor", EvolveTo="Skeledirge", Icon="rbxassetid://0", Image="rbxassetid://0" },
	["Skeledirge"] = { Id=911, Rarity="Epic",     Attack=22, HP=32, Type="Fire", Model="911 - Skeledirge", Icon="rbxassetid://133636351324480", Image="rbxassetid://133636351324480" },

	["Quaxly"]    = { Id=912, Rarity="Uncommon", Attack=13, HP=13, Type="Water", Model="912 - Quaxly", EvolveTo="Quaxwell", Icon="rbxassetid://139219172128335", Image="rbxassetid://139219172128335" },
	["Quaxwell"]  = { Id=913, Rarity="Rare",     Attack=17, HP=20, Type="Water", Model="913 - Quaxwell", EvolveTo="Quaquaval", Icon="rbxassetid://81551061112201", Image="rbxassetid://81551061112201" },
	["Quaquaval"] = { Id=914, Rarity="Epic",     Attack=25, HP=26, Type="Water", Model="914 - Quaquaval", Icon="rbxassetid://108393314003706", Image="rbxassetid://108393314003706" },

	-- CYCLIZAR DELETED (Not in image)
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
		-- Fallback logic for safety
		if selectedRarity == "Divine" then pool = PokemonDB.GetByRarity("Epic") end
		if #pool == 0 then pool = PokemonDB.GetByRarity("Rare") end
		if #pool == 0 then pool = PokemonDB.GetByRarity("Common") end
	end

	if #pool > 0 then
		return pool[math.random(1, #pool)]
	end
	return nil
end

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
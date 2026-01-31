--[[
================================================================================
                       ?? CARD DATABASE
================================================================================
    ?? ModuleScript defining all available cards in the game.
    
    ?? Card Types:
        - Buff/Support: Positive effects (Money, Draw, Balls)
        - Attack: Negative effects on others (Steal, Push back, Sleep)
        - Defense: Self-protection (Shield, Cleanse)
        
    ?? Usage:
        local CardDB = require(ReplicatedStorage.CardDB)
        local card = CardDB.Cards["Potion"]
================================================================================
--]]

local CardDB = {}

-- Card Registry
CardDB.Cards = {
	-- === BUFF/SUPPORT CARDS ===

	["Lucky Energy"] = {
		Name = "Lucky Energy",
		Description = "Draw 2 cards",
		Draw = 2,
	},
	
	["Rare Candy"] = {
		Name = "Rare Candy",
		Description = "Evolve your pokemon",
	},

	["Nugget"] = {
		Name = "Nugget",
		Description = "Sell for 5 coins",
		MoneyGain = 5,
	},

	-- === ATTACK CARDS ===
	["Grabber"] = {
		Name = "Grabber",
		Description = "Steal 5 coins from target player",
		Steal = 5,
		NeedsTarget = true,
		Negative = true,
	},

	["Air Balloon"] = {
		Name = "Air Balloon",
		Description = "Target player moves back 3 tiles",
		BackSteps = 3,
		NeedsTarget = true,
		Negative = true,
	},

	["Sleep Powder"] = {
		Name = "Sleep Powder",
		Description = "Target player skips 1 turn",
		SleepTurns = 1,
		NeedsTarget = true,
		Negative = true,
	},

	["Twisted Spoon"] = {
		Name = "Twisted Spoon",
		Description = "Teleport to a selected player. Triggers tile event. Skips your dice roll.",
		Warp = true,
		NeedsTarget = true,
	},

	-- === DEFENSE CARDS ===
	["Protective Goggles"] = {
		Name = "Protective Goggles",
		Description = "PASSIVE: Auto-blocks one negative card (Grabber, Sleep Powder, Air Balloon)",
		Shield = true,
	},

	["Revive"] = {
		Name = "Revive",
		Description = "Choose 1 fainted Pokemon to revive",
		NeedsSelfPokemon = true,
	},
}

-- Deck Builder
function CardDB:BuildDeck()
	local deck = {}

	local cardCounts = {
		["Lucky Energy"] = 6,
		["Rare Candy"] = 4,
		["Nugget"] = 10,
		["Grabber"] = 4,
		["Air Balloon"] = 4,
		["Sleep Powder"] = 2,
		["Twisted Spoon"] = 3,
		["Protective Goggles"] = 5,
		["Revive"] = 4,
	}

	for cardId, count in pairs(cardCounts) do
		for i = 1, count do
			table.insert(deck, cardId)
		end
	end

	return deck
end

return CardDB

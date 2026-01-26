--[[
================================================================================
                       🃏 CARD DATABASE
================================================================================
    📌 ModuleScript defining all available cards in the game.
    
    🎴 Card Types:
        - Buff/Support: Positive effects (Money, Draw, Balls)
        - Attack: Negative effects on others (Steal, Push back, Sleep)
        - Defense: Self-protection (Shield, Cleanse)
        
    📁 Usage:
        local CardDB = require(ReplicatedStorage.CardDB)
        local card = CardDB.Cards["Potion"]
================================================================================
--]]

local CardDB = {}

-- Card Registry
CardDB.Cards = {
	-- === BUFF/SUPPORT CARDS ===
	["Potion"] = {
		Name = "Potion",
		Description = "Gain 5 coins",
		MoneyGain = 5,
	},
	
	["Super Potion"] = {
		Name = "Super Potion", 
		Description = "Gain 10 coins",
		MoneyGain = 10,
	},
	
	["Lucky Draw"] = {
		Name = "Lucky Draw",
		Description = "Draw 2 cards",
		Draw = 2,
	},
	
	["Nugget"] = {
		Name = "Nugget",
		Description = "Sell for 5 coins",
		MoneyGain = 5,
	},
	
	-- === ATTACK CARDS ===
	["Robbery"] = {
		Name = "Robbery",
		Description = "Steal 5 coins from target player",
		Steal = 5,
		NeedsTarget = true,
		Negative = true,
	},
	
	["Push Back"] = {
		Name = "Push Back",
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
	
	-- === DEFENSE CARDS ===
	["Safety Shield"] = {
		Name = "Safety Shield",
		Description = "Block next negative card",
		Shield = true,
	},
	
	["Full Heal"] = {
		Name = "Full Heal",
		Description = "Remove sleep status",
		Cleanse = true,
	},
}

-- Deck Builder
function CardDB:BuildDeck()
	local deck = {}
	
	-- Add cards to deck (Configure quantities here)
	local cardCounts = {
		["Potion"] = 10,
		["Super Potion"] = 5,
		["Lucky Draw"] = 5,
		["Nugget"] = 8,
		["Robbery"] = 3,
		["Push Back"] = 3,
		["Sleep Powder"] = 2,
		["Safety Shield"] = 5,
		["Full Heal"] = 4,
	}
	
	for cardId, count in pairs(cardCounts) do
		for i = 1, count do
			table.insert(deck, cardId)
		end
	end
	
	return deck
end

return CardDB

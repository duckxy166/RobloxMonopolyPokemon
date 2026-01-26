--[[
================================================================================
                       🃏 CARD DATABASE - ฐานข้อมูลการ์ด
================================================================================
    📌 ModuleScript นี้เก็บข้อมูลการ์ดทั้งหมดในเกม
    
    🎴 ประเภทการ์ด:
        - Buff/Support: ให้ข้อดีแก่ผู้เล่น (เงิน, จับการ์ด, ลูกบอล)
        - Attack: โจมตีผู้เล่นอื่น (ขโมยเงิน, ถอยหลัง, Sleep)
        - Defense: ป้องกันตัวเอง (Shield, Cleanse)
        
    📁 ใช้งาน:
        local CardDB = require(ServerStorage.CardDB)
        local card = CardDB.Cards["Potion"]
================================================================================
--]]

local CardDB = {}

-- 🃏 ฐานข้อมูลการ์ดทั้งหมด
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
	
	["Pokeball Card"] = {
		Name = "Pokeball Card",
		Description = "Gain 2 Pokeballs",
		AddBalls = 2,
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

-- 🔨 สร้างกองไพ่ (Deck)
function CardDB:BuildDeck()
	local deck = {}
	
	-- เพิ่มการ์ดแต่ละชนิดลงกอง (จำนวนตามต้องการ)
	local cardCounts = {
		["Potion"] = 10,
		["Super Potion"] = 5,
		["Lucky Draw"] = 5,
		["Pokeball Card"] = 8,
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

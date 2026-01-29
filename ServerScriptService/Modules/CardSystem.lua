--[[
================================================================================
                      🃏 CARD SYSTEM - Deck & Hand Management
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Deck building, shuffling
        - Draw, discard piles
        - Hand management (add/remove cards)
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardSystem = {}

-- Constants
CardSystem.HAND_LIMIT = 5

-- State
CardSystem.deck = {}
CardSystem.discardPile = {}

-- Dependencies (set via init)
local CardDB = nil
local notifyEvent = nil

-- Shuffle helper (Fisher-Yates)
local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Initialize with dependencies
function CardSystem.init(events)
	-- Load CardDB
	local CardDBModule = ReplicatedStorage:WaitForChild("CardDB", 10)
	if not CardDBModule then
		warn("🚨 CRITICAL: CardDB not found in ReplicatedStorage!")
		CardDBModule = Instance.new("ModuleScript")
		CardDBModule.Name = "CardDB"
		CardDBModule.Parent = ReplicatedStorage
	end
	CardDB = require(CardDBModule)
	notifyEvent = events.Notify

	print("✅ CardSystem initialized")
end

-- Refill deck from discard pile
function CardSystem.refillDeckIfEmpty()
	if #CardSystem.deck > 0 then return end
	if #CardSystem.discardPile == 0 then
		CardSystem.deck = CardDB:BuildDeck()
		shuffle(CardSystem.deck)
		return
	end
	CardSystem.deck = CardSystem.discardPile
	CardSystem.discardPile = {}
	shuffle(CardSystem.deck)
end

-- Get hand folder for player
function CardSystem.getHandFolder(player)
	return player:FindFirstChild("Hand")
end

-- Count total cards in hand
function CardSystem.countHand(player)
	local hand = CardSystem.getHandFolder(player)
	if not hand then return 0 end
	local total = 0
	for _, v in ipairs(hand:GetChildren()) do
		if v:IsA("IntValue") then
			total += v.Value
		end
	end
	return total
end

-- Add card to player hand
function CardSystem.addCardToHand(player, cardId)
	local hand = CardSystem.getHandFolder(player)
	if not hand then return false, "no_hand" end
	if CardSystem.countHand(player) >= CardSystem.HAND_LIMIT then
		return false, "hand_full"
	end

	local slot = hand:FindFirstChild(cardId)
	if not slot then
		slot = Instance.new("IntValue")
		slot.Name = cardId
		slot.Value = 0
		slot.Parent = hand
	end

	slot.Value += 1
	return true
end

-- Remove card from player hand
function CardSystem.removeCardFromHand(player, cardId, amount)
	amount = amount or 1
	local hand = CardSystem.getHandFolder(player)
	if not hand then return false end

	local slot = hand:FindFirstChild(cardId)
	if not slot or not slot:IsA("IntValue") then return false end
	if slot.Value < amount then return false end

	slot.Value -= amount
	if slot.Value <= 0 then slot:Destroy() end
	return true
end

-- Draw one card from deck
function CardSystem.drawOneCard(player)
	CardSystem.refillDeckIfEmpty()

	if CardSystem.countHand(player) >= CardSystem.HAND_LIMIT then
		if notifyEvent then 
			notifyEvent:FireClient(player, "Hand is full (5 cards)! Discard or use cards first!") 
		end
		return nil
	end

	local cardId = table.remove(CardSystem.deck, 1)
	if not cardId then return nil end

	local ok = CardSystem.addCardToHand(player, cardId)
	if ok then
		if notifyEvent and CardDB then
			local def = CardDB.Cards[cardId]
			notifyEvent:FireClient(player, ("Card drawn: %s"):format(def and def.Name or cardId))
		end
		return cardId
	end

	table.insert(CardSystem.deck, 1, cardId)
	return nil
end

-- Discard a card
function CardSystem.discardCard(cardId)
	table.insert(CardSystem.discardPile, cardId)
end

-- Get CardDB reference
function CardSystem.getCardDB()
	return CardDB
end

function CardSystem.connectEvents(events, turnManager, playerManager)
	if events.PlayCard then
		events.PlayCard.OnServerEvent:Connect(function(player, cardName, targetInfo)
			print("🃏 [Server] PlayCard Request form " .. player.Name .. ": " .. tostring(cardName))
			
			-- 1. Phase Check (Pre-Roll Only)
			if turnManager.turnPhase ~= "Roll" then
				if events.Notify then 
					events.Notify:FireClient(player, "❌ Can only use cards before rolling!") 
				end
				return
			end
			
			-- 2. Turn Check
			if player ~= playerManager.playersInGame[turnManager.currentTurnIndex] then
				if events.Notify then
					events.Notify:FireClient(player, "❌ Not your turn!")
				end
				return
			end
			
			-- 3. Verify Ownership
			local hand = CardSystem.getHandFolder(player)
			local cardObj = hand and hand:FindFirstChild(cardName)
			if not cardObj then return end -- Player doesn't have card
			
			-- 4. Process Effect (Placeholder for now, just consume)
			-- TODO: Add specific card logic here (e.g. Potion, etc.)
			CardSystem.removeCardFromHand(player, cardName, 1)
			
			if events.Notify then
				events.Notify:FireClient(player, "✅ Used " .. cardName .. "!")
			end
			
			-- 5. Special logic if card affects movement or stats could go here
		end)
	end
end

return CardSystem

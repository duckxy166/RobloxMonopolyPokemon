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
			
			-- 1. Phase Check (Pre-Roll Only & Turn Active)
			if turnManager.turnPhase ~= "Roll" or not turnManager.isTurnActive then
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
			
			-- 4. Get Card Definition
			local cardDef = CardDB.Cards[cardName]
			
			-- 5. Process Effect
			CardSystem.removeCardFromHand(player, cardName, 1)
			
			if cardDef then
				-- [A] Money Gain (Nugget)
				if cardDef.MoneyGain and cardName ~= "Rare Candy" then
					local money = player.leaderstats.Money
					money.Value += cardDef.MoneyGain
					if events.Notify then events.Notify:FireClient(player, "💰 Gained " .. cardDef.MoneyGain .. " Coins!") end
				end
				
				-- [B] Draw Cards (Lucky Draw)
				if cardDef.Draw then
					for i=1, cardDef.Draw do
						CardSystem.drawOneCard(player)
					end
					if events.Notify then events.Notify:FireClient(player, "🃏 Drew " .. cardDef.Draw .. " cards!") end
				end
				
				-- [C] Heal / Cleanse (Full Heal)
				if cardDef.Cleanse then
					local status = player:FindFirstChild("Status")
					local sleep = status and status:FindFirstChild("SleepTurns")
					if sleep then sleep.Value = 0 end
					if events.Notify then events.Notify:FireClient(player, "✨ Status Cleared!") end
				end
			end
			
			-- [D] Special Cards
			if cardName == "Rare Candy" then
				local EvolutionSystem = require(script.Parent:WaitForChild("EvolutionSystem"))
				local success = EvolutionSystem.tryEvolve(player)
				if not success then
					player.leaderstats.Money.Value += 3
					if events.Notify then events.Notify:FireClient(player, "🍬 No evolution possible. +3 Coins instead.") end
				end
			end
			
			-- TARGET CARD LOGIC
			if cardDef.NeedsTarget then
				local targetPlayer = targetInfo
				
				-- Validation
				if not targetPlayer or typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
					if events.Notify then events.Notify:FireClient(player, "❌ Invalid Target!") end
					-- Refund card? To simplify, we assume client handled it correctly.
					return 
				end
				
				if targetPlayer == player then
					if events.Notify then events.Notify:FireClient(player, "❌ Cannot target yourself!") end
					return
				end
				
				print("🎯 " .. player.Name .. " used " .. cardName .. " on " .. targetPlayer.Name)

				-- DEFENSE CHECK (Safety Goggles)
                -- Concept: If target has Goggles, ask if they want to block.
                local blocked = false
                if cardName ~= "Twisted Spoon" then
                    local targetHand = CardSystem.getHandFolder(targetPlayer)
                    local goggles = targetHand and targetHand:FindFirstChild("Safety Goggles")
                    
                    if goggles and events.RequestReaction then
						-- Notify Attacker
						if events.Notify then events.Notify:FireClient(player, "⏳ Waiting for response...") end
						
                        local decision = events.RequestReaction:InvokeClient(targetPlayer, player.Name, cardName)
                        if decision then
                            blocked = true
                            -- Consume Goggles
                            CardSystem.removeCardFromHand(targetPlayer, "Safety Goggles", 1)
                            
                            if events.Notify then
                                events.Notify:FireClient(player, "🛡️ Attack BLOCKED by Safety Goggles!")
                                events.Notify:FireClient(targetPlayer, "🛡️ You blocked the attack!")
                            end
                        end
                    end
                end
                
                if blocked then return end

				-- 1. TWISTED SPOON (Teleport to Target) - Unblockable
				if cardName == "Twisted Spoon" then
					local targetPos = playerManager.playerPositions[targetPlayer.UserId]
					playerManager.playerPositions[player.UserId] = targetPos
					
					if player.Character and targetPlayer.Character then
						player.Character:SetPrimaryPartCFrame(targetPlayer.Character.PrimaryPart.CFrame + Vector3.new(3, 0, 0))
					end
					
					if events.Notify then
						events.Notify:FireClient(player, "🔮 Warped to " .. targetPlayer.Name .. "!")
						events.Notify:FireClient(targetPlayer, "🔮 " .. player.Name .. " warped to you!")
					end
				end
				
				-- 2. SLEEP POWDER (Sleep 1 Turn)
				if cardName == "Sleep Powder" then
					local status = targetPlayer:FindFirstChild("Status")
					local sleep = status and status:FindFirstChild("SleepTurns")
					if sleep then
						sleep.Value = 1
						if events.Notify then 
							events.Notify:FireClient(player, "💤 Put " .. targetPlayer.Name .. " to sleep!")
							events.Notify:FireClient(targetPlayer, "💤 You fell asleep! Skip next turn.")
						end
					end
				end
				
				-- 3. ROBBERY (Steal 50% Coins)
				if cardName == "Robbery" then
					local targetMoney = targetPlayer.leaderstats.Money
					local stealAmount = math.floor(targetMoney.Value * 0.5)
					
					if stealAmount > 0 then
						targetMoney.Value -= stealAmount
						player.leaderstats.Money.Value += stealAmount
						
						if events.Notify then
							events.Notify:FireClient(player, "💰 Stole " .. stealAmount .. " from " .. targetPlayer.Name .. "!")
							events.Notify:FireClient(targetPlayer, "💸 " .. player.Name .. " stole " .. stealAmount .. " coins from you!")
						end
					else
						if events.Notify then events.Notify:FireClient(player, "Target has no money!") end
					end
				end
				
				-- 4. PUSH BACK (Move back 3 Spaces)
				if cardName == "Push Back" then
					local currentPos = playerManager.playerPositions[targetPlayer.UserId] or 0
					local newPos = currentPos - 3
					if newPos < 0 then newPos = 0 end -- Clamp to 0 (Start) for simplicity
					
					playerManager.playerPositions[targetPlayer.UserId] = newPos
					playerManager.teleportToLastTile(targetPlayer, game.Workspace:WaitForChild("Tiles"))
					
					if events.Notify then
						events.Notify:FireClient(player, "💨 Pushed " .. targetPlayer.Name .. " back 3 spaces!")
						events.Notify:FireClient(targetPlayer, "💨 You were pushed back 3 spaces!")
					end
				end
			end
			
			if events.Notify then
				events.Notify:FireClient(player, "✅ Used " .. cardName .. "!")
			end
			
			if events.Notify then
				events.Notify:FireClient(player, "✅ Used " .. cardName .. "!")
			end
			
			-- 5. Special logic if card affects movement or stats could go here
		end)
	end
end

return CardSystem

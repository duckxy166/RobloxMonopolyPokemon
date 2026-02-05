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
	print("📂 Loaded CardDB Contents:")
	for name, _ in pairs(CardDB.Cards) do
		print("   - " .. tostring(name))
	end
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

-- Validate Hand (Cleanup Legacy Cards)
function CardSystem.validateHand(player)
	local hand = CardSystem.getHandFolder(player)
	if not hand then return end
	
	print("🔍 [CardSystem] Validating hand for " .. player.Name)
	for _, card in ipairs(hand:GetChildren()) do
		print("   🃏 Found card: " .. card.Name .. " (Count: " .. tostring(card.Value) .. ")")
		
		if card.Name == "Full Heal" then
			print("🧹 [CardSystem] Removing legacy 'Full Heal' card from " .. player.Name)
			
			-- Check if they already have Revive
			local reviveCard = hand:FindFirstChild("Revive")
			if reviveCard then
				reviveCard.Value += card.Value
				card:Destroy()
				print("   ✨ Merged into existing 'Revive'")
			else
				card.Name = "Revive"
				-- card.Value remains the same (count)
				print("   ✨ Swapped to 'Revive'")
			end
		end
	end
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

-- Get player's hand limit (Trainer gets 6)
function CardSystem.getHandLimit(player)
	local job = player:GetAttribute("Job")
	if job == "Trainer" then
		return 6
	end
	return CardSystem.HAND_LIMIT
end

-- Add card to player hand
function CardSystem.addCardToHand(player, cardId)
	local hand = CardSystem.getHandFolder(player)
	if not hand then return false, "no_hand" end
	local handLimit = CardSystem.getHandLimit(player)
	if CardSystem.countHand(player) >= handLimit then
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

	local handLimit = CardSystem.getHandLimit(player)
	if CardSystem.countHand(player) >= handLimit then
		if notifyEvent then 
			notifyEvent:FireClient(player, "Hand is full (" .. handLimit .. " cards)! Discard or use cards first!") 
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
			print("🃏 Playing card: " .. cardName)
			local cardDef = CardDB.Cards[cardName]
			
			-- Validate card exists in CardDB
			if not cardDef then
				if events.Notify then events.Notify:FireClient(player, "❌ Unknown card: " .. cardName) end
				return
			end
			
			-- Turn validation: Block cards during other players' turns
			local currentPlayer = playerManager.playersInGame[turnManager.currentTurnIndex]
			if currentPlayer and player ~= currentPlayer then
				if events.Notify then 
					events.Notify:FireClient(player, "❌ Cannot use cards during another player's turn!") 
				end
				return
			end
			
			-- Protective Goggles is passive only (auto-activates when attacked)
			if cardName == "Protective Goggles" then
				if events.Notify then
					events.Notify:FireClient(player, "🛡️ Protective Goggles activates automatically when you're attacked!")
				end
				return
			end
			
			-- Consume the card from hand first
			if not CardSystem.removeCardFromHand(player, cardName, 1) then
				if events.Notify then events.Notify:FireClient(player, "❌ You don't have that card!") end
				return
			end
			CardSystem.discardCard(cardName)
			
			-- [C] Revive (Single Pokemon)
			if cardDef and cardDef.NeedsSelfPokemon then
				local pokeName = targetInfo -- Pass pokemon name as targetInfo
				if pokeName and typeof(pokeName) == "string" then
					local inventory = player:FindFirstChild("PokemonInventory")
					if inventory then
						local found = false
						for _, poke in ipairs(inventory:GetChildren()) do
							-- Check name AND status
							if poke.Name == pokeName and (poke:GetAttribute("Status") == "Dead" or poke:GetAttribute("Status") == "Fainted") then
								poke:SetAttribute("Status", "Alive")
								poke:SetAttribute("CurrentHP", poke:GetAttribute("MaxHP"))
								found = true
								if events.Notify then 
							events.Notify:FireClient(player, "💖 Revived " .. pokeName .. "!")
							events.Notify:FireAllClients("💖 " .. player.Name .. " revived " .. pokeName .. "!")
						end
								break -- Only revive one
							end
						end
						if not found then
							-- Fallback if name not found or already alive (refund logic could go here)
							if events.Notify then events.Notify:FireClient(player, "⚠️ Pokemon not found or already alive.") end
						end
					end
				else
					if events.Notify then events.Notify:FireClient(player, "❌ Select a pokemon to revive!") end
				end
			end
			
			-- [A] MoneyGain Cards (Nugget, etc.)
			if cardDef.MoneyGain then
				local amount = cardDef.MoneyGain
				player.leaderstats.Money.Value += amount
				if events.Notify then 
					events.Notify:FireClient(player, "💰 +" .. amount .. " coins!")
					events.Notify:FireAllClients("💰 " .. player.Name .. " used " .. cardName .. " and gained " .. amount .. " coins!")
				end
			end
			
			-- [B] Draw Cards (Lucky Draw, etc.)
			if cardDef.Draw then
				local drawCount = cardDef.Draw
				for i = 1, drawCount do
					CardSystem.drawOneCard(player)
				end
				if events.Notify then
					events.Notify:FireAllClients("🃏 " .. player.Name .. " used " .. cardName .. " and drew " .. drawCount .. " cards!")
				end
			end
			
			-- [C] Special Cards
			if cardName == "Rare Candy" then
				local EvolutionSystem = require(script.Parent:WaitForChild("EvolutionSystem"))
				local success = EvolutionSystem.tryEvolve(player)
				if events.Notify then
					if success then
						events.Notify:FireAllClients("🍬 " .. player.Name .. " used Rare Candy and evolved a Pokemon!")
					else
						player.leaderstats.Money.Value += 3
						events.Notify:FireClient(player, "🍬 No evolution possible. +3 Coins instead.")
						events.Notify:FireAllClients("🍬 " .. player.Name .. " used Rare Candy (+3 coins)")
					end
				end
			end
			
			-- TARGET CARD LOGIC
			if cardDef and cardDef.NeedsTarget then
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
                    local goggles = targetHand and targetHand:FindFirstChild("Protective Goggles")
                    
                    if goggles and events.RequestReaction then
						-- Notify Attacker
						if events.Notify then events.Notify:FireClient(player, "⏳ Waiting for response...") end
						
                        local decision = events.RequestReaction:InvokeClient(targetPlayer, player.Name, cardName)
                        if decision then
                            blocked = true
                            CardSystem.removeCardFromHand(targetPlayer, "Protective Goggles", 1)
                            
                            if events.Notify then
                                events.Notify:FireClient(player, "🛡️ Attack BLOCKED by Protective Goggles!")
                                events.Notify:FireClient(targetPlayer, "🛡️ You blocked the attack!")
                            end
                            -- UI Notification to all players
                            if events.CardNotification then
                                events.CardNotification:FireAllClients({
                                    CardName = "Protective Goggles",
                                    UserName = targetPlayer.Name,
                                    TargetName = player.Name,
                                    CardType = "Defense",
                                    Message = "Blocked " .. cardName .. " from " .. player.Name .. "!"
                                })
                            end
                        end
                    end
                end
                
                if blocked then return end

				-- 1. TWISTED SPOON (Teleport to Target + Trigger Tile Event) - Unblockable  
				if cardName == "Twisted Spoon" then
					local targetPos = playerManager.playerPositions[targetPlayer.UserId]
					local currentPos = playerManager.playerPositions[player.UserId] or 0
					
					-- ANTI-EXPLOIT: Prevent warping to tile 0 (Sell Center) to avoid lap skipping
					if targetPos == 0 then
						if events.Notify then
							events.Notify:FireClient(player, "❌ Cannot warp to Sell Center (Tile 0)! Choose another target.")
						end
						-- Refund the card
						CardSystem.addCardToHand(player, cardName)
						return
					end
					
					playerManager.playerPositions[player.UserId] = targetPos
					
					if player.Character and targetPlayer.Character then
						player.Character:SetPrimaryPartCFrame(targetPlayer.Character.PrimaryPart.CFrame + Vector3.new(3, 0, 0))
					end
					
					if events.Notify then
						events.Notify:FireClient(player, "🔮 Warped to " .. targetPlayer.Name .. "!")
						events.Notify:FireClient(targetPlayer, "🔮 " .. player.Name .. " warped to you!")
					end
					-- UI Notification to all players
					if events.CardNotification then
						events.CardNotification:FireAllClients({
							CardName = "Twisted Spoon",
							UserName = player.Name,
							TargetName = targetPlayer.Name,
							CardType = "Warp",
							Message = "Teleported to " .. targetPlayer.Name .. "!"
						})
					end
					
					-- Trigger tile event at new position (skips dice roll)
					task.spawn(function()
						task.wait(0.5)
						local tilesFolder = game.Workspace:FindFirstChild("Tiles")
						local tile = tilesFolder and tilesFolder:FindFirstChild(tostring(targetPos))
						if tile and turnManager.processTileEvent then
							turnManager.processTileEvent(player, targetPos, tile)
						else
							-- Fallback to next turn if tile not found
							turnManager.nextTurn()
						end
					end)
					return -- Early return to skip "Used card" message since this card handles its own flow
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
						-- UI Notification to all players
						if events.CardNotification then
							events.CardNotification:FireAllClients({
								CardName = "Sleep Powder",
								UserName = player.Name,
								TargetName = targetPlayer.Name,
								CardType = "Attack",
								Message = targetPlayer.Name .. " will skip next turn!"
							})
						end
					end
				end
				
				-- 3. GRABBER (Steal 5 Coins)
				if cardName == "Grabber" then
					local targetMoney = targetPlayer.leaderstats.Money
					local stealAmount = math.min(5, targetMoney.Value)
					
					if stealAmount > 0 then
						targetMoney.Value -= stealAmount
						player.leaderstats.Money.Value += stealAmount
						
						if events.Notify then
							events.Notify:FireClient(player, "💰 Stole " .. stealAmount .. " from " .. targetPlayer.Name .. "!")
							events.Notify:FireClient(targetPlayer, "💸 " .. player.Name .. " stole " .. stealAmount .. " coins from you!")
						end
						-- UI Notification to all players
						if events.CardNotification then
							events.CardNotification:FireAllClients({
								CardName = "Grabber",
								UserName = player.Name,
								TargetName = targetPlayer.Name,
								CardType = "Attack",
								Message = "Stole $" .. stealAmount .. "!"
							})
						end
					else
						if events.Notify then events.Notify:FireClient(player, "Target has no money!") end
					end
				end
				
				-- 4. AIR BALLOON (Move back 3 Spaces)
				if cardName == "Air Balloon" then
					local currentPos = playerManager.playerPositions[targetPlayer.UserId] or 0
					local newPos = currentPos - 3
					if newPos < 0 then newPos = 0 end -- Clamp to 0 (Start) for simplicity
					
					playerManager.playerPositions[targetPlayer.UserId] = newPos
					playerManager.teleportToLastTile(targetPlayer, game.Workspace:WaitForChild("Tiles"))
					
					if events.Notify then
						events.Notify:FireClient(player, "🎈 Pushed " .. targetPlayer.Name .. " back 3 spaces!")
						events.Notify:FireClient(targetPlayer, "🎈 You were pushed back 3 spaces!")
						-- Broadcast to all
						events.Notify:FireAllClients("🎈 " .. player.Name .. " pushed " .. targetPlayer.Name .. " back 3 spaces!")
					end
					-- UI Notification to all players
					if events.CardNotification then
						events.CardNotification:FireAllClients({
							CardName = "Air Balloon",
							UserName = player.Name,
							TargetName = targetPlayer.Name,
							CardType = "Attack",
							Message = targetPlayer.Name .. " pushed back 3 tiles!"
						})
					end
				end
			end
			
			if events.Notify then
				events.Notify:FireClient(player, "✅ Used " .. cardName .. "!")
			end
			
			-- 5. Special logic if card affects movement or stats could go here
		end)
	end

	-- Discard Card Event Handler
	if events.DiscardCard then
		events.DiscardCard.OnServerEvent:Connect(function(player, cardName)
			if CardSystem.removeCardFromHand(player, cardName, 1) then
				CardSystem.discardCard(cardName)
				if events.Notify then
					events.Notify:FireClient(player, "🗑️ Discarded: " .. cardName)
				end
			end
		end)
	end
end

return CardSystem

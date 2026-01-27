--[[
================================================================================
                      🎮 GAME LOOP SCRIPT - Pokemon Monopoly Core
================================================================================
    📌 Location: ServerScriptService
    📌 Responsibilities:
        - Turn-based game management
        - Tile-based movement logic
        - Pokemon spawning/catching
        - Card System (Draw/Play/Discard)
        - Shop logic (Item purchasing)
        - Player notifications (UI Events)
    
    📌 Dependencies:
        - CardDB (ModuleScript in ServerStorage)
        - PokemonModels (Folder in ServerStorage)
        - Tiles (Folder in Workspace)
        
    📌 Version: 1.0
================================================================================
--]]
-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")


-- 1. Initialize Events FIRST (to prevent client infinite yields)
local function getOrCreateEvent(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
		print("🔹 Created RemoteEvent: " .. name)
	end
	return ev
end

local drawCardEvent = getOrCreateEvent("DrawCardEvent")
local playCardEvent = getOrCreateEvent("PlayCardEvent")
local rollEvent = getOrCreateEvent("RollDiceEvent") 
local encounterEvent = getOrCreateEvent("EncounterEvent")
local catchEvent = getOrCreateEvent("CatchPokemonEvent")
local runEvent = getOrCreateEvent("RunEvent")
local updateTurnEvent = getOrCreateEvent("UpdateTurnEvent")
local notifyEvent = getOrCreateEvent("NotifyEvent")
local shopEvent = getOrCreateEvent("ShopEvent")
local useItemEvent = getOrCreateEvent("UseItemEvent")
local endTurnEvent = getOrCreateEvent("EndTurnEvent")
local phaseEvent = getOrCreateEvent("PhaseChangeEvent")
local timerUpdateEvent = getOrCreateEvent("TimerUpdateEvent") -- NEW: broadcasts countdown to clients



-- Deck variables


-- CARD DATABASE MODULE
-- Wait for it safely
local CardDBModule = ReplicatedStorage:WaitForChild("CardDB", 10)
if not CardDBModule then
	warn("🚨 CRITICAL: CardDB not found in ReplicatedStorage! Please check file location.")
	-- Create dummy to prevent crash
	CardDBModule = Instance.new("ModuleScript")
	CardDBModule.Name = "CardDB"
	CardDBModule.Parent = ReplicatedStorage
end
local CardDB = require(CardDBModule)

-- Deck variables
local deck = {}         -- draw pile
local discardPile = {}  -- discard pile

-- Shuffle helper (Fisher-Yates)
-- @param t : table to shuffle
local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

-- Refill deck from discard pile
local function refillDeckIfEmpty()
	if #deck > 0 then return end
	if #discardPile == 0 then
		-- Build new deck if both piles are empty
		deck = CardDB:BuildDeck()
		shuffle(deck)
		return
	end
	deck = discardPile
	discardPile = {}
	shuffle(deck)
end

-- Helper to get player leaderstats
-- @return money, balls parts
local function getLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Money"), ls and ls:FindFirstChild("Pokeballs")
end

-- ==========================================
-- 1. Events Setup
-- ==========================================
local rollEvent = ReplicatedStorage:FindFirstChild("RollDiceEvent") 
local encounterEvent = ReplicatedStorage:FindFirstChild("EncounterEvent")
local catchEvent = ReplicatedStorage:FindFirstChild("CatchPokemonEvent")
local runEvent = ReplicatedStorage:FindFirstChild("RunEvent")
local updateTurnEvent = ReplicatedStorage:FindFirstChild("UpdateTurnEvent")
local notifyEvent = ReplicatedStorage:FindFirstChild("NotifyEvent")
local shopEvent = ReplicatedStorage:FindFirstChild("ShopEvent")
local useItemEvent = ReplicatedStorage:FindFirstChild("UseItemEvent")
local playerInShop = {} -- [userId] = true/false (Is player currently in shop UI)

-- Events are already initialized at the top!

-- Item Usage Handler
useItemEvent.OnServerEvent:Connect(function(player, itemName)
	local itemsFolder = player:FindFirstChild("Items")
	local item = itemsFolder and itemsFolder:FindFirstChild(itemName)

	if item then
		-- Item Effect logic
		if itemName == "Rare Candy" then
			player.leaderstats.Money.Value += 10
		elseif itemName == "Repel" then
			playerRepelSteps[player.UserId] = 3
		elseif itemName == "Revive" then
			player.leaderstats.Pokeballs.Value += 2
		end

		item:Destroy() -- Consume item
		print("✅ " .. player.Name .. " used " .. itemName)
	end
end)

-- HAND SYSTEM - Card Management
-- Players can hold up to 5 cards (HAND_LIMIT)
local HAND_LIMIT = 5

-- Get hand folder
local function getHandFolder(player)
	return player:FindFirstChild("Hand")
end

-- Count total cards in hand (sum of stack sizes)
local function countHand(player)
	local hand = getHandFolder(player)
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
-- @param cardId : id from CardDB
-- @return true if success, false + reason if failed
local function addCardToHand(player, cardId)
	local hand = getHandFolder(player)
	if not hand then return false, "no_hand" end
	if countHand(player) >= HAND_LIMIT then
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
local function removeCardFromHand(player, cardId, amount)
	amount = amount or 1
	local hand = getHandFolder(player)
	if not hand then return false end

	local slot = hand:FindFirstChild(cardId)
	if not slot or not slot:IsA("IntValue") then return false end
	if slot.Value < amount then return false end

	slot.Value -= amount
	if slot.Value <= 0 then slot:Destroy() end
	return true
end

-- Draw one card from deck
local function drawOneCard(player)
	refillDeckIfEmpty()

	if countHand(player) >= HAND_LIMIT then
		if notifyEvent then notifyEvent:FireClient(player, "Hand is full (5 cards)! Discard or use cards first!") end
		return nil
	end

	local cardId = table.remove(deck, 1)
	if not cardId then return nil end

	local ok = addCardToHand(player, cardId)
	if ok then
		if notifyEvent then
			local def = CardDB.Cards[cardId]
			notifyEvent:FireClient(player, ("Card drawn: %s"):format(def and def.Name or cardId))
		end
		return cardId
	end

	table.insert(deck, 1, cardId) -- return card to deck if failed
	return nil
end



-- Create PlayCardEvent if not exists
if not shopEvent then shopEvent = Instance.new("RemoteEvent", ReplicatedStorage); shopEvent.Name = "ShopEvent" end
if not useItemEvent then useItemEvent = Instance.new("RemoteEvent", ReplicatedStorage); useItemEvent.Name = "UseItemEvent" end
if not notifyEvent then notifyEvent = Instance.new("RemoteEvent", ReplicatedStorage); notifyEvent.Name = "NotifyEvent" end
if not rollEvent then rollEvent = Instance.new("RemoteEvent", ReplicatedStorage); rollEvent.Name = "RollDiceEvent" end
if not encounterEvent then encounterEvent = Instance.new("RemoteEvent", ReplicatedStorage); encounterEvent.Name = "EncounterEvent" end
if not catchEvent then catchEvent = Instance.new("RemoteEvent", ReplicatedStorage); catchEvent.Name = "CatchPokemonEvent" end
if not runEvent then runEvent = Instance.new("RemoteEvent", ReplicatedStorage); runEvent.Name = "RunEvent" end
if not updateTurnEvent then updateTurnEvent = Instance.new("RemoteEvent", ReplicatedStorage); updateTurnEvent.Name = "UpdateTurnEvent" end

-- ==========================================
-- Variables & Config
-- ==========================================
local tilesFolder = Workspace:WaitForChild("Tiles")
local centerStage = Workspace:WaitForChild("CenterStage")
centerStage.Transparency = 1 -- Hide by default
centerStage.CanCollide = false
local pokemonModels = ServerStorage:WaitForChild("PokemonModels")

local playerPositions = {}
local playerRepelSteps = {} 
local currentSpawnedPokemon = nil 
local playersInGame = {} 
local currentTurnIndex = 1 
local isTurnActive = false 

-- TOKEN OFFSET SYSTEM (4 players per tile)
local playerSlots = {} -- [userId] = slot (1-4)
local TOKEN_OFFSETS = {
	[1] = Vector3.new(-2, 0, -2),  -- Front-Left
	[2] = Vector3.new(2, 0, -2),   -- Front-Right
	[3] = Vector3.new(-2, 0, 2),   -- Back-Left
	[4] = Vector3.new(2, 0, 2),    -- Back-Right
}

-- TIMER SYSTEM
local turnPhase = "Idle" -- Draw, Roll, Event
local turnTimerTask = nil
local DRAW_TIMEOUT = 10
local ROLL_TIMEOUT = 30
local SHOP_TIMEOUT = 20
local ENCOUNTER_TIMEOUT = 10

local POKEMON_DB = {
	{ Name = "Bulbasaur", Rarity = "Common", ModelName = "Bulbasaur" }, 
	{ Name = "Charmander", Rarity = "Common", ModelName = "Charmander" },
	{ Name = "Squirtle", Rarity = "Common", ModelName = "Squirtle" },
	{ Name = "Pikachu", Rarity = "Rare", ModelName = "Pikachu" },
	{ Name = "Mewtwo", Rarity = "Legendary", ModelName = "Mewtwo" }
}
local DIFFICULTY = { ["Common"] = 2, ["Rare"] = 4, ["Legendary"] = 6 }

-- Clear spawned pokemon from center stage
local function clearCenterStage()
	if currentSpawnedPokemon then currentSpawnedPokemon:Destroy(); currentSpawnedPokemon = nil end
	centerStage.Transparency = 1 -- Hide stage
end

-- Get player's position on tile with offset (so 4 players don't stack)
local function getPlayerTilePosition(player, tile)
	local slot = playerSlots[player.UserId] or 1
	local offset = TOKEN_OFFSETS[slot] or Vector3.new(0, 0, 0)
	return tile.Position + offset + Vector3.new(0, 3, 0) -- 3 studs above tile
end

-- Teleport player to their last tile position
local function teleportToLastTile(player)
	local tileIndex = playerPositions[player.UserId] or 0
	local tile = tilesFolder:FindFirstChild(tostring(tileIndex))
	local char = player.Character
	if tile and char and char.PrimaryPart then
		char:SetPrimaryPartCFrame(CFrame.new(getPlayerTilePosition(player, tile)))
		print("Reset: Teleported " .. player.Name .. " to tile " .. tileIndex)
	end
end

-- Walking Logic
-- Handles player movement across tiles
-- Actions based on Tile Color: White=Shop, Green=Encounter, Others=Draw Card
local function processPlayerRoll(player)
	print("📊 [Server] processPlayerRoll called by:", player.Name)
	print("📊 [Server] isTurnActive:", isTurnActive)
	print("📊 [Server] currentTurnIndex:", currentTurnIndex)
	print("📊 [Server] processPlayerRoll called by:", player.Name)
	print("📊 [Server] isTurnActive:", isTurnActive)
	print("📊 [Server] currentTurnIndex:", currentTurnIndex)
	if #playersInGame > 0 then
		print("📊 [Server] playersInGame[currentTurnIndex]:", playersInGame[currentTurnIndex] and playersInGame[currentTurnIndex].Name or "nil")
	else
		print("⚠️ [Server] No players in game table!")
	end

	if not isTurnActive then 
		print("? [Server] isTurnActive is false! Returning...")
		return 
	end
	if player ~= playersInGame[currentTurnIndex] then 
		print("? [Server] Not this player's turn! Returning...")
		return 
	end

	print("? [Server] Processing roll for:", player.Name)
	isTurnActive = false 
	clearCenterStage()

	-- roll dice
	local roll = math.random(1, 6)
	-- local roll = 3 -- rigged for testing

	print("🎲 [Server] Roll result:", roll)
	rollEvent:FireAllClients(player, roll) 
	task.wait(2.5) 

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local currentPos = playerPositions[player.UserId] or 0
	local repelLeft = playerRepelSteps[player.UserId] or 0

	for i = 1, roll do
		currentPos = currentPos + 1
		local nextTile = tilesFolder:FindFirstChild(tostring(currentPos))

		if nextTile and humanoid then
			-- Use offset position so players don't stack
			humanoid:MoveTo(getPlayerTilePosition(player, nextTile))
			humanoid.MoveToFinished:Wait()

			if repelLeft > 0 then repelLeft = repelLeft - 1; playerRepelSteps[player.UserId] = repelLeft end

			if i == roll then
				local tileColor = string.lower(nextTile.BrickColor.Name)

				if string.find(tileColor, "white") then
					-- [[ SHOP TILE ]] --
					print("Landed on Shop! Opening shop...")

					-- Set position
					playerPositions[player.UserId] = currentPos

					-- Set shop flag
					playerInShop[player.UserId] = true

					shopEvent:FireClient(player)
					
					-- Start Shop Timer (20 seconds) with countdown
					turnPhase = "Shop"
					startPhaseTimer(SHOP_TIMEOUT, "Shop", function()
						if turnPhase == "Shop" and player == playersInGame[currentTurnIndex] then
							print("Timer: Shop timeout, auto-closing for " .. player.Name)
							playerInShop[player.UserId] = false
							nextTurn()
						end
					end)
					return


				elseif string.find(tileColor, "green") then
					-- Encounter tile
					if repelLeft > 0 then nextTurn() else spawnPokemonEncounter(player) end
				else
					drawOneCard(player)
					nextTurn()
				end
			end
		else
			currentPos = 0
			if humanoid then 
				local startTile = tilesFolder:FindFirstChild("0")
				if startTile then character:SetPrimaryPartCFrame(startTile.CFrame + Vector3.new(0,5,0)) end
			end
			nextTurn()
			break
		end
	end
	playerPositions[player.UserId] = currentPos
end


-- CARD EVENT HANDLER
-- Utility to block negative effects with Shield
-- @return true if blocked
local function tryBlockNegative(targetPlayer)
	local status = targetPlayer:FindFirstChild("Status")
	if not status then return false end

	local shield = status:FindFirstChild("Shield")
	if shield and shield.Value == true then
		shield.Value = false -- Shield used once
		return true
	end
	return false
end

-- Move player back X steps
local function moveBackSteps(targetPlayer, steps)
	local uid = targetPlayer.UserId
	local currentPos = playerPositions[uid] or 0
	local newPos = math.max(0, currentPos - steps)
	playerPositions[uid] = newPos

	local char = targetPlayer.Character
	local startTile = tilesFolder:FindFirstChild(tostring(newPos))
	if char and startTile and char.PrimaryPart then
		char:SetPrimaryPartCFrame(startTile.CFrame + Vector3.new(0,5,0))
	end
end

playCardEvent.OnServerEvent:Connect(function(player, cardId, targetUserId)
	-- Check if player turn
	if player ~= playersInGame[currentTurnIndex] then return end

	local def = CardDB.Cards[cardId]
	if not def then return end

	-- Remove card from hand
	if not removeCardFromHand(player, cardId, 1) then
		if notifyEvent then notifyEvent:FireClient(player, "Card not in hand!") end
		return
	end

	-- Verify target player if needed
	local targetPlayer = nil
	if def.NeedsTarget then
		for _, p in ipairs(playersInGame) do
			if p.UserId == targetUserId then
				targetPlayer = p
				break
			end
		end
		if not targetPlayer then
			-- Return card if invalid target
			addCardToHand(player, cardId)
			if notifyEvent then notifyEvent:FireClient(player, "Invalid target!") end
			return
		end
	end

	-- If negative card, check if target has Shield
	if targetPlayer and def.Negative then
		if tryBlockNegative(targetPlayer) then
			table.insert(discardPile, cardId)
			if notifyEvent then
				notifyEvent:FireClient(player, "Target blocked with Safety Shield!")
				notifyEvent:FireClient(targetPlayer, "Your Safety Shield blocked an attack!")
			end
			return
		end
	end

	-- Apply card effects
	local money, balls = getLeaderstats(player)

	if def.MoneyGain and money then
		money.Value += def.MoneyGain
	end

	if def.Steal and targetPlayer then
		local tMoney = getLeaderstats(targetPlayer)
		local stealAmt = def.Steal
		if tMoney then
			local stolen = math.min(stealAmt, tMoney.Value)
			tMoney.Value -= stolen
			if money then money.Value += stolen end
		end
	end

	if def.Discard and def.MoneyGain and money then
		-- Try Discard-to-Money effect
		local need = def.Discard

		-- Check if enough cards to discard
		if countHand(player) < need then
			addCardToHand(player, cardId) -- Return original card
			if notifyEvent then notifyEvent:FireClient(player, "Need " .. need .. " cards to discard!") end
			return
		end

		local hand = getHandFolder(player)
		local discarded = 0
		for _, slot in ipairs(hand:GetChildren()) do
			if discarded >= need then break end
			if slot:IsA("IntValue") and slot.Value > 0 then
				slot.Value -= 1
				if slot.Value <= 0 then slot:Destroy() end
				discarded += 1
			end
		end

		money.Value += def.MoneyGain
	end


	if def.BackSteps and targetPlayer then
		moveBackSteps(targetPlayer, def.BackSteps)
	end

	if def.Draw then
		for i = 1, def.Draw do
			drawOneCard(player)
		end
	end

	if def.Cleanse then
		local status = player:FindFirstChild("Status")
		if status then
			local sleep = status:FindFirstChild("SleepTurns")
			if sleep then sleep.Value = 0 end
		end
	end

	if def.Shield then
		local status = player:FindFirstChild("Status")
		if status then
			local shield = status:FindFirstChild("Shield")
			if shield then shield.Value = true end
		end
	end

	if def.SleepTurns and targetPlayer then
		local status = targetPlayer:FindFirstChild("Status")
		if status then
			local sleep = status:FindFirstChild("SleepTurns")
			if sleep then sleep.Value += def.SleepTurns end
		end
	end

	if def.AddBalls and balls then
		balls.Value += def.AddBalls
	end

	-- TODO: RareCandy / TradeTicket (needs extra logic) - add later

	-- Finally: add to discard pile
	table.insert(discardPile, cardId)

	if notifyEvent then notifyEvent:FireClient(player, "Card used successfully!") end
end)

-- Turn Management logic
-- Handles Sleep status and turn cycling
function nextTurn()
	print("🔄 [Server] nextTurn() called")
	task.wait(1)
	if #playersInGame == 0 then 
		print("⚠️ [Server] No players in game!")
		return 
	end

	for _ = 1, #playersInGame do
		currentTurnIndex += 1
		if currentTurnIndex > #playersInGame then currentTurnIndex = 1 end

		local p = playersInGame[currentTurnIndex]
		local status = p:FindFirstChild("Status")
		local sleep = status and status:FindFirstChild("SleepTurns")

		if sleep and sleep.Value > 0 then
			sleep.Value -= 1
			if notifyEvent then notifyEvent:FireClient(p, "You are asleep! Turn skipped!") end
		else
			isTurnActive = true
			playerInShop[p.UserId] = false
			print("🎲 [Server] Turn started for:", p.Name, "| isTurnActive:", isTurnActive)
			-- Start with Draw Phase (Timer System)
			enterDrawPhase(p)
			return
		end
	end
end


-- ===========================
-- Shop System (separate from main loop)
-- ===========================
local shopDebounce = {} -- [userId] = timestamp

shopEvent.OnServerEvent:Connect(function(player, action)
	-- Apply card effects
	if player ~= playersInGame[currentTurnIndex] then return end

	-- Check if player is in shop (prevent invalid events)
	if not playerInShop[player.UserId] then
		warn("❌ Player not in shop but tried:", player.Name, action)
		return
	end

	-- Debounce to prevent multiple clicks
	local now = os.clock()
	if shopDebounce[player.UserId] and (now - shopDebounce[player.UserId]) < 0.12 then
		return
	end
	shopDebounce[player.UserId] = now

	print("Shop Server: Action = " .. tostring(action))

	if action == "Buy" then
		local leaderstats = player:FindFirstChild("leaderstats")
		local money = leaderstats and leaderstats:FindFirstChild("Money")
		local balls = leaderstats and leaderstats:FindFirstChild("Pokeballs")

		if money and balls then
			local price = 2
			if money.Value >= price then
				money.Value -= price
				balls.Value += 1

				-- Notify client of purchase result
				if notifyEvent then
					notifyEvent:FireClient(player, ("Bought Pokeball +1 (Money left: %d)"):format(money.Value))
				end
			else
				if notifyEvent then
					notifyEvent:FireClient(player, "Not enough money!")
				end
			end
		end
		-- Don't end turn after Buy - allow multiple purchases
		return
	end

	-- Exit action - close shop and end turn
	if action == "Exit" then
		print("Player finished shop action: Exit -> End Turn")
		cancelTimer()
		playerInShop[player.UserId] = false
		task.wait(0.5)
		nextTurn()
	end
end)

-- Pokemon Spawning (Physics based)
-- Spawns pokemon above center stage and applies physics stabilizers
function spawnPokemonEncounter(player)
	local randomPoke = POKEMON_DB[math.random(1, #POKEMON_DB)]
	local modelTemplate = pokemonModels:FindFirstChild(randomPoke.ModelName)

	if modelTemplate then
		centerStage.Transparency = 0 -- Show stage
		local clonedModel = modelTemplate:Clone()

		-- 1. Position above center stage
		clonedModel:PivotTo(centerStage.CFrame + Vector3.new(0, 20, 0)) 
		clonedModel.Parent = Workspace
		currentSpawnedPokemon = clonedModel

		-- 2. Find MainPart
		local mainPart = clonedModel.PrimaryPart or clonedModel:FindFirstChild("HumanoidRootPart") or clonedModel:FindFirstChildWhichIsA("BasePart", true)
		local pokeHumanoid = clonedModel:FindFirstChild("Humanoid")

		if mainPart then
			-- 3. Weld all parts together
			for _, part in pairs(clonedModel:GetDescendants()) do
				if part:IsA("BasePart") and part ~= mainPart then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = mainPart
					weld.Part1 = part
					weld.Parent = mainPart

					part.Anchored = false
					part.CanCollide = false
					part.Massless = true
				end
			end

			-- 4. Set main part physics
			mainPart.Anchored = false 
			mainPart.CanCollide = true 
			mainPart.Massless = false

			-- 5. Add stabilizer (BodyGyro)
			local gyro = Instance.new("BodyGyro")
			gyro.Name = "Stabilizer"
			gyro.MaxTorque = Vector3.new(math.huge, 0, math.huge) 
			gyro.P = 5000 
			gyro.CFrame = CFrame.new() 
			gyro.Parent = mainPart

			-- 6. Humanoid settings
			if pokeHumanoid then
				pokeHumanoid.AutomaticScalingEnabled = false
				pokeHumanoid.HipHeight = 0 
			end
		end
	else
		warn("⚠️ Model not found: " .. randomPoke.ModelName)
	end

	encounterEvent:FireAllClients(player, randomPoke)
	
	-- Start Encounter Timer (10 seconds for Catch/Run decision) with countdown
	turnPhase = "Encounter"
	startPhaseTimer(ENCOUNTER_TIMEOUT, "Encounter", function()
		if turnPhase == "Encounter" and player == playersInGame[currentTurnIndex] then
			forceRunAndEnd(player)
		end
	end)
end

-- Lucky Cards & Items Logic
function giveLuckyCard(player)
	local cards = {"Rare Candy", "Repel", "Revive"}
	local pickedCard = cards[math.random(1, #cards)]
	local itemsFolder = player:FindFirstChild("Items")

	if itemsFolder then
		local newCard = Instance.new("StringValue")
		newCard.Name = pickedCard
		newCard.Parent = itemsFolder
		print("Lucky card given: " .. pickedCard)
	end
end


-- Player Setup on Join
-- Initializing Stats: Money=20, Balls=5
-- Creating Hand, Status, and Inventory folders
local function onPlayerAdded(player)
	print("✅ [Server] onPlayerAdded:", player.Name)
	for _, p in ipairs(playersInGame) do if p == player then return end end
	table.insert(playersInGame, player)
	print("👥 [Server] Player added to game! Total players:", #playersInGame)
	playerPositions[player.UserId] = 0 
	playerRepelSteps[player.UserId] = 0 
	
	-- Assign slot (1-4) for token offset positioning
	playerSlots[player.UserId] = #playersInGame -- 1st player = slot 1, etc.

	local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player
	local money = Instance.new("IntValue"); money.Name = "Money"; money.Value = 10; money.Parent = leaderstats
	local balls = Instance.new("IntValue"); balls.Name = "Pokeballs"; balls.Value = 5; balls.Parent = leaderstats
	local inventory = Instance.new("Folder"); inventory.Name = "PokemonInventory" ;inventory.Parent = player

	-- Items folder: for Lucky Cards (Rare Candy, Repel, Revive)
	local items = Instance.new("Folder"); items.Name = "Items"; items.Parent = player

	-- Hand folder: max 5 cards
	local hand = Instance.new("Folder"); hand.Name = "Hand"; hand.Parent = player

	-- Give 3 starter cards
	for i = 1, 3 do
		drawOneCard(player)
	end

	-- Status: shield / sleep
	local status = Instance.new("Folder"); status.Name = "Status"; status.Parent = player
	local shield = Instance.new("BoolValue"); shield.Name = "Shield"; shield.Value = false; shield.Parent = status
	local sleep = Instance.new("IntValue"); sleep.Name = "SleepTurns"; sleep.Value = 0; sleep.Parent = status

	-- Give Starter Pokemon
	local starterPoke = Instance.new("StringValue")
	starterPoke.Name = "Bulbasaur"
	starterPoke.Value = "Common" 
	starterPoke.Parent = inventory


	if #playersInGame == 1 then 
		print("🚀 [Server] First player joined! Starting game in 3 seconds...")
		task.wait(3)
		currentTurnIndex = 0
		nextTurn() 
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
print("📡 [Server] GameLoopScript loaded! Checking for existing players...")
for _, player in ipairs(Players:GetPlayers()) do 
	print("🔍 [Server] Found existing player:", player.Name)
	onPlayerAdded(player) 
end

Players.PlayerRemoving:Connect(function(player)
	for i, p in ipairs(playersInGame) do
		if p == player then
			table.remove(playersInGame, i)
			if i == currentTurnIndex then currentTurnIndex = currentTurnIndex - 1; nextTurn()
			elseif i < currentTurnIndex then currentTurnIndex = currentTurnIndex - 1 end
			break
		end
	end
end)



rollEvent.OnServerEvent:Connect(function(player) processPlayerRoll(player) end)
catchEvent.OnServerEvent:Connect(function(player, pokeData)
	-- Cancel current encounter timer first
	cancelTimer()
	
	local balls = player.leaderstats.Pokeballs
	balls.Value = balls.Value - 1

	-- 1. Roll Logic
	local target = DIFFICULTY[pokeData.Rarity] or 2
	local roll = math.random(1, 6)
	local success = roll >= target

	-- 2. Rewards on Success
	if success then
		-- Add Pokemon to inventory
		local newPoke = Instance.new("StringValue")
		newPoke.Name = pokeData.Name
		newPoke.Value = pokeData.Rarity
		newPoke.Parent = player.PokemonInventory

		-- Bonus money
		player.leaderstats.Money.Value = player.leaderstats.Money.Value + 5 
	end

	-- 3. Check finish condition
	local isFinished = success or (balls.Value <= 0)

	-- 4. Notify Client (ALL CLIENTS)
	catchEvent:FireAllClients(player, success, roll, target, isFinished)

	-- 5. Handle timer based on result
	if isFinished then 
		-- Give 3 seconds to see result, then end turn
		turnPhase = "CatchResult"
		startPhaseTimer(3, "Result", function()
			clearCenterStage()
			nextTurn()
		end)
	else
		-- Not finished (failed catch, still has balls) - restart encounter timer
		turnPhase = "Encounter"
		startPhaseTimer(ENCOUNTER_TIMEOUT, "Encounter", function()
			if turnPhase == "Encounter" and player == playersInGame[currentTurnIndex] then
				forceRunAndEnd(player)
			end
		end)
	end
end)

runEvent.OnServerEvent:Connect(function(player) 
	cancelTimer() -- Player chose to run
	runEvent:FireAllClients(player) 
	task.wait(1)
	clearCenterStage()

	-- Auto End Turn
	nextTurn()
end)

-- End Turn Handler (Manual)
endTurnEvent.OnServerEvent:Connect(function(player)
	-- Verify it's their turn
	if #playersInGame > 0 and player == playersInGame[currentTurnIndex] then
		print("Server: Player manually ended turn -> Next Turn")
		nextTurn()
	end
end)

-- Reset Character Event Handler (Teleport to last tile)
local resetCharEvent = getOrCreateEvent("ResetCharacterEvent")
resetCharEvent.OnServerEvent:Connect(function(player)
	teleportToLastTile(player)
end)

-- ==========================================
-- PHASE SYSTEM: Timer-based Turn Flow
-- ==========================================
local drawPhaseEvent = getOrCreateEvent("DrawPhaseEvent")

-- Cancel any active timer
local function cancelTimer()
	if turnTimerTask then task.cancel(turnTimerTask); turnTimerTask = nil end
	timerUpdateEvent:FireAllClients(0, "") -- Clear timer on clients
end

-- Start a phase timer with countdown broadcast to clients
-- @param seconds: time in seconds
-- @param phaseName: name of phase for display ("Roll", "Shop", etc.)
-- @param timeoutCallback: function to call when timer expires
local function startPhaseTimer(seconds, phaseName, timeoutCallback)
	cancelTimer()
	timerUpdateEvent:FireAllClients(seconds, phaseName) -- Tell clients to start countdown
	turnTimerTask = task.delay(seconds, function()
		timerUpdateEvent:FireAllClients(0, "") -- Timer ended
		if timeoutCallback then timeoutCallback() end
	end)
end

-- Force run and end encounter (timeout or auto-end)
local function forceRunAndEnd(player)
	print("Timer: Force Run triggered for " .. player.Name)
	cancelTimer()
	runEvent:FireAllClients(player)
	clearCenterStage()
	nextTurn()
end

-- Phase: Draw (Hidden timer - 10s to auto-draw)
function enterDrawPhase(player)
	turnPhase = "Draw"
	isTurnActive = true
	print("Phase: Enter Draw Phase for:", player.Name)
	
	drawPhaseEvent:FireClient(player, "Start")
	
	startPhaseTimer(DRAW_TIMEOUT, "Draw", function()
		if turnPhase == "Draw" and player == playersInGame[currentTurnIndex] then
			print("Timer: Auto-Draw triggered for " .. player.Name)
			performDrawAction(player)
		end
	end)
end

-- Perform draw action (manual or timeout)
function performDrawAction(player)
	if turnPhase ~= "Draw" then return end
	cancelTimer()
	
	drawOneCard(player)
	enterRollPhase(player)
end

-- Phase: Roll (30s timer for card skills + roll)
function enterRollPhase(player)
	turnPhase = "Roll"
	print("Phase: Enter Roll Phase for:", player.Name)
	
	updateTurnEvent:FireAllClients(player.Name) -- UI shows "Your Turn"
	
	startPhaseTimer(ROLL_TIMEOUT, "Roll", function()
		if turnPhase == "Roll" and player == playersInGame[currentTurnIndex] then
			print("Timer: Auto-Roll triggered for " .. player.Name)
			processPlayerRoll(player)
		end
	end)
end

-- Draw Phase Event Handler (manual click from client)
drawPhaseEvent.OnServerEvent:Connect(function(player)
	if player ~= playersInGame[currentTurnIndex] then return end
	performDrawAction(player)
end)


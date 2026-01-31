--[[
================================================================================
                      🎲 TURN MANAGER - Turn Flow & Phases
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Turn cycling
        - Phase management (Draw, Roll, Shop, Encounter)
        - Player movement logic
================================================================================
--]]
local Workspace = game:GetService("Workspace")

local TurnManager = {}

-- State
TurnManager.currentTurnIndex = 0
TurnManager.turnPhase = "Idle"
TurnManager.isTurnActive = false

-- Dependencies
local Events = nil
local TimerSystem = nil
local CardSystem = nil
local PlayerManager = nil
local EncounterSystem = nil
local BattleSystem = nil
local tilesFolder = nil
local PokemonDB = require(game:GetService("ReplicatedStorage"):WaitForChild("PokemonDB"))

-- Initialize with dependencies
function TurnManager.init(events, timerSystem, cardSystem, playerManager)
	Events = events
	TimerSystem = timerSystem
	CardSystem = cardSystem
	PlayerManager = playerManager
	tilesFolder = Workspace:WaitForChild("Tiles")
	print("✅ TurnManager initialized")
end

-- Set dependencies (circular dependency fix)
function TurnManager.setSystems(encounterSys, battleSys)
	EncounterSystem = encounterSys
	BattleSystem = battleSys
end

-- ... (inside processPlayerRoll) ...

-- End Game Logic
function TurnManager.endGame()
	print("🏆 GAME OVER! All players finished.")

	-- Determine Winner (Richest Player)
	local winner = nil
	local maxMoney = -1

	for _, p in ipairs(PlayerManager.playersInGame) do
		local moneyVal = 0
		if p:FindFirstChild("leaderstats") then
			moneyVal = p.leaderstats.Money.Value
		end

		print(p.Name .. " finished with $" .. moneyVal)

		if moneyVal > maxMoney then
			maxMoney = moneyVal
			winner = p
		end
	end

	local msg = "🏆 GAME OVER! Winner: " .. (winner and winner.Name or "None")
	if Events.BattleEnd then
		Events.BattleEnd:FireAllClients(msg) -- Reuse existing announcer
	end

	if Events.Notify and winner then
		Events.Notify:FireAllClients("🏆 " .. winner.Name .. " WINS THE GAME with $" .. maxMoney .. "!")
	end
end

-- Next turn logic
function TurnManager.nextTurn()
	print("🔄 [Server] nextTurn() called")
	task.wait(1)

	if #PlayerManager.playersInGame == 0 then
		print("⚠️ [Server] No players in game!")
		return
	end

	-- Check if everyone finished
	local allFinished = true
	for _, p in ipairs(PlayerManager.playersInGame) do
		if not PlayerManager.playerFinished[p.UserId] then
			allFinished = false
			break
		end
	end

	if allFinished then
		TurnManager.endGame()
		return
	end

	-- Find next valid player
	local attempts = 0
	while attempts < #PlayerManager.playersInGame * 2 do
		attempts = attempts + 1
		TurnManager.currentTurnIndex += 1
		if TurnManager.currentTurnIndex > #PlayerManager.playersInGame then 
			TurnManager.currentTurnIndex = 1 
		end

		local p = PlayerManager.playersInGame[TurnManager.currentTurnIndex]

		-- Skip if player finished
		if PlayerManager.playerFinished[p.UserId] then
			print("⏩ Skipping finished player: " .. p.Name)
			continue
		end

		-- Process Active Player
		local status = p:FindFirstChild("Status")
		local sleep = status and status:FindFirstChild("SleepTurns")

		if sleep and sleep.Value > 0 then
			sleep.Value -= 1
			if Events.Notify then 
				Events.Notify:FireClient(p, "You are asleep! Turn skipped!") 
				-- Broadcast to all
				Events.Notify:FireAllClients("💤 " .. p.Name .. " is asleep! Turn skipped.")
			end
		else
			TurnManager.isTurnActive = true
			PlayerManager.playerInShop[p.UserId] = false
			print("🎲 [Server] Turn started for:", p.Name)
			TurnManager.enterDrawPhase(p)
			return
		end
	end

	print("⚠️ No valid players found to take turn?")
end

-- Enter draw phase (Always draw 1 card at start of turn)
function TurnManager.enterDrawPhase(player)
	TurnManager.turnPhase = "Draw"
	TurnManager.isTurnActive = true
	print("Phase: Draw Phase for:", player.Name)

	-- Highlight Current Turn Player
	local UIHelpers = require(game:GetService("ReplicatedStorage"):WaitForChild("UIHelpers"))
	
	-- Remove highlight from all other players
	for _, p in ipairs(PlayerManager.playersInGame) do
		if p.Character then
			UIHelpers.CreatePlayerHighlight(p.Character, false)
			-- Remove old name label
			local head = p.Character:FindFirstChild("Head")
			if head then
				local oldLabel = head:FindFirstChild("TurnNameLabel")
				if oldLabel then oldLabel:Destroy() end
			end
		end
	end
	
	-- Add highlight to current player
	if player.Character then
		UIHelpers.CreatePlayerHighlight(player.Character, true)
		UIHelpers.CreatePlayerNameLabel(player.Character, player.Name, true)
	end

	-- Force Draw 1 Card
	local drawnCard = CardSystem.drawOneCard(player)

	if drawnCard then
		if Events.Notify then
			-- Notify handled in CardSystem usually, but ensuring feedback
			-- Events.Notify:FireClient(player, "🃏 Drawn a card!") -- CardSystem does this
		end
	else
		-- Determine why (Hand Full or Deck Empty)
		local count = CardSystem.countHand(player)
		if count >= CardSystem.HAND_LIMIT then
			if Events.Notify then Events.Notify:FireClient(player, "⚠️ Hand Full! Cannot draw more.") end
		else
			if Events.Notify then Events.Notify:FireClient(player, "⚠️ Deck Empty! No cards left.") end
		end
	end

	-- Short delay to show card drawn, then go to Roll
	task.wait(1.5)
	TurnManager.enterRollPhase(player)
end

-- Enter roll phase
function TurnManager.enterRollPhase(player)
	TurnManager.turnPhase = "Roll"
	TurnManager.isTurnActive = true  -- IMPORTANT: Allow player to roll
	print("Phase: Enter Roll Phase for:", player.Name)

	-- Check if on same tile as another player (e.g., pushed back here)
	local currentPos = PlayerManager.playerPositions[player.UserId] or 0
	
	-- Skip battle check on start tile (tile 0) to prevent game-start battles
	if currentPos == 0 then
		Events.UpdateTurn:FireAllClients(player.Name)
		TimerSystem.startPhaseTimer(TimerSystem.ROLL_TIMEOUT, "Roll", function()
			if TurnManager.turnPhase == "Roll" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				print("Timer: Auto-Roll triggered for " .. player.Name)
				TurnManager.processPlayerRoll(player)
			end
		end)
		return
	end
	
	local opponents = {}
	for _, otherPlayer in ipairs(PlayerManager.playersInGame) do
		if otherPlayer ~= player and PlayerManager.playerPositions[otherPlayer.UserId] == currentPos then
			table.insert(opponents, otherPlayer)
		end
	end

	if #opponents > 0 and Events.BattleTrigger then
		print("⚔️ PvP Opportunity at turn start for " .. player.Name)
		Events.BattleTrigger:FireClient(player, "PvP", { Opponents = opponents })
		-- The BattleTriggerResponse handler will call resumeTurn or start battle
		return
	end

	Events.UpdateTurn:FireAllClients(player.Name)

	TimerSystem.startPhaseTimer(TimerSystem.ROLL_TIMEOUT, "Roll", function()
		if TurnManager.turnPhase == "Roll" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
			print("Timer: Auto-Roll triggered for " .. player.Name)
			TurnManager.processPlayerRoll(player)
		end
	end)
end


-- Connect events
function TurnManager.connectEvents()
	Events.RollDice.OnServerEvent:Connect(function(player)
		TurnManager.processPlayerRoll(player)
	end)

	-- DrawPhase handler removed (now auto-draw)

	Events.EndTurn.OnServerEvent:Connect(function(player)
		if #PlayerManager.playersInGame > 0 and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
			print("Server: Player manually ended turn -> Next Turn")
			TurnManager.nextTurn()
		end
	end)

	Events.ResetCharacter.OnServerEvent:Connect(function(player)
		PlayerManager.teleportToLastTile(player, tilesFolder)
	end)

	-- New: Handle Starter Selection
	if Events.SelectStarter then
		Events.SelectStarter.OnServerEvent:Connect(function(player, starterName)
			TurnManager.handleStarterSelection(player, starterName)
		end)
	end
end

-- ============================================================================
-- 🎮 GAME START & SELECTION FLOW
-- ============================================================================

TurnManager.readyPlayers = {}
TurnManager.gameStarted = false

function TurnManager.checkPreGameStart()
	-- ALLOW LATE JOINERS: Don't return if gameStarted. 
	-- We still want to check for unready players (late joiners) and show them the UI.
	-- if TurnManager.gameStarted then return end

	print("🔍 Checking Pre-Game Status... Players in game: " .. #PlayerManager.playersInGame)
	
	-- Small delay to ensure client scripts have loaded
	task.spawn(function()
		task.wait(0.5)
		
		for _, p in ipairs(PlayerManager.playersInGame) do
			if not TurnManager.readyPlayers[p.UserId] then
				-- Show Selection UI to unready players
				print("📋 Sending ShowStarterSelection to: " .. p.Name)
				if Events.ShowStarterSelection then
					Events.ShowStarterSelection:FireClient(p)
				end
			else
				print("✅ Player " .. p.Name .. " already ready, skipping...")
			end
		end
	end)
end

function TurnManager.handleStarterSelection(player, starterName)
	if TurnManager.readyPlayers[player.UserId] then return end -- Already picked

	-- Validate Name
	local data = PokemonDB.GetPokemon(starterName)
	if not data then 
		warn("Invalid starter: " .. tostring(starterName))
		return 
	end

	print("✅ " .. player.Name .. " selected " .. starterName)

	-- Give Pokemon
	local inventory = player:FindFirstChild("PokemonInventory")
	if inventory then
		local starterPoke = Instance.new("StringValue")
		starterPoke.Name = starterName
		starterPoke.Value = data.Rarity or "Common"

		-- Set Stats
		starterPoke:SetAttribute("CurrentHP", data.HP)
		starterPoke:SetAttribute("MaxHP", data.HP)
		starterPoke:SetAttribute("Attack", data.Attack)
		starterPoke:SetAttribute("Status", "Alive")
		starterPoke.Parent = inventory
	end

	-- Draw 1 Starter Card
	CardSystem.drawOneCard(player)

	-- Mark Ready
	TurnManager.readyPlayers[player.UserId] = true

	if Events.Notify then Events.Notify:FireClient(player, "You selected " .. starterName .. "! Waiting for players...") end

	-- Check if ALL players are ready
	local allReady = true
	local playerCount = #PlayerManager.playersInGame

	if playerCount == 0 then return end

	for _, p in ipairs(PlayerManager.playersInGame) do
		if not TurnManager.readyPlayers[p.UserId] then
			allReady = false
			break
		end
	end

	if allReady then
		TurnManager.startGame()
	elseif TurnManager.gameStarted then
		-- LATE JOINER HANDLING:
		print("🕒 Late joiner " .. player.Name .. " ready! Syncing turn...")
		
		-- 1. Sync Current Turn (Also hides Waiting UI because StarterSelectUI listens to UpdateTurn)
		local activePlayerName = "Waiting"
		if #PlayerManager.playersInGame > 0 and TurnManager.currentTurnIndex > 0 then
			local activePlayer = PlayerManager.playersInGame[TurnManager.currentTurnIndex]
			if activePlayer then
				activePlayerName = activePlayer.Name
			end
		end
		if Events.UpdateTurn then
			Events.UpdateTurn:FireClient(player, activePlayerName)
		end

		-- 2. Notify others
		if Events.Notify then
			Events.Notify:FireAllClients(player.Name .. " has joined the game!")
		end
	end
end

function TurnManager.startGame()
	if TurnManager.gameStarted then return end
	TurnManager.gameStarted = true

	print("🚀 ALL PLAYERS READY! STARTING GAME!")
	if Events.Notify then Events.Notify:FireAllClients("🚀 All players ready! Game Starting!") end
	
	-- Fire GameStarted event to hide starter selection UI on all clients
	if Events.GameStarted then 
		Events.GameStarted:FireAllClients() 
		print("📡 GameStarted event fired to all clients")
	end

	task.wait(2)

	-- Unfreeze Everyone
	for _, p in ipairs(PlayerManager.playersInGame) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			p.Character.Humanoid.WalkSpeed = 16
			p.Character.Humanoid.JumpPower = 50
		end
	end

	-- Start First Turn
	TurnManager.currentTurnIndex = 0
	TurnManager.nextTurn()
end

-- Process player roll and movement
function TurnManager.processPlayerRoll(player)
	print("📊 [Server] processPlayerRoll called by:", player.Name)

	if not TurnManager.isTurnActive then return end
	if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then return end

	TurnManager.isTurnActive = false
	if EncounterSystem then EncounterSystem.clearCenterStage() end

	--local roll = 10
	local roll = math.random(1, 6)
	print("🎲 [Server] Roll result:", roll)
	Events.RollDice:FireAllClients(player, roll)
	task.wait(2.5)

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local currentPos = PlayerManager.playerPositions[player.UserId] or 0
	local repelLeft = PlayerManager.playerRepelSteps[player.UserId] or 0

	for i = 1, roll do
		currentPos = currentPos + 1
		local nextTile = tilesFolder:FindFirstChild(tostring(currentPos))

		-- Logic: Board Wrapping (If tile 40 doesn't exist, wrap to 0)
		if not nextTile then
			print("🔄 Wrapping board! " .. currentPos .. " -> 0")
			currentPos = 0
			nextTile = tilesFolder:FindFirstChild(tostring(currentPos))

			-- Increment Lap
			local currentLap = PlayerManager.playerLaps[player.UserId] or 1
			PlayerManager.playerLaps[player.UserId] = currentLap + 1
			print("🏁 " .. player.Name .. " finished Lap " .. currentLap .. "!")

			-- Reward: 5 Pokeballs
			local balls = player.leaderstats:FindFirstChild("Pokeballs")
			if balls then
				balls.Value += 5
			end

			if Events.Notify then
				Events.Notify:FireClient(player, "🏁 Lap Completed! +5 🔴 Pokeballs! Stopping at Sell Center.")
			end

			-- FORCE STOP AT START (Tile 0)
			if nextTile and humanoid then
				humanoid:MoveTo(PlayerManager.getPlayerTilePosition(player, nextTile))
				humanoid.MoveToFinished:Wait()
			end

			PlayerManager.playerPositions[player.UserId] = 0

			-- Trigger Sell UI Immediately and End Move
			print("💰 Landed on Start (Forced Stop)! Opening Sell UI...")
			local SellSystem = require(game.ServerScriptService.Modules.SellSystem)
			if SellSystem then
				SellSystem.openSellUI(player)

				TimerSystem.startPhaseTimer(60, "Sell", function()
					if player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
						TurnManager.nextTurn()
					end
				end)
			else
				TurnManager.nextTurn()
			end
			return -- Stop movement here
		end

		if nextTile and humanoid then
			humanoid:MoveTo(PlayerManager.getPlayerTilePosition(player, nextTile))
			humanoid.MoveToFinished:Wait()

			if repelLeft > 0 then 
				repelLeft = repelLeft - 1
				PlayerManager.playerRepelSteps[player.UserId] = repelLeft 
			end

			-- UPDATE POSITION CACHE DURING WALK
			PlayerManager.playerPositions[player.UserId] = currentPos
		else
			-- Fallback reset logic
			currentPos = 0
			if humanoid then
				local startTile = tilesFolder:FindFirstChild("0")
				if startTile then 
					character:SetPrimaryPartCFrame(startTile.CFrame + Vector3.new(0, 5, 0)) 
				end
			end
			TurnManager.nextTurn()
			return -- Return instead of break to avoid accidental event trigger
		end
	end

	-- ==========================================
	-- 🏁 LANDING LOGIC (ONLY AFTER MOVEMENT)
	-- ==========================================
	PlayerManager.playerPositions[player.UserId] = currentPos
	local landingTile = tilesFolder:FindFirstChild(tostring(currentPos))

	if landingTile then
		-- 🛑 SPECIAL: START TILE (Priority over PVP)
		local isStartTile = (landingTile.Name == "0" or landingTile.Name == "Start")
		if isStartTile then
			TurnManager.processTileEvent(player, currentPos, landingTile)
			return
		end

		-- 🔷 PVP CHECK
		local opponents = {}
		for _, otherPlayer in ipairs(PlayerManager.playersInGame) do
			if otherPlayer ~= player and PlayerManager.playerPositions[otherPlayer.UserId] == currentPos then
				table.insert(opponents, otherPlayer)
			end
		end

		if #opponents > 0 and Events.BattleTrigger then
			print("⚔️ PvP Potential on landing! Triggering Selection...")
			Events.BattleTrigger:FireClient(player, "PvP", { Opponents = opponents })
			return 
		end

		-- If no PvP, process tile normally
		TurnManager.processTileEvent(player, currentPos, landingTile)
	else
		TurnManager.nextTurn()
	end
end

-- RESUME TURN (Called after declining PvP)
function TurnManager.resumeTurn(player)
	print("🔄 Resuming turn for " .. player.Name)
	local currentPos = PlayerManager.playerPositions[player.UserId] or 0
	local tile = tilesFolder:FindFirstChild(tostring(currentPos))

	if tile then
		TurnManager.processTileEvent(player, currentPos, tile)
	else
		warn("ResumeTurn: Tile not found!")
		TurnManager.nextTurn()
	end
end

-- CENTRAL TILE EVENT HANDLER
function TurnManager.processTileEvent(player, currentPos, nextTile)
	local tileColorName = nextTile.BrickColor.Name
	local tileColorLower = string.lower(tileColorName)
	print("📍 [Server] Processing Tile: " .. nextTile.Name .. " | Color: " .. tileColorName)

	-- 0. START TILE
	local isStartTile = (nextTile.Name == "0" or nextTile.Name == "Start")
	if isStartTile then
		print("💰 Landed on Start! Opening Sell UI...")

		local SellSystem = require(game.ServerScriptService.Modules.SellSystem)
		if SellSystem then
			SellSystem.openSellUI(player)
			TimerSystem.startPhaseTimer(60, "Sell", function()
				if player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
					TurnManager.nextTurn()
				end
			end)
		else
			TurnManager.nextTurn()
		end
		return
	end

	-- 1. BLACK TILE (Skip Turn / Sleep)
	if tileColorLower == "black" or tileColorName == "Black" then
		print("🛑 Landed on Black Tile! Stunned for 1 turn.")
		if Events.Notify then 
			Events.Notify:FireClient(player, "🛑 Stuck in Black Tile! Skip 1 turn.") 
			-- Broadcast to all
			Events.Notify:FireAllClients("🛑 " .. player.Name .. " landed on a Black Tile! Skip 1 turn.")
		end

		local status = player:FindFirstChild("Status")
		if status then
			local sleep = status:FindFirstChild("SleepTurns")
			if sleep then sleep.Value = 1 end
		end

		TurnManager.nextTurn()
		return
	end

	-- 2. GREEN TILES (Encounter System)
	if tileColorLower == "bright green" or tileColorLower == "forest green" or 
		tileColorLower == "dark green" or tileColorLower == "earth green" or 
		tileColorLower == "gold" then

		local repelLeft = PlayerManager.playerRepelSteps[player.UserId] or 0
		if repelLeft > 0 then 
			print("🛡️ Repel Active. No encounter.")
			TurnManager.nextTurn() 
		elseif EncounterSystem then 
			EncounterSystem.spawnPokemonEncounter(player, tileColorName) 
		else
			TurnManager.nextTurn()
		end
		return
	end

	-- 3. WHITE TILES (Shop/Heal)
	if string.find(tileColorLower, "white") then
		local inventory = player:FindFirstChild("PokemonInventory")
		if inventory then
			local revivedCount = 0
			for _, poke in ipairs(inventory:GetChildren()) do
				if poke:GetAttribute("Status") == "Dead" then
					poke:SetAttribute("Status", "Alive")
					poke:SetAttribute("CurrentHP", poke:GetAttribute("MaxHP"))
					revivedCount = revivedCount + 1
				end
			end
			if revivedCount > 0 and Events.Notify then 
				Events.Notify:FireClient(player, "💖 " .. revivedCount .. " Pokemon Revived!") 
			end
		end

		PlayerManager.playerInShop[player.UserId] = true
		Events.Shop:FireClient(player)
		if Events.Notify then
			Events.Notify:FireAllClients("🏪 " .. player.Name .. " entered the Shop!")
		end

		TurnManager.turnPhase = "Shop"
		TimerSystem.startPhaseTimer(TimerSystem.SHOP_TIMEOUT, "Shop", function()
			if TurnManager.turnPhase == "Shop" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				PlayerManager.playerInShop[player.UserId] = false
				TurnManager.nextTurn()
			end
		end)
		return
	end

	-- 4. RED TILE (PvE Battle Trigger)
	if string.find(tileColorLower, "red") or string.find(tileColorLower, "crimson") or string.find(tileColorLower, "maroon") then
		local rarity = "Common"
		if string.find(tileColorLower, "crimson") then rarity = "Uncommon" end
		if string.find(tileColorLower, "maroon") then rarity = "Rare" end

		print("⚔️ Landed on Red Tile (" .. tileColorName .. ") -> PvE: " .. rarity)

		if Events.BattleTrigger then
			TurnManager.turnPhase = "BattleSelection"
			-- Pass Rarity info to Client (for local display if needed) and back to Server in response
			Events.BattleTrigger:FireClient(player, "PvE", { Rarity = rarity })

			TimerSystem.startPhaseTimer(30, "BattleSelection", function()
				if TurnManager.turnPhase == "BattleSelection" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
					TurnManager.nextTurn()
				end
			end)
		else
			TurnManager.nextTurn()
		end
		return
	end

	-- 5. DEFAULT (Draw Card - if logic falls through)
	-- Previously checked for PvP here. Now handled before.
	CardSystem.drawOneCard(player)
	TurnManager.nextTurn()
end

return TurnManager

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

-- Next turn logic
function TurnManager.nextTurn()
	print("🔄 [Server] nextTurn() called")
	task.wait(1)

	if #PlayerManager.playersInGame == 0 then
		print("⚠️ [Server] No players in game!")
		return
	end

	for _ = 1, #PlayerManager.playersInGame do
		TurnManager.currentTurnIndex += 1
		if TurnManager.currentTurnIndex > #PlayerManager.playersInGame then 
			TurnManager.currentTurnIndex = 1 
		end

		local p = PlayerManager.playersInGame[TurnManager.currentTurnIndex]
		local status = p:FindFirstChild("Status")
		local sleep = status and status:FindFirstChild("SleepTurns")

		if sleep and sleep.Value > 0 then
			sleep.Value -= 1
			if Events.Notify then 
				Events.Notify:FireClient(p, "You are asleep! Turn skipped!") 
			end
		else
			TurnManager.isTurnActive = true
			PlayerManager.playerInShop[p.UserId] = false
			print("🎲 [Server] Turn started for:", p.Name)
			TurnManager.enterDrawPhase(p)
			return
		end
	end
end

-- Enter draw phase (Auto-draw to 3 cards, then go to Roll)
function TurnManager.enterDrawPhase(player)
	TurnManager.turnPhase = "Draw"
	TurnManager.isTurnActive = true
	print("Phase: Auto-Draw for:", player.Name)

	-- Auto-draw until player has 3 cards
	local handCount = CardSystem.countHand(player)
	local cardsNeeded = 3 - handCount

	if cardsNeeded > 0 then
		for i = 1, cardsNeeded do
			CardSystem.drawOneCard(player)
		end
		if Events.Notify then
			Events.Notify:FireClient(player, "🃏 Auto-draw: +" .. cardsNeeded .. " cards!")
		end
	end

	-- Short delay to show card drawn, then go to Roll
	task.wait(1)
	TurnManager.enterRollPhase(player)
end

-- Enter roll phase
function TurnManager.enterRollPhase(player)
	TurnManager.turnPhase = "Roll"
	TurnManager.isTurnActive = true  -- IMPORTANT: Allow player to roll
	print("Phase: Enter Roll Phase for:", player.Name)

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
end

-- Process player roll and movement
function TurnManager.processPlayerRoll(player)
	print("📊 [Server] processPlayerRoll called by:", player.Name)

	if not TurnManager.isTurnActive then return end
	if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then return end

	TurnManager.isTurnActive = false
	if EncounterSystem then EncounterSystem.clearCenterStage() end

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

		if nextTile and humanoid then
			humanoid:MoveTo(PlayerManager.getPlayerTilePosition(player, nextTile))
			humanoid.MoveToFinished:Wait()

			if repelLeft > 0 then 
				repelLeft = repelLeft - 1
				PlayerManager.playerRepelSteps[player.UserId] = repelLeft 
			end

			if i == roll then
				-- UPDATE POSITION IMMEDIATELY
				PlayerManager.playerPositions[player.UserId] = currentPos

				local tileColorName = nextTile.BrickColor.Name
				local tileColorLower = string.lower(tileColorName)
				print("📍 [Server] Landed on tile: " .. nextTile.Name .. " | Color: " .. tileColorName)

				-- 0. START TILE (Tile 0 Logic - Modulo check typically, but here checked by index)
				-- Note: In this project, Tile 40 wraps to 0 or 1. If logic resets pos to 0, handle it.
				-- If currentPos is handled linearly (e.g. 1-40), check map.
				-- Assuming Tile 0 is the start tile or a specific Sell Tile.
				
				local isStartTile = (nextTile.Name == "0" or nextTile.Name == "Start")
				
				if isStartTile then
					print("💰 Landed on Start! Opening Sell UI...")
					PlayerManager.playerPositions[player.UserId] = currentPos -- Ensure pos update
					
					-- Trigger Sell UI
					local SellSystem = require(game.ServerScriptService.Modules.SellSystem)
					if SellSystem then
						-- IMPORTANT: Ensure SellSystem handles the NextTurn callback!
						SellSystem.openSellUI(player)
						
						-- Setup Timeout just in case
						TimerSystem.startPhaseTimer(60, "Sell", function()
							-- If player still in Sell phase after 60s
							if player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
								print("Timer: Sell timeout")
								TurnManager.nextTurn()
							end
						end)
					else
						warn("SellSystem not found!")
						TurnManager.nextTurn()
					end
					return
				end

				-- 1. BLACK TILE (Skip Turn / Sleep)
				if tileColorLower == "black" or tileColorName == "Black" then
					print("🛑 Landed on Black Tile! Stunned for 1 turn.")
					if Events.Notify then Events.Notify:FireClient(player, "🛑 Stuck in Black Tile! Skip 1 turn.") end

					-- Set Status
					local status = player:FindFirstChild("Status")
					if status then
						local sleep = status:FindFirstChild("SleepTurns")
						if sleep then sleep.Value = 1 end
					end

					TurnManager.nextTurn()
					return
				end

				-- 2. GREEN TILES (Encounter System)
				-- เช็ครายชื่อสีที่อยู่ใน DB หรือที่มีคำว่า green / gold
				if tileColorLower == "bright green" or tileColorLower == "forest green" or 
					tileColorLower == "dark green" or tileColorLower == "earth green" or 
					tileColorLower == "gold" then

					if repelLeft > 0 then 
						print("🛡️ Repel Active. No encounter.")
						TurnManager.nextTurn() 
					elseif EncounterSystem then 
						-- ส่งชื่อสีไปให้ EncounterSystem คำนวณ
						EncounterSystem.spawnPokemonEncounter(player, tileColorName) 
					else
						TurnManager.nextTurn()
					end
					return

						-- 3. WHITE TILES (Shop/Heal)
				elseif string.find(tileColorLower, "white") then
					-- ... (Logic เดิม: Heal & Shop) ...
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

					PlayerManager.playerPositions[player.UserId] = currentPos
					PlayerManager.playerInShop[player.UserId] = true
					Events.Shop:FireClient(player)

					TurnManager.turnPhase = "Shop"
					TimerSystem.startPhaseTimer(TimerSystem.SHOP_TIMEOUT, "Shop", function()
						if TurnManager.turnPhase == "Shop" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
							PlayerManager.playerInShop[player.UserId] = false
							TurnManager.nextTurn()
						end
					end)
					return

						-- 4. RED TILE (PvE Battle Trigger)
				elseif string.find(tileColorLower, "red") then
					print("⚔️ Landed on Red Tile! PvE Trigger.")
					if Events.BattleTrigger then
						TurnManager.turnPhase = "BattleSelection"
						Events.BattleTrigger:FireClient(player, "PvE", nil)

						TimerSystem.startPhaseTimer(30, "BattleSelection", function()
							if TurnManager.turnPhase == "BattleSelection" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
								TurnManager.nextTurn()
							end
						end)
					else
						TurnManager.nextTurn()
					end
					return

				else
					-- 5. OTHER (PvP Check or Draw Card)
					local opponents = {}
					for _, otherPlayer in ipairs(PlayerManager.playersInGame) do
						if otherPlayer ~= player and PlayerManager.playerPositions[otherPlayer.UserId] == currentPos then
							table.insert(opponents, otherPlayer)
						end
					end

					if #opponents > 0 and Events.BattleTrigger then
						print("⚔️ PvP Potential!")
						Events.BattleTrigger:FireClient(player, "PvP", { Opponents = opponents })
						return 
					end

					-- Default: Draw Card
					CardSystem.drawOneCard(player)
					TurnManager.nextTurn()
				end
			end
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
			break
		end
	end
	PlayerManager.playerPositions[player.UserId] = currentPos
end

return TurnManager

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

-- Process player roll and movement
function TurnManager.processPlayerRoll(player)
	print("📊 [Server] processPlayerRoll called by:", player.Name)

	if not TurnManager.isTurnActive then return end
	if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then return end

	TurnManager.isTurnActive = false
	if EncounterSystem then EncounterSystem.clearCenterStage() end

	local roll = math.random(1, 6)
	--local roll = (10)
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
				local tileColor = string.lower(nextTile.BrickColor.Name)
				print("📍 [Server] Landed on tile: " .. nextTile.Name .. " | Color: " .. tileColor)

				if string.find(tileColor, "white") then
					-- Shop / City / Recovery Center
					print("Landed on City/Shop! Healing & Opening shop...")

					-- 1. HEAL / REVIVE ALL POKEMON
					local inventory = player:FindFirstChild("PokemonInventory")
					if inventory then
						local revivedCount = 0
						for _, poke in ipairs(inventory:GetChildren()) do
							if poke:GetAttribute("Status") == "Dead" then
								poke:SetAttribute("Status", "Alive")
								poke:SetAttribute("CurrentHP", poke:GetAttribute("MaxHP")) -- Full heal?
								revivedCount = revivedCount + 1
							end
						end
						if revivedCount > 0 then
							if Events.Notify then Events.Notify:FireClient(player, "💖 " .. revivedCount .. " Pokemon Revived!") end
						end
					end

					-- 2. Open Shop
					PlayerManager.playerPositions[player.UserId] = currentPos
					PlayerManager.playerInShop[player.UserId] = true
					Events.Shop:FireClient(player)

					TurnManager.turnPhase = "Shop"
					TimerSystem.startPhaseTimer(TimerSystem.SHOP_TIMEOUT, "Shop", function()
						if TurnManager.turnPhase == "Shop" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
							print("Timer: Shop timeout")
							PlayerManager.playerInShop[player.UserId] = false
							TurnManager.nextTurn()
						end
					end)
					return

				elseif string.find(tileColor, "red") then -- Red Tile (PvE)
					print("⚔️ [Server] Landed on Red Tile! Firing BattleTrigger/PvE to " .. player.Name)
					if Events.BattleTrigger then
						Events.BattleTrigger:FireClient(player, "PvE", nil)
						print("   -> Event Fired!")
					else
						warn("   -> Events.BattleTrigger is MISSING!")
						TurnManager.nextTurn()
					end
					return

				elseif string.find(tileColor, "green") then
					-- Encounter tile (Wild Pokemon)
					if repelLeft > 0 then 
						TurnManager.nextTurn() 
					elseif EncounterSystem then 
						EncounterSystem.spawnPokemonEncounter(player) 
					end

				else
					-- Check for PvP Collision (Any Standard Tile)
					local opponents = {}
					for _, otherPlayer in ipairs(PlayerManager.playersInGame) do
						if otherPlayer ~= player and PlayerManager.playerPositions[otherPlayer.UserId] == currentPos then
							table.insert(opponents, otherPlayer)
						end
					end

					if #opponents > 0 then
						print("⚔️ PvP Potential! Found " .. #opponents .. " opponents.")
						if Events.BattleTrigger then
							-- Trigger PvP Selection
							Events.BattleTrigger:FireClient(player, "PvP", { Opponents = opponents })
							-- Wait for client selection
							return 
						end
					end

					-- Default: Draw Card
					CardSystem.drawOneCard(player)
					TurnManager.nextTurn()
				end
			end
		else
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

return TurnManager

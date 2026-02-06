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

	-- Collect all player stats
	local results = {}
	for _, p in ipairs(PlayerManager.playersInGame) do
		local moneyVal = 0
		local pokemonCount = 0
		local laps = PlayerManager.playerLaps[p.UserId] or 1
		
		if p:FindFirstChild("leaderstats") then
			moneyVal = p.leaderstats.Money.Value
		end
		
		local inventory = p:FindFirstChild("PokemonInventory")
		if inventory then
			pokemonCount = #inventory:GetChildren()
		end

		table.insert(results, {
			Name = p.Name,
			UserId = p.UserId,
			Money = moneyVal,
			PokemonCount = pokemonCount,
			Laps = laps
		})
		
		print(p.Name .. " finished with $" .. moneyVal .. ", " .. pokemonCount .. " Pokemon")
	end

	-- Sort by money (highest first)
	table.sort(results, function(a, b)
		return a.Money > b.Money
	end)

	-- Add rank
	for i, r in ipairs(results) do
		r.Rank = i
	end

	local winner = results[1]
	local msg = "🏆 GAME OVER! Winner: " .. (winner and winner.Name or "None") .. " with $" .. (winner and winner.Money or 0)
	
	-- Fire GameEnd event with full results
	if Events.GameEnd then
		Events.GameEnd:FireAllClients(results)
	end

	if Events.Notify and winner then
		Events.Notify:FireAllClients("🏆 " .. winner.Name .. " WINS THE GAME with $" .. winner.Money .. "!")
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
			if Events.StatusChanged then
				Events.StatusChanged:FireAllClients(p.UserId, "Sleep", sleep.Value)
			end
		else
			TurnManager.isTurnActive = true
			PlayerManager.playerInShop[p.UserId] = false
			print("🎲 [Server] Turn started for:", p.Name)
			TurnManager.processStatusEffects(p)
			TurnManager.enterDrawPhase(p)
			return
		end
	end

	print("⚠️ No valid players found to take turn?")
end

-- Process Status Effects (Poison, Burn) at start of turn
function TurnManager.processStatusEffects(player)
	local status = player:FindFirstChild("Status")
	if not status then return end

	-- Poison: -1 coin per turn
	local poison = status:FindFirstChild("PoisonTurns")
	if poison and poison.Value > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Money") then
			leaderstats.Money.Value = math.max(0, leaderstats.Money.Value - 1)
		end
		poison.Value -= 1
		if Events.Notify then
			Events.Notify:FireClient(player, "☠️ Poison! -1 เหรียญ")
		end
		if Events.StatusChanged then
			Events.StatusChanged:FireAllClients(player.UserId, "Poison", poison.Value)
		end
	end

	-- Burn: -2 coins per turn
	local burn = status:FindFirstChild("BurnTurns")
	if burn and burn.Value > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Money") then
			leaderstats.Money.Value = math.max(0, leaderstats.Money.Value - 2)
		end
		burn.Value -= 1
		if Events.Notify then
			Events.Notify:FireClient(player, "🔥 Burn! -2 เหรียญ")
		end
		if Events.StatusChanged then
			Events.StatusChanged:FireAllClients(player.UserId, "Burn", burn.Value)
		end
	end
end

-- ============================================================================
-- 🎮 4-PHASE TURN SYSTEM
-- Phase 1: Draw Phase - จั่วการ์ด 1 ใบอัตโนมัติ
-- Phase 2: Item Phase - ใช้การ์ดได้ + ปุ่ม "Next Phase"
-- Phase 3: Ability Phase - ใช้ Skill อาชีพ + ปุ่ม "Next Phase"
-- Phase 4: Roll Phase - ทอยเต๋า
-- ============================================================================

-- Phase Timeouts (seconds)
TurnManager.ITEM_PHASE_TIMEOUT = 60
TurnManager.ABILITY_PHASE_TIMEOUT = 30

-- Enter draw phase (Always draw 1 card at start of turn)
function TurnManager.enterDrawPhase(player)
	TurnManager.turnPhase = "Draw"
	TurnManager.isTurnActive = true
	print("📍 Phase 1: DRAW Phase for:", player.Name)

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

	-- Fire PhaseUpdate to client
	if Events.PhaseUpdate then
		Events.PhaseUpdate:FireClient(player, "Draw", "🃏 กำลังจั่วการ์ด...")
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

	-- Short delay to show card drawn, then go to Item Phase
	task.wait(1.5)
	TurnManager.enterItemPhase(player)
end

-- Enter Item Phase (Use cards before rolling)
function TurnManager.enterItemPhase(player)
	TurnManager.turnPhase = "Item"
	print("📍 Phase 2: ITEM Phase for:", player.Name)

	-- Fire PhaseUpdate to client
	if Events.PhaseUpdate then
		Events.PhaseUpdate:FireClient(player, "Item", "🎒 ใช้การ์ดได้เลย หรือกด Next Phase")
	end

	-- Notify all clients about phase change
	if Events.Notify then
		Events.Notify:FireAllClients("🎒 " .. player.Name .. " อยู่ใน Item Phase")
	end
	
	-- No forced timer - player can switch phases freely
end

-- Enter Ability Phase (Use class abilities)
function TurnManager.enterAbilityPhase(player)
	TurnManager.turnPhase = "Ability"
	print("📍 Phase 3: ABILITY Phase for:", player.Name)

	-- Reset ability usage for this turn
	player:SetAttribute("AbilityUsedThisTurn", false)

	-- Check if player has a job with abilities
	local playerJob = player:GetAttribute("Job")

	if not playerJob then
		-- No job - auto skip to Roll Phase after short delay
		print("⏩ No job found, skipping Ability Phase")
		if Events.PhaseUpdate then
			Events.PhaseUpdate:FireClient(player, "Ability", "⏩ ไม่มี Ability - ข้ามไป Roll Phase")
		end
		if Events.Notify then
			Events.Notify:FireClient(player, "⏩ ไม่มี Ability - ข้ามไป Roll Phase")
		end
		task.wait(1)
		TurnManager.enterRollPhase(player)
		return
	end

	-- Fire PhaseUpdate to client with job info
	local jobAbility = player:GetAttribute("JobAbility") or "Unknown"
	if Events.PhaseUpdate then
		Events.PhaseUpdate:FireClient(player, "Ability", "⚡ ใช้ " .. jobAbility .. " หรือกด Next Phase")
	end

	-- Notify all clients about phase change
	if Events.Notify then
		Events.Notify:FireAllClients("⚡ " .. player.Name .. " อยู่ใน Ability Phase (" .. playerJob .. ")")
	end
	
	-- No forced timer - player can switch phases freely
end

-- Enter roll phase
function TurnManager.enterRollPhase(player)
	TurnManager.turnPhase = "Roll"
	TurnManager.isTurnActive = true  -- IMPORTANT: Allow player to roll
	print("📍 Phase 4: ROLL Phase for:", player.Name)

	-- Fire PhaseUpdate to client
	if Events.PhaseUpdate then
		Events.PhaseUpdate:FireClient(player, "Roll", "🎲 กดทอยเต๋าได้เลย!")
	end

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

	-- 4-Phase System: Advance Phase Event
	if Events.AdvancePhase then
		Events.AdvancePhase.OnServerEvent:Connect(function(player)
			-- Validate it's the current player's turn
			if #PlayerManager.playersInGame == 0 then return end
			if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				print("⚠️ AdvancePhase rejected: Not " .. player.Name .. "'s turn")
				return
			end

			print("➡️ AdvancePhase from " .. player.Name .. " (current phase: " .. TurnManager.turnPhase .. ")")

			-- Advance to Roll phase from Item or Ability
			if TurnManager.turnPhase == "Item" or TurnManager.turnPhase == "Ability" then
				TurnManager.enterRollPhase(player)
			else
				print("⚠️ Cannot advance from phase: " .. TurnManager.turnPhase)
			end
		end)
	end

	-- Flexible Phase Switching Event (Item <-> Ability)
	if Events.SwitchPhase then
		Events.SwitchPhase.OnServerEvent:Connect(function(player, targetPhase)
			-- Validate it's the current player's turn
			if #PlayerManager.playersInGame == 0 then return end
			if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				print("⚠️ SwitchPhase rejected: Not " .. player.Name .. "'s turn")
				return
			end

			-- Only allow switching between Item and Ability (not Roll or Draw)
			local currentPhase = TurnManager.turnPhase
			if currentPhase ~= "Item" and currentPhase ~= "Ability" then
				if Events.Notify then
					Events.Notify:FireClient(player, "❌ ไม่สามารถสลับ Phase ได้ในตอนนี้!")
				end
				return
			end

			if targetPhase == "Item" then
				TurnManager.enterItemPhase(player)
			elseif targetPhase == "Ability" then
				TurnManager.enterAbilityPhase(player)
			else
				print("⚠️ Invalid target phase: " .. tostring(targetPhase))
			end
		end)
	end

	-- 4-Phase System: Use Ability Event
	if Events.UseAbility then
		Events.UseAbility.OnServerEvent:Connect(function(player, abilityName, abilityData)
			if TurnManager.turnPhase ~= "Ability" then
				if Events.Notify then
					Events.Notify:FireClient(player, "❌ ใช้ Ability ได้แค่ใน Ability Phase เท่านั้น!")
				end
				return
			end

			-- Check if already used this turn
			if player:GetAttribute("AbilityUsedThisTurn") then
				if Events.Notify then
					Events.Notify:FireClient(player, "❌ ใช้ Ability ได้แค่ 1 ครั้งต่อเทิร์น!")
				end
				return
			end

			local playerJob = player:GetAttribute("Job")
			print("⚡ " .. player.Name .. " (" .. (playerJob or "No Job") .. ") used ability: " .. tostring(abilityName))

			local abilitySuccess = false

			-- ============================================
			-- GAMBLER: Lucky Guess - ทายเลข 1-6
			-- ============================================
			if playerJob == "Gambler" and abilityName == "LuckyGuess" then
				local guessedNumber = abilityData and abilityData.guess
				if not guessedNumber or type(guessedNumber) ~= "number" then
					if Events.Notify then
						Events.Notify:FireClient(player, "❌ กรุณาเลือกเลข 1-6!")
					end
					return
				end

				local actualRoll = math.random(1, 6)
				if guessedNumber == actualRoll then
					-- WIN! +6 coins
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild("Money") then
						leaderstats.Money.Value += 6
					end
					if Events.Notify then
						Events.Notify:FireClient(player, "🎰 ทายถูก! เลข " .. actualRoll .. " ได้ 6 เหรียญ!")
						Events.Notify:FireAllClients("🎰 " .. player.Name .. " ทายเลขถูก! (" .. actualRoll .. ") +6 เหรียญ")
					end
				else
					if Events.Notify then
						Events.Notify:FireClient(player, "🎰 ทายผิด! คุณทาย " .. guessedNumber .. " แต่ออก " .. actualRoll)
						Events.Notify:FireAllClients("🎰 " .. player.Name .. " ทายเลขผิด (ทาย " .. guessedNumber .. " ออก " .. actualRoll .. ")")
					end
				end
				abilitySuccess = true

			-- ============================================
			-- ESPER: Mind Move - กำหนดช่องเดิน 1-2
			-- ============================================
			elseif playerJob == "Esper" and abilityName == "MindMove" then
				local moveAmount = abilityData and abilityData.move
				if not moveAmount or (moveAmount ~= 1 and moveAmount ~= 2) then
					if Events.Notify then
						Events.Notify:FireClient(player, "❌ กรุณาเลือก 1 หรือ 2 ช่อง!")
					end
					return
				end

				-- Store the fixed move for this turn
				player:SetAttribute("FixedDiceRoll", moveAmount)
				if Events.Notify then
					Events.Notify:FireClient(player, "🔮 กำหนดเดิน " .. moveAmount .. " ช่องสำหรับเทิร์นนี้!")
					Events.Notify:FireAllClients("🔮 " .. player.Name .. " ใช้พลังจิตกำหนดการเดิน!")
				end
				abilitySuccess = true

			-- ============================================
			-- SHAMAN: Curse - สาปคนอื่น (ทิ้งการ์ด + -1 เหรียญ)
			-- ============================================
			elseif playerJob == "Shaman" and abilityName == "Curse" then
				local targetUserId = abilityData and abilityData.targetUserId
				local targetPlayer = nil

				-- Find target player
				for _, p in ipairs(PlayerManager.playersInGame) do
					if p.UserId == targetUserId and p ~= player then
						targetPlayer = p
						break
					end
				end

				if not targetPlayer then
					if Events.Notify then
						Events.Notify:FireClient(player, "❌ กรุณาเลือกผู้เล่นที่จะสาป!")
					end
					return
				end

				-- Curse effect: -1 Money
				local targetStats = targetPlayer:FindFirstChild("leaderstats")
				if targetStats and targetStats:FindFirstChild("Money") then
					targetStats.Money.Value = math.max(0, targetStats.Money.Value - 1)
				end

				-- Curse effect: Discard 1 random card
				local targetHand = targetPlayer:FindFirstChild("Hand")
				if targetHand then
					local cards = targetHand:GetChildren()
					if #cards > 0 then
						local randomCard = cards[math.random(1, #cards)]
						local cardName = randomCard.Name
						randomCard:Destroy()
						if Events.Notify then
							Events.Notify:FireClient(targetPlayer, "🌿 ถูกสาป! เสียการ์ด " .. cardName .. " และ 1 เหรียญ!")
						end
					end
				end

				if Events.Notify then
					Events.Notify:FireClient(player, "🌿 สาป " .. targetPlayer.Name .. " สำเร็จ!")
					Events.Notify:FireAllClients("🌿 " .. player.Name .. " สาป " .. targetPlayer.Name .. "! (-1 การ์ด, -1 เหรียญ)")
				end
				abilitySuccess = true

			-- ============================================
			-- BIKER: Turbo Boost - เดินเพิ่ม +2 ช่อง
			-- ============================================
			elseif playerJob == "Biker" and abilityName == "TurboBoost" then
				player:SetAttribute("BonusDiceRoll", 2)
				if Events.Notify then
					Events.Notify:FireClient(player, "🏍️ Turbo Boost! +2 ช่องในเทิร์นนี้!")
					Events.Notify:FireAllClients("🏍️ " .. player.Name .. " เปิด Turbo Boost! +2 ช่อง")
				end
				abilitySuccess = true

			-- ============================================
			-- TRAINER: Extra Hand - Passive (no active ability)
			-- ============================================
			elseif playerJob == "Trainer" and abilityName == "ExtraHand" then
				if Events.Notify then
					Events.Notify:FireClient(player, "🎒 เทรนเนอร์สามารถถือการ์ดได้ 6 ใบ (Passive)")
				end
				-- No active ability, just passive hand limit
				abilitySuccess = false -- Don't count as used

			-- ============================================
			-- FISHERMAN: Steal Card - แย่งชิงการ์ดจากผู้เล่นอื่น
			-- ============================================
			elseif playerJob == "Fisherman" and abilityName == "StealCard" then
				local targetUserId = abilityData and abilityData.targetUserId
				local targetPlayer = nil

				for _, p in ipairs(PlayerManager.playersInGame) do
					if p.UserId == targetUserId and p ~= player then
						targetPlayer = p
						break
					end
				end

				if not targetPlayer then
					if Events.Notify then
						Events.Notify:FireClient(player, "❌ กรุณาเลือกผู้เล่นที่จะแย่งการ์ด!")
					end
					return
				end

				local targetHand = targetPlayer:FindFirstChild("Hand")
				local myHand = player:FindFirstChild("Hand")

				if targetHand and myHand then
					local cards = targetHand:GetChildren()
					if #cards > 0 then
						local stolenCard = cards[math.random(1, #cards)]
						local cardName = stolenCard.Name
						stolenCard.Parent = myHand
						if Events.Notify then
							Events.Notify:FireClient(player, "🎣 แย่งการ์ด " .. cardName .. " จาก " .. targetPlayer.Name .. " สำเร็จ!")
							Events.Notify:FireClient(targetPlayer, "🎣 " .. player.Name .. " แย่งการ์ด " .. cardName .. " ไป!")
							Events.Notify:FireAllClients("🎣 " .. player.Name .. " แย่งการ์ดจาก " .. targetPlayer.Name .. "!")
						end
						abilitySuccess = true
					else
						if Events.Notify then
							Events.Notify:FireClient(player, "❌ " .. targetPlayer.Name .. " ไม่มีการ์ดให้แย่ง!")
						end
						return
					end
				end

			-- ============================================
			-- ROCKET: Steal Pokemon - Passive (triggers on PvP win)
			-- ============================================
			elseif playerJob == "Rocket" and abilityName == "StealPokemon" then
				if Events.Notify then
					Events.Notify:FireClient(player, "💀 แก็งร็อกเก็ตจะขโมย Pokemon เมื่อชนะ PvP (Passive)")
				end
				abilitySuccess = false -- Passive, no active use

			-- ============================================
			-- NURSE JOY: Revive - ฟื้นฟู Pokemon ที่ตาย
			-- ============================================
			elseif playerJob == "NurseJoy" and abilityName == "Revive" then
				local inventory = player:FindFirstChild("PokemonInventory")
				if inventory then
					local revived = false
					for _, poke in ipairs(inventory:GetChildren()) do
						if poke:GetAttribute("Status") == "Dead" then
							poke:SetAttribute("Status", "Alive")
							poke:SetAttribute("CurrentHP", poke:GetAttribute("MaxHP"))
							if Events.Notify then
								Events.Notify:FireClient(player, "💖 ฟื้นฟู " .. poke.Name .. " สำเร็จ!")
								Events.Notify:FireAllClients("💖 " .. player.Name .. " ฟื้นฟู " .. poke.Name .. "!")
							end
							revived = true
							break -- Revive only 1 per turn
						end
					end
					if not revived then
						if Events.Notify then
							Events.Notify:FireClient(player, "❌ ไม่มี Pokemon ที่ต้องฟื้นฟู!")
						end
						return
					end
				end
				abilitySuccess = true

			else
				if Events.Notify then
					Events.Notify:FireClient(player, "❌ Ability ไม่ถูกต้องสำหรับอาชีพของคุณ!")
				end
				return
			end

			-- Mark ability as used
			if abilitySuccess then
				player:SetAttribute("AbilityUsedThisTurn", true)
			end

			-- After using ability, auto-advance to Roll Phase
			TurnManager.enterRollPhase(player)
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

-- ============================================================================
-- JOB DATABASE (Server-side validation)
-- ============================================================================
local ValidJobs = {
	Gambler = {
		Name = "Gambler",
		Ability = "LuckyGuess",
		Description = "นักพนัน - ทายเลข 1-6 ถูกได้ 6 เหรียญ"
	},
	Esper = {
		Name = "Esper",
		Ability = "MindMove",
		Description = "จิตสัมผัส - กำหนดช่องเดินได้ 1-2 ช่อง"
	},
	Shaman = {
		Name = "Shaman",
		Ability = "Curse",
		Description = "หมอผี - สาปให้คนอื่นทิ้งการ์ด+เสียเงิน"
	},
	Biker = {
		Name = "Biker",
		Ability = "TurboBoost",
		Description = "นักบิด - เดินเพิ่ม +2 ช่อง"
	},
	Trainer = {
		Name = "Trainer",
		Ability = "ExtraHand",
		Description = "เทรนเนอร์ - ถือการ์ดได้ 6 ใบ (Passive)",
		HandLimit = 6
	},
	Fisherman = {
		Name = "Fisherman",
		Ability = "StealCard",
		Description = "นักตกปลา - แย่งชิงการ์ดจากผู้เล่นอื่น"
	},
	Rocket = {
		Name = "Rocket",
		Ability = "StealPokemon",
		Description = "แก็งร็อกเก็ต - ขโมย Pokemon เมื่อชนะ PvP (Passive)"
	},
	NurseJoy = {
		Name = "NurseJoy",
		Ability = "Revive",
		Description = "คุณจอย - ฟื้นฟู Pokemon ที่ตายได้ทุกเทิร์น"
	}
}

function TurnManager.handleStarterSelection(player, jobName)
	if TurnManager.readyPlayers[player.UserId] then return end -- Already picked

	-- Validate Job Name
	local jobData = ValidJobs[jobName]
	if not jobData then
		warn("Invalid job: " .. tostring(jobName))
		return
	end

	print("✅ " .. player.Name .. " selected job: " .. jobName)

	-- Set Player's Job/Class
	player:SetAttribute("Job", jobName)
	player:SetAttribute("JobAbility", jobData.Ability)
	player:SetAttribute("AbilityUsedThisTurn", false)

	-- Give starter Pokemon based on job
	local starterPokemon = {
		Gambler = "Meowth",    -- Money-related
		Esper = "Drowzee",     -- Psychic/Sleep
		Shaman = "Gastly",     -- Ghost/Spirit
		Biker = "Cyclizar",    -- Fast/Motorcycle Pokemon
		Trainer = "Pikachu",   -- Classic trainer
		Fisherman = "Magikarp",-- Fishing
		Rocket = "Rattata",    -- Team Rocket
		NurseJoy = "Chansey"   -- Healing
	}

	local starterName = starterPokemon[jobName] or "Pikachu"
	local inventory = player:FindFirstChild("PokemonInventory")
	if inventory then
		local data = PokemonDB.GetPokemon(starterName)
		if data then
			local starterPoke = Instance.new("StringValue")
			starterPoke.Name = starterName
			starterPoke.Value = data.Rarity or "Common"
			starterPoke:SetAttribute("CurrentHP", data.HP)
			starterPoke:SetAttribute("MaxHP", data.HP)
			starterPoke:SetAttribute("Attack", data.Attack)
			starterPoke:SetAttribute("Status", "Alive")
			starterPoke.Parent = inventory
		end
	end

	-- Draw 3 Starter Cards (consolidated here - not in PlayerManager)
	for i = 1, 3 do
		CardSystem.drawOneCard(player)
	end

	-- Mark Ready
	TurnManager.readyPlayers[player.UserId] = true

	if Events.Notify then
		Events.Notify:FireClient(player, "🎭 คุณเลือกอาชีพ " .. jobName .. "! รอผู้เล่นคนอื่น...")
	end

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

	-- SOLO MODE: If only 1 player and they're ready, start immediately
	if allReady or (playerCount == 1 and TurnManager.readyPlayers[player.UserId]) then
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

	-- Unfreeze Everyone (Biker gets bonus speed)
	for _, p in ipairs(PlayerManager.playersInGame) do
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			local isBiker = (p:GetAttribute("Job") == "Biker")
			p.Character.Humanoid.WalkSpeed = isBiker and 32 or 24
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

	-- Check for Esper's Fixed Roll (MindMove ability)
	local fixedRoll = player:GetAttribute("FixedDiceRoll")
	local bonusRoll = player:GetAttribute("BonusDiceRoll") or 0

	local roll
	local baseRoll -- Store base roll for display
	if fixedRoll and fixedRoll > 0 then
		-- Esper: Use fixed roll (1 or 2)
		roll = fixedRoll
		baseRoll = fixedRoll
		player:SetAttribute("FixedDiceRoll", nil) -- Clear after use
		print("🔮 [Server] Esper fixed roll:", roll)
	else
		-- Normal random roll
		roll = math.random(1, 6)
		baseRoll = roll
	end

	-- Send base roll to client (dice shows 1-6)
	print("🎲 [Server] Base roll result:", baseRoll)
	Events.RollDice:FireAllClients(player, baseRoll)
	
	-- Apply Biker bonus (+2) AFTER dice animation
	if bonusRoll > 0 then
		task.wait(1.5) -- Wait for dice animation
		roll = baseRoll + bonusRoll
		player:SetAttribute("BonusDiceRoll", nil) -- Clear after use
		print("🏍️ [Server] Biker bonus applied: +" .. bonusRoll .. " (Total: " .. roll .. ")")
		
		-- Notify all players about bonus
		if Events.Notify then
			Events.Notify:FireAllClients("🏍️ " .. player.Name .. " ใช้ Turbo Boost! +" .. bonusRoll .. " ช่อง (รวม " .. roll .. " ช่อง)")
		end
		task.wait(1) -- Extra wait for notification
	else
		task.wait(2.5)
	end

	print("🎲 [Server] Final move distance:", roll)

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

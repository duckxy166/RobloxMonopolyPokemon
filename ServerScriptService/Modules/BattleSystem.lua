--[[
================================================================================
                      ⚔️ BATTLE SYSTEM - PvP & PvE Logic
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Handle PvE (Red Tile) and PvP (Player Collision)
        - Turn-based Combat (Dice Roll)
        - HP/Status Management
        - Rewards (Evolution)
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BattleSystem = {}

-- Dependencies
local Events = nil
local TimerSystem = nil
local TurnManager = nil
local PlayerManager = nil
local PokemonDB = nil
local EvolutionSystem = require(script.Parent:WaitForChild("EvolutionSystem"))

-- State
BattleSystem.activeBattles = {} -- Key: PlayerId, Value: BattleData

-- Initialize
function BattleSystem.init(events, timerSystem, turnManager, playerManager)
	Events = events
	TimerSystem = timerSystem
	TurnManager = turnManager
	PlayerManager = playerManager

	-- Load DB
	PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))

	print("✅ BattleSystem initialized")
end

-- ============================================================================
-- 🔷 HELPER FUNCTIONS
-- ============================================================================

-- Get First Alive Pokemon
function BattleSystem.getFirstAlivePokemon(player)
	local inventory = player:FindFirstChild("PokemonInventory")
	if not inventory then return nil end

	for _, poke in ipairs(inventory:GetChildren()) do
		if poke:GetAttribute("Status") == "Alive" then
			return poke
		end
	end
	return nil
end

-- Get Pokemon attributes as table
function BattleSystem.getPokeStats(pokeStrValue)
	return {
		Name = pokeStrValue.Name,
		Rarity = pokeStrValue.Value,
		CurrentHP = pokeStrValue:GetAttribute("CurrentHP") or 10,
		MaxHP = pokeStrValue:GetAttribute("MaxHP") or 10,
		Attack = pokeStrValue:GetAttribute("Attack") or 5,
		Status = pokeStrValue:GetAttribute("Status") or "Alive",
		Model = pokeStrValue.Name -- Simplification, ideally lookup DB
	}
end

-- ============================================================================
-- ⚔️ BATTLE START LOGIC
-- ============================================================================

-- Start PvE (Wild Pokemon)
-- Start PvE (Wild Pokemon / Gym)
function BattleSystem.startPvE(player, chosenPoke)
	print("⚔️ PvE Started for " .. player.Name)

	-- 1. Determine Pokemon (Chosen or Default First Alive)
	local myPoke = chosenPoke or BattleSystem.getFirstAlivePokemon(player)

	if not myPoke then
		if Events.Notify then Events.Notify:FireClient(player, "❌ All Pokemon are dead! Cannot battle.") end
		TurnManager.nextTurn()
		return
	end

	-- 2. Generate Random Enemy
	local encounter = PokemonDB.GetRandomEncounter()
	local enemyStats = {
		Name = encounter.Name,
		Level = 1,
		CurrentHP = encounter.Data.HP,
		MaxHP = encounter.Data.HP,
		Attack = encounter.Data.Attack,
		IsNPC = true
	}

	-- 3. Setup Battle State
	BattleSystem.activeBattles[player.UserId] = {
		Type = "PvE",
		Player = player,
		MyPokeObj = myPoke, -- StringValue reference
		MyStats = BattleSystem.getPokeStats(myPoke),
		EnemyStats = enemyStats,
		TurnState = "WaitRoll"
	}

	-- TELEPORT TO BATTLE STAGE
	local battleStage = game.Workspace:FindFirstChild("Stage")
	if battleStage then
		local p1Stage = battleStage:FindFirstChild("PlayerStage1")
		local pokeStage1 = battleStage:FindFirstChild("PokemonStage1")
		local pokeStage2 = battleStage:FindFirstChild("PokemonStage2")

		if p1Stage and player.Character then
			player.Character:SetPrimaryPartCFrame(p1Stage.CFrame + Vector3.new(0, 3, 0))
		end

		-- SPAWN POKEMON MODEL
		if myPoke then
			if pokeStage1 then
				BattleSystem.spawnPokemonModel(myPoke.Name, pokeStage1)
			else
				warn("⚠️ PokemonStage1 NOT found in Stage folder!")
			end
		end
		if enemyStats then
			if pokeStage2 then
				BattleSystem.spawnPokemonModel(enemyStats.Name, pokeStage2)
			else
				warn("⚠️ PokemonStage2 NOT found in Stage folder!")
			end
		end
	else
		warn("⚠️ No Stage folder found in Workspace!")
	end

	-- 4. Notify Player of their Pokemon
	if Events.Notify then 
		Events.Notify:FireClient(player, "Go! " .. myPoke.Name .. "!") 
	end

	-- 5. Send Client Event (Minimal/No UI Mode)
	Events.BattleStart:FireClient(player, "PvE", BattleSystem.activeBattles[player.UserId])
end

-- Start PvP (Player vs Player)
function BattleSystem.startPvP(player1, player2)
	print("⚔️ PvP Started: " .. player1.Name .. " vs " .. player2.Name)

	local p1Poke = BattleSystem.getFirstAlivePokemon(player1)
	local p2Poke = BattleSystem.getFirstAlivePokemon(player2)

	if not p1Poke or not p2Poke then
		if Events.Notify then Events.Notify:FireClient(player1, "❌ One of you has no alive Pokemon!") end
		TurnManager.nextTurn()
		return
	end

	-- Setup Battle State
	local battleData = {
		Type = "PvP",
		Attacker = player1,
		Defender = player2,
		AttackerPokeObj = p1Poke,
		DefenderPokeObj = p2Poke,
		AttackerStats = BattleSystem.getPokeStats(p1Poke),
		DefenderStats = BattleSystem.getPokeStats(p2Poke),
		TurnState = "WaitRoll"
	}

	BattleSystem.activeBattles[player1.UserId] = battleData
	BattleSystem.activeBattles[player2.UserId] = battleData

	-- TELEPORT TO BATTLE STAGE
	local battleStage = game.Workspace:FindFirstChild("Stage")
	if battleStage then
		local p1Stage = battleStage:FindFirstChild("PlayerStage1")
		local p2Stage = battleStage:FindFirstChild("PlayerStage2")

		if p1Stage and player1.Character then
			player1.Character:SetPrimaryPartCFrame(p1Stage.CFrame + Vector3.new(0, 3, 0))
		end
		if p2Stage and player2.Character then
			player2.Character:SetPrimaryPartCFrame(p2Stage.CFrame + Vector3.new(0, 3, 0))
		end

		-- SPAWN POKEMON MODELS
		if p1Poke then
			BattleSystem.spawnPokemonModel(p1Poke.Name, battleStage:FindFirstChild("PokemonStage1"))
		end
		if p2Poke then
			BattleSystem.spawnPokemonModel(p2Poke.Name, battleStage:FindFirstChild("PokemonStage2"))
		end
	end

	-- Notify Both
	Events.BattleStart:FireClient(player1, "PvP", battleData)
	Events.BattleStart:FireClient(player2, "PvP", battleData)
end

-- ============================================================================
-- 🎲 BATTLE LOGIC (ROLL)
-- ============================================================================

-- Process Attack Roll
function BattleSystem.processRoll(player, roll)
	local battle = BattleSystem.activeBattles[player.UserId]
	if not battle then return end

	-- Store roll
	if battle.Type == "PvE" then
		-- Player roll vs AI roll
		local aiRoll = math.random(1, 6)
		BattleSystem.resolveTurn(battle, roll, aiRoll)

	elseif battle.Type == "PvP" then
		-- Wait for both players to roll
		if player == battle.Attacker then
			battle.AttackerRoll = roll
		elseif player == battle.Defender then
			battle.DefenderRoll = roll
		end

		-- If both rolled, resolve
		if battle.AttackerRoll and battle.DefenderRoll then
			BattleSystem.resolveTurn(battle, battle.AttackerRoll, battle.DefenderRoll)
		end
	end
end

-- Resolve Turn (Damage Calculation)
function BattleSystem.resolveTurn(battle, roll1, roll2)
	-- Determine Winner
	local winner = nil -- "Attacker" or "Defender" (or "Player"/"Enemy" for PvE)
	local damage = 0

	if roll1 == roll2 then
		-- DRAW - NO DAMAGE / REROLL
		if battle.Type == "PvP" then
			-- Reset rolls
			battle.AttackerRoll = nil
			battle.DefenderRoll = nil

			Events.BattleAttack:FireClient(battle.Attacker, "Draw", 0, {AttackerRoll = roll1, DefenderRoll = roll2})
			Events.BattleAttack:FireClient(battle.Defender, "Draw", 0, {AttackerRoll = roll1, DefenderRoll = roll2})
		elseif battle.Type == "PvE" then
			Events.BattleAttack:FireClient(battle.Player, "Draw", 0, {PlayerRoll = roll1, EnemyRoll = roll2})
		end
		return
	end

	if battle.Type == "PvE" then
		-- roll1 = Player, roll2 = AI
		if roll1 > roll2 then
			winner = "Player"
			damage = battle.MyStats.Attack
			-- Damage Enemy
			battle.EnemyStats.CurrentHP = battle.EnemyStats.CurrentHP - damage
		elseif roll2 > roll1 then
			winner = "Enemy"
			damage = battle.EnemyStats.Attack
			-- Damage Player
			battle.MyStats.CurrentHP = battle.MyStats.CurrentHP - damage
			battle.MyPokeObj:SetAttribute("CurrentHP", battle.MyStats.CurrentHP)
		end

		-- Fire Update
		Events.BattleAttack:FireClient(battle.Player, winner, damage, {
			PlayerRoll = roll1, EnemyRoll = roll2,
			PlayerHP = battle.MyStats.CurrentHP, EnemyHP = battle.EnemyStats.CurrentHP
		})

		-- Check Death
		if battle.EnemyStats.CurrentHP <= 0 then
			task.spawn(function()
				task.wait(6) -- Wait for client animation
				BattleSystem.endBattle(battle, "Win")
			end)
		elseif battle.MyStats.CurrentHP <= 0 then
			-- Do NOT set "Dead" status yet effectively to avoid UI spoiler
			task.spawn(function()
				task.wait(6) -- Wait for client animation
				BattleSystem.endBattle(battle, "Lose")
			end)
		end

	elseif battle.Type == "PvP" then
		-- roll1 = Attacker, roll2 = Defender
		local attacker = battle.Attacker
		local defender = battle.Defender

		if roll1 > roll2 then
			winner = "Attacker"
			damage = battle.AttackerStats.Attack
			-- Damage Defender
			battle.DefenderStats.CurrentHP = battle.DefenderStats.CurrentHP - damage
			battle.DefenderPokeObj:SetAttribute("CurrentHP", battle.DefenderStats.CurrentHP)
		elseif roll2 > roll1 then
			winner = "Defender"
			damage = battle.DefenderStats.Attack
			-- Damage Attacker
			battle.AttackerStats.CurrentHP = battle.AttackerStats.CurrentHP - damage
			battle.AttackerPokeObj:SetAttribute("CurrentHP", battle.AttackerStats.CurrentHP)
		end

		-- Notify Both
		local updateData = {
			Winner = winner, Damage = damage,
			AttackerRoll = roll1, DefenderRoll = roll2,
			AttackerHP = battle.AttackerStats.CurrentHP,
			DefenderHP = battle.DefenderStats.CurrentHP
		}
		Events.BattleAttack:FireClient(attacker, winner, damage, updateData)
		Events.BattleAttack:FireClient(defender, winner, damage, updateData)

		-- Check Death
		if battle.DefenderStats.CurrentHP <= 0 then
			-- battle.DefenderPokeObj:SetAttribute("Status", "Dead") -- Delayed to endBattle
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "AttackerWin")
			end)
		elseif battle.AttackerStats.CurrentHP <= 0 then
			-- battle.AttackerPokeObj:SetAttribute("Status", "Dead") -- Delayed to endBattle
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "DefenderWin")
			end)
		else
			-- Reset rolls for next round
			battle.AttackerRoll = nil
			battle.DefenderRoll = nil
		end
	end
end

-- End Battle
function BattleSystem.endBattle(battle, result)
	print("🏁 Battle Ended: " .. result)

	-- === 0. Update Dead Status (Delayed from resolveTurn) ===
	if battle.Type == "PvE" then
		if battle.MyStats.CurrentHP <= 0 then
			battle.MyPokeObj:SetAttribute("Status", "Dead")
		end
	elseif battle.Type == "PvP" then
		if battle.AttackerStats.CurrentHP <= 0 then
			battle.AttackerPokeObj:SetAttribute("Status", "Dead")
		end
		if battle.DefenderStats.CurrentHP <= 0 then
			battle.DefenderPokeObj:SetAttribute("Status", "Dead")
		end
	end

	local tilesFolder = game.Workspace:FindFirstChild("Tiles")

	-- === 1. Prepare Global Announcement Message ===
	local winnerName = "Someone"
	local loserName = "Someone"
	local finalMsg = ""
	
	if battle.Type == "PvE" then
		winnerName = (result == "Win") and battle.Player.Name or battle.EnemyStats.Name
		loserName = (result == "Win") and battle.EnemyStats.Name or battle.Player.Name
		
		if result == "Win" then
			finalMsg = "🏆 " .. winnerName .. " defeated wild " .. loserName .. "!"
		else
			finalMsg = "💀 " .. winnerName .. " knocked out " .. loserName .. "!"
		end
		
		-- Notify Result Global
		Events.BattleEnd:FireAllClients(finalMsg) -- Send String Message directly
		
		-- Clear reference
		BattleSystem.activeBattles[battle.Player.UserId] = nil

		if result == "Win" then
			-- Reward: Evolution or Money
			local success = EvolutionSystem.tryEvolve(battle.Player)
			if not success then
				battle.Player.leaderstats.Money.Value += 3
				if Events.Notify then Events.Notify:FireClient(battle.Player, "⭐ No evolution available. +3 Coins!") end
			end
		end

		-- Return to Board
		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Player, tilesFolder)
		end
		TurnManager.nextTurn()

	elseif battle.Type == "PvP" then
		local winner = nil
		if result == "AttackerWin" then
			winner = battle.Attacker
			winnerName = battle.Attacker.Name
			loserName = battle.Defender.Name
		else
			winner = battle.Defender
			winnerName = battle.Defender.Name
			loserName = battle.Attacker.Name
		end
		
		finalMsg = "⚔️ PvP Result: " .. winnerName .. " defeated " .. loserName .. "!"
		
		-- Reward Winner
		local success = EvolutionSystem.tryEvolve(winner)
		if not success then
			winner.leaderstats.Money.Value += 3
			if Events.Notify then Events.Notify:FireClient(winner, "⭐ No evolution available. +3 Coins!") end
		end
		
		-- Notify Result Global
		Events.BattleEnd:FireAllClients(finalMsg)

		BattleSystem.activeBattles[battle.Attacker.UserId] = nil
		BattleSystem.activeBattles[battle.Defender.UserId] = nil

		-- Return both to Board
		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Attacker, tilesFolder)
			PlayerManager.teleportToLastTile(battle.Defender, tilesFolder)
		end

		TurnManager.nextTurn()
	end
	
	-- === 2. CLEANUP MODELS (Fix for Stuck Models) ===
	print("🧹 Cleaning up Battle Stage Models...")
	local battleStage = game.Workspace:FindFirstChild("Stage")
	if battleStage then
		local stages = {
			battleStage:FindFirstChild("PokemonStage1"),
			battleStage:FindFirstChild("PokemonStage2")
		}
		for _, stage in ipairs(stages) do
			if stage then
				for _, child in ipairs(stage:GetChildren()) do
					if child:IsA("Model") then
						child:Destroy()
					end
				end
			end
		end
	end
end

function BattleSystem.connectEvents()
	-- Listen for Battle Roll input from client
	if Events.BattleAttack then
		Events.BattleAttack.OnServerEvent:Connect(function(player)
			-- Client creates this event to signal "Roll Dice"
			-- We reuse it as input signal

			local roll = math.random(1, 6)
			BattleSystem.processRoll(player, roll)
		end)
	end

	if Events.BattleTriggerResponse then
		Events.BattleTriggerResponse.OnServerEvent:Connect(function(player, action, data)
			print("⚔️ [Server] BattleTriggerResponse Received from " .. player.Name .. ": " .. tostring(action))
			BattleSystem.handleTriggerResponse(player, action, data)
		end)
	end
end

-- Spawn Pokemon Model Helper
function BattleSystem.spawnPokemonModel(pokeName, stagePart)
	if not stagePart then return end

	-- Clear existing
	for _, child in ipairs(stagePart:GetChildren()) do
		if child:IsA("Model") then child:Destroy() end
	end

	-- Clone new
	-- Search Logic
	local modelTemplate = ServerStorage:FindFirstChild(pokeName, true)
	if not modelTemplate then
		local folder = ServerStorage:FindFirstChild("PokemonModels")
		if folder then 
			modelTemplate = folder:FindFirstChild(pokeName) 
			if not modelTemplate then
				-- Try loose match
				for _, child in ipairs(folder:GetChildren()) do
					if child.Name:match("^%s*" .. pokeName .. "%s*$") then
						modelTemplate = child
						break
					end
				end
			end
		end
	end

	if modelTemplate then
		local cloned = modelTemplate:Clone()
		cloned.Parent = stagePart -- Parent to stage so cleanup works!

		-- Ensure PrimaryPart exists
		if not cloned.PrimaryPart then
			local root = cloned:FindFirstChild("HumanoidRootPart") or cloned:FindFirstChildWhichIsA("BasePart", true)
			if root then
				cloned.PrimaryPart = root
			else
				warn("⚠️ Model '" .. pokeName .. "' has no BasePart to position!")
			end
		end

		if cloned.PrimaryPart then
			local targetCFrame = stagePart.CFrame + Vector3.new(0, 3, 0) -- Higher up to avoid clipping
			cloned:SetPrimaryPartCFrame(targetCFrame)
			print("   ✅ Spawned " .. pokeName .. " at " .. tostring(targetCFrame.Position))
		end

		-- Anchor EVERYTHING so it doesn't fall
		for _, desc in ipairs(cloned:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end
	else
		print("⚠️ Model not found for: " .. pokeName)
	end
end

-- Handle Trigger Response
function BattleSystem.handleTriggerResponse(player, action, data)
	print("Battle Trigger Response:", player.Name, action)

	if action == "Fight" then
		if data and data.Type == "PvE" then
			-- Find chosen pokemon if name provided
			local chosenPoke = nil
			if data.SelectedPokemonName then
				local inventory = player:FindFirstChild("PokemonInventory")
				if inventory then
					chosenPoke = inventory:FindFirstChild(data.SelectedPokemonName)
				end
			end
			BattleSystem.startPvE(player, chosenPoke)
		elseif data and data.Type == "PvP" then
			-- PvP requires opponent selection if multiple, or just first one
			-- Simplify: If target provided, fight them
			local target = data.Target
			if target then
				BattleSystem.startPvP(player, target)
			end
		end
	else
		-- Run / Decline
		TurnManager.nextTurn()
	end
end

return BattleSystem

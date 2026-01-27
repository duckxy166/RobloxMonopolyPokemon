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
function BattleSystem.startPvE(player)
	print("⚔️ PvE Started for " .. player.Name)
	
	-- 1. Check if player has alive pokemon
	local myPoke = BattleSystem.getFirstAlivePokemon(player)
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
	local battleStage = game.Workspace:FindFirstChild("BattleStage")
	if battleStage then
		local p1Stage = battleStage:FindFirstChild("PlayerStage1")
		if p1Stage and player.Character then
			player.Character:SetPrimaryPartCFrame(p1Stage.CFrame + Vector3.new(0, 3, 0))
		end
	else
		print("⚠️ No BattleStage folder found in Workspace!")
	end
	
	-- 4. Send Client Event (Minimal/No UI Mode)
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
	local battleStage = game.Workspace:FindFirstChild("BattleStage")
	if battleStage then
		local p1Stage = battleStage:FindFirstChild("PlayerStage1")
		local p2Stage = battleStage:FindFirstChild("PlayerStage2")
		
		if p1Stage and player1.Character then
			player1.Character:SetPrimaryPartCFrame(p1Stage.CFrame + Vector3.new(0, 3, 0))
		end
		if p2Stage and player2.Character then
			player2.Character:SetPrimaryPartCFrame(p2Stage.CFrame + Vector3.new(0, 3, 0))
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
		else
			winner = "Draw"
		end
		
		-- Fire Update
		Events.BattleAttack:FireClient(battle.Player, winner, damage, {
			PlayerRoll = roll1, EnemyRoll = roll2,
			PlayerHP = battle.MyStats.CurrentHP, EnemyHP = battle.EnemyStats.CurrentHP
		})
		
		-- Check Death
		if battle.EnemyStats.CurrentHP <= 0 then
			BattleSystem.endBattle(battle, "Win")
		elseif battle.MyStats.CurrentHP <= 0 then
			battle.MyPokeObj:SetAttribute("Status", "Dead")
			BattleSystem.endBattle(battle, "Lose")
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
		else
			winner = "Draw"
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
			battle.DefenderPokeObj:SetAttribute("Status", "Dead")
			BattleSystem.endBattle(battle, "AttackerWin")
		elseif battle.AttackerStats.CurrentHP <= 0 then
			battle.AttackerPokeObj:SetAttribute("Status", "Dead")
			BattleSystem.endBattle(battle, "DefenderWin")
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
	
	local tilesFolder = game.Workspace:FindFirstChild("Tiles")
	
	if battle.Type == "PvE" then
		Events.BattleEnd:FireClient(battle.Player, result)
		BattleSystem.activeBattles[battle.Player.UserId] = nil
		
		if result == "Win" then
			-- Reward: Evolution (TODO: Open Evolution UI)
			if Events.Notify then Events.Notify:FireClient(battle.Player, "🏆 You Won! Evolution logic coming soon.") end
		end
		
		-- Return to Board
		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Player, tilesFolder)
		end
		TurnManager.nextTurn()
		
	elseif battle.Type == "PvP" then
		Events.BattleEnd:FireClient(battle.Attacker, result)
		Events.BattleEnd:FireClient(battle.Defender, result)
		
		BattleSystem.activeBattles[battle.Attacker.UserId] = nil
		BattleSystem.activeBattles[battle.Defender.UserId] = nil
		
		-- Return both to Board
		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Attacker, tilesFolder)
			PlayerManager.teleportToLastTile(battle.Defender, tilesFolder)
		end
		
		TurnManager.nextTurn()
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
end

return BattleSystem

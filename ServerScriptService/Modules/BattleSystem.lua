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

-- ============================================================================
-- ✅ STAGE / TELEPORT HELPERS (FIX)
-- ============================================================================

local function getAnchorCFrame(stageObj)
	if not stageObj then return nil end

	if stageObj:IsA("BasePart") then
		return stageObj.CFrame
	end

	if stageObj:IsA("Model") then
		if stageObj.PrimaryPart then
			return stageObj.PrimaryPart.CFrame
		end

		local anyPart = stageObj:FindFirstChildWhichIsA("BasePart", true)
		if anyPart then
			return anyPart.CFrame
		end
	end

	return nil
end

local function teleportCharacterTo(player, stageObj)
	if not (player and player.Character) then return end
	local cf = getAnchorCFrame(stageObj)
	if not cf then
		warn("⚠️ teleportCharacterTo: no anchor CFrame for", stageObj)
		return
	end
	player.Character:PivotTo(cf * CFrame.new(0, 3, 0))
end

local function getOrCreateSpawnFolder(stageObj)
	if not stageObj then return nil end

	local folder = stageObj:FindFirstChild("SpawnedModels")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SpawnedModels"
		folder.Parent = stageObj
	end
	return folder
end

local function clearSpawnFolder(stageObj)
	local folder = stageObj and stageObj:FindFirstChild("SpawnedModels")
	if not folder then return end
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
end

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
		Model = pokeStrValue:GetAttribute("ModelName") or pokeStrValue.Name
	}
end

-- ============================================================================
-- 🧩 SPAWN POKEMON MODEL (FIXED)
-- ============================================================================

local function findAnchorPart(obj)
	if not obj then return nil end
	if obj:IsA("BasePart") then return obj end
	if obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	if obj:IsA("Folder") then
		return obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getSpawnFolder(stageRoot, keyName)
	local root = stageRoot:FindFirstChild("SpawnedPokemon")
	if not root then
		root = Instance.new("Folder")
		root.Name = "SpawnedPokemon"
		root.Parent = stageRoot
	end

	local f = root:FindFirstChild(keyName)
	if not f then
		f = Instance.new("Folder")
		f.Name = keyName
		f.Parent = root
	end

	f:ClearAllChildren()
	return f
end

local function resolveModelName(pokemonName)
	-- If your PokemonDB has GetPokemon(name) returning { Model = "155 - Cyndaquil", ... }
	if PokemonDB and PokemonDB.GetPokemon then
		local data = PokemonDB.GetPokemon(pokemonName)
		if data and data.Model then
			return data.Model
		end
	end
	return pokemonName
end

function BattleSystem.spawnPokemonModel(modelName, stageObj, pokemonName, rarity)
	local stageRoot = workspace:FindFirstChild("Stage")
	if not stageRoot then
		warn("⚠️ spawnPokemonModel: Workspace.Stage not found")
		return
	end

	local anchor = findAnchorPart(stageObj)
	if not anchor then
		warn("⚠️ spawnPokemonModel: no anchor BasePart for", stageObj and stageObj:GetFullName() or "nil")
		return
	end

	local modelsFolder = ServerStorage:FindFirstChild("PokemonModels")
	if not modelsFolder then
		warn("⚠️ spawnPokemonModel: ServerStorage.PokemonModels not found")
		return
	end
	local template = modelsFolder:FindFirstChild(modelName) or ServerStorage:FindFirstChild(modelName, true)
	if not template or not template:IsA("Model") then
		warn("⚠️ spawnPokemonModel: model not found or not a Model:", modelName)
		return
	end

	local key = (stageObj and stageObj.Name) or "UnknownStage"
	local spawnFolder = getSpawnFolder(stageRoot, key)

	local clone = template:Clone()
	clone.Parent = spawnFolder

	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end

	clone:PivotTo(anchor.CFrame * CFrame.new(0, 3, 0))
	print(("✅ Spawned '%s' on %s"):format(modelName, key))

	-- Add Name Label with Rarity Color
	if pokemonName and rarity then
		local UIHelpers = require(ReplicatedStorage:WaitForChild("UIHelpers"))
		UIHelpers.CreateNameLabel(clone, pokemonName, rarity)
	end

	return clone
end


-- ============================================================================
-- ⚔️ BATTLE START LOGIC
-- ============================================================================

-- Start PvE (Wild Pokemon / Gym)
function BattleSystem.startPvE(player, chosenPoke, desiredRarity)
	print("⚔️ PvE Started for " .. player.Name .. " (Rarity: " .. tostring(desiredRarity) .. ")")

	-- 1. Determine Pokemon (Chosen or Default First Alive)
	local myPoke = chosenPoke or BattleSystem.getFirstAlivePokemon(player)

	if not myPoke then
		if Events.Notify then Events.Notify:FireClient(player, "❌ All Pokemon are dead! Cannot battle.") end
		TurnManager.nextTurn()
		return
	end

	-- 2. Generate Random Enemy
	local encounter = nil
	if desiredRarity then
		encounter = PokemonDB.GetRandomByRarity(desiredRarity)
	end
	if not encounter then
		encounter = PokemonDB.GetRandomEncounter()
	end

	-- ✅ Support optional encounter.ModelName (if you have it in your DB)
	local enemyModelName =
		(encounter and encounter.ModelName)
		or (encounter and encounter.Name)
		or (encounter and encounter.Data and encounter.Data.Name)
		or "Unknown"

	local enemyStats = {
		Name = encounter.Name or (encounter.Data and encounter.Data.Name) or "Unknown",
		ModelName = enemyModelName,
		Level = 1,
		CurrentHP = encounter.Data and encounter.Data.HP or 10,
		MaxHP = encounter.Data and encounter.Data.HP or 10,
		Attack = encounter.Data and encounter.Data.Attack or 5,
		IsNPC = true
	}

	-- 3. Setup Battle State
	BattleSystem.activeBattles[player.UserId] = {
		Type = "PvE",
		Player = player,
		MyPokeObj = myPoke,
		MyStats = BattleSystem.getPokeStats(myPoke),
		EnemyStats = enemyStats,
		TurnState = "WaitRoll"
	}

	-- TELEPORT TO BATTLE STAGE (RECURSIVE + RELIABLE)
	local battleStage = workspace:FindFirstChild("Stage")
	if not battleStage then
		warn("⚠️ No Stage folder found in Workspace! Aborting battle.")
		return
	end

	local p1Stage = battleStage:FindFirstChild("PlayerStage1", true)
	local pokeStage1 = battleStage:FindFirstChild("PokemonStage1", true)
	local pokeStage2 = battleStage:FindFirstChild("PokemonStage2", true)

	-- Safe teleport (no PrimaryPart needed)
	do
		local anchor = (p1Stage and (p1Stage:IsA("BasePart") and p1Stage or p1Stage:FindFirstChildWhichIsA("BasePart", true))) or nil
		if anchor and player.Character then
			player.Character:PivotTo(anchor.CFrame * CFrame.new(0, 3, 0))
		else
			warn("⚠️ PlayerStage1 missing/bad. Aborting battle.")
			return
		end
	end

	local myModelName = myPoke:GetAttribute("ModelName") or resolveModelName(myPoke.Name)
	local myRarity = myPoke.Value or "Common"
	BattleSystem.spawnPokemonModel(myModelName, pokeStage1, myPoke.Name, myRarity)

	-- prefer DB model name if it exists, fallback to resolving by name
	local enemyModel = (encounter and encounter.Data and encounter.Data.Model) or resolveModelName(enemyStats.Name)
	local enemyRarity = (encounter and encounter.Data and encounter.Data.Rarity) or "Common"
	BattleSystem.spawnPokemonModel(enemyModel, pokeStage2, enemyStats.Name, enemyRarity)


	-- 4. Notify Player
	if Events.Notify then
		Events.Notify:FireClient(player, "Go! " .. myPoke.Name .. "!")
		-- Broadcast to all players
		Events.Notify:FireAllClients("⚔️ " .. player.Name .. " entered a PvE battle!")
	end

	-- 5. Send Client Event to Active Player
	Events.BattleStart:FireClient(player, "PvE", BattleSystem.activeBattles[player.UserId])
	
	-- 6. Send to Spectators (all other players)
	for _, spectator in ipairs(game.Players:GetPlayers()) do
		if spectator ~= player then
			local spectatorData = {
				Type = "PvE",
				Player = player,
				MyStats = BattleSystem.activeBattles[player.UserId].MyStats,
				EnemyStats = BattleSystem.activeBattles[player.UserId].EnemyStats,
				IsSpectator = true
			}
			Events.BattleStart:FireClient(spectator, "PvE", spectatorData)
		end
	end
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

	-- TELEPORT TO BATTLE STAGE (RECURSIVE + RELIABLE)
	local battleStage = workspace:FindFirstChild("Stage")
	if not battleStage then
		warn("⚠️ No Stage folder found in Workspace! Aborting battle.")
		return
	end

	local p1Stage = battleStage:FindFirstChild("PlayerStage1", true)
	local p2Stage = battleStage:FindFirstChild("PlayerStage2", true)
	local pokeStage1 = battleStage:FindFirstChild("PokemonStage1", true)
	local pokeStage2 = battleStage:FindFirstChild("PokemonStage2", true)

	local function safeTeleport(plr, stageObj, label)
		local anchor = (stageObj and (stageObj:IsA("BasePart") and stageObj or stageObj:FindFirstChildWhichIsA("BasePart", true))) or nil
		if anchor and plr.Character then
			plr.Character:PivotTo(anchor.CFrame * CFrame.new(0, 3, 0))
			return true
		end
		warn("⚠️ " .. label .. " missing/bad. Aborting battle.")
		return false
	end

	if not safeTeleport(player1, p1Stage, "PlayerStage1") then return end
	if not safeTeleport(player2, p2Stage, "PlayerStage2") then return end

	local aModel = p1Poke:GetAttribute("ModelName") or resolveModelName(p1Poke.Name)
	local dModel = p2Poke:GetAttribute("ModelName") or resolveModelName(p2Poke.Name)
	local aRarity = p1Poke.Value or "Common"
	local dRarity = p2Poke.Value or "Common"
	BattleSystem.spawnPokemonModel(aModel, pokeStage1, p1Poke.Name, aRarity)
	BattleSystem.spawnPokemonModel(dModel, pokeStage2, p2Poke.Name, dRarity)


	-- Notify Both
	local attackerBasicData = {
		Type = "PvP",
		Attacker = player1,
		Defender = player2,
		MyStats = battleData.AttackerStats,
		EnemyStats = battleData.DefenderStats,
		Target = "Roll",
		TurnState = "WaitRoll"
	}

	local defenderBasicData = {
		Type = "PvP",
		Attacker = player1,
		Defender = player2,
		MyStats = battleData.DefenderStats,
		EnemyStats = battleData.AttackerStats,
		Target = "Roll",
		TurnState = "WaitRoll"
	}

	Events.BattleStart:FireClient(player1, "PvP", attackerBasicData)
	Events.BattleStart:FireClient(player2, "PvP", defenderBasicData)
	
	-- Broadcast to all players
	if Events.Notify then
		Events.Notify:FireAllClients("⚔️ " .. player1.Name .. " vs " .. player2.Name .. " - PvP Battle!")
	end
	
	-- Send to Spectators (all other players)
	for _, spectator in ipairs(game.Players:GetPlayers()) do
		if spectator ~= player1 and spectator ~= player2 then
			local spectatorData = {
				Type = "PvP",
				Attacker = player1,
				Defender = player2,
				AttackerStats = battleData.AttackerStats,
				DefenderStats = battleData.DefenderStats,
				IsSpectator = true
			}
			Events.BattleStart:FireClient(spectator, "PvP", spectatorData)
		end
	end
end

-- ============================================================================
-- 🎲 BATTLE LOGIC (ROLL)
-- ============================================================================

function BattleSystem.processRoll(player, roll)
	local battle = BattleSystem.activeBattles[player.UserId]
	if not battle then return end

	if battle.Type == "PvE" then
		local aiRoll = math.random(1, 6)
		BattleSystem.resolveTurn(battle, roll, aiRoll)

	elseif battle.Type == "PvP" then
		if player == battle.Attacker then
			battle.AttackerRoll = roll
		elseif player == battle.Defender then
			battle.DefenderRoll = roll
		end

		if battle.AttackerRoll and battle.DefenderRoll then
			BattleSystem.resolveTurn(battle, battle.AttackerRoll, battle.DefenderRoll)
		end
	end
end

function BattleSystem.resolveTurn(battle, roll1, roll2)
	local winner = nil
	local damage = 0

	if roll1 == roll2 then
		if battle.Type == "PvP" then
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
		if roll1 > roll2 then
			winner = "Player"
			damage = battle.MyStats.Attack
			battle.EnemyStats.CurrentHP -= damage
		else
			winner = "Enemy"
			damage = battle.EnemyStats.Attack
			battle.MyStats.CurrentHP -= damage
			battle.MyPokeObj:SetAttribute("CurrentHP", battle.MyStats.CurrentHP)
		end

		Events.BattleAttack:FireClient(battle.Player, winner, damage, {
			PlayerRoll = roll1, EnemyRoll = roll2,
			PlayerHP = battle.MyStats.CurrentHP, EnemyHP = battle.EnemyStats.CurrentHP
		})

		if battle.EnemyStats.CurrentHP <= 0 then
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "Win")
			end)
		elseif battle.MyStats.CurrentHP <= 0 then
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "Lose")
			end)
		end

	elseif battle.Type == "PvP" then
		local attacker = battle.Attacker
		local defender = battle.Defender

		if roll1 > roll2 then
			winner = "Attacker"
			damage = battle.AttackerStats.Attack
			battle.DefenderStats.CurrentHP -= damage
			battle.DefenderPokeObj:SetAttribute("CurrentHP", battle.DefenderStats.CurrentHP)
		else
			winner = "Defender"
			damage = battle.DefenderStats.Attack
			battle.AttackerStats.CurrentHP -= damage
			battle.AttackerPokeObj:SetAttribute("CurrentHP", battle.AttackerStats.CurrentHP)
		end

		local updateData = {
			Winner = winner, Damage = damage,
			AttackerRoll = roll1, DefenderRoll = roll2,
			AttackerHP = battle.AttackerStats.CurrentHP,
			DefenderHP = battle.DefenderStats.CurrentHP
		}
		Events.BattleAttack:FireClient(attacker, winner, damage, updateData)
		Events.BattleAttack:FireClient(defender, winner, damage, updateData)

		if battle.DefenderStats.CurrentHP <= 0 then
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "AttackerWin")
			end)
		elseif battle.AttackerStats.CurrentHP <= 0 then
			task.spawn(function()
				task.wait(6)
				BattleSystem.endBattle(battle, "DefenderWin")
			end)
		else
			battle.AttackerRoll = nil
			battle.DefenderRoll = nil
		end
	end
end

-- ============================================================================
-- 🏁 END BATTLE + CLEANUP (UPDATED)
-- ============================================================================

function BattleSystem.endBattle(battle, result)
	print("🏁 Battle Ended: " .. result)

	-- Delayed Dead Status set
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

	local tilesFolder = workspace:FindFirstChild("Tiles")

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

		Events.BattleEnd:FireAllClients(finalMsg)
		BattleSystem.activeBattles[battle.Player.UserId] = nil

		if result == "Win" then
			local success = EvolutionSystem.tryEvolve(battle.Player)
			if not success then
				battle.Player.leaderstats.Money.Value += 3
				if Events.Notify then Events.Notify:FireClient(battle.Player, "⭐ No evolution available. +3 Coins!") end
			end
		end

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

		local success = EvolutionSystem.tryEvolve(winner)
		if not success then
			winner.leaderstats.Money.Value += 3
			if Events.Notify then Events.Notify:FireClient(winner, "⭐ No evolution available. +3 Coins!") end
		end

		Events.BattleEnd:FireAllClients(finalMsg)

		BattleSystem.activeBattles[battle.Attacker.UserId] = nil
		BattleSystem.activeBattles[battle.Defender.UserId] = nil

		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Attacker, tilesFolder)
			PlayerManager.teleportToLastTile(battle.Defender, tilesFolder)
		end

		TurnManager.nextTurn()
	end

	print("🧹 Cleaning up Battle Stage Models...")
	local battleStage = workspace:FindFirstChild("Stage")
	if battleStage then
		local spawned = battleStage:FindFirstChild("SpawnedPokemon")
		if spawned then
			spawned:ClearAllChildren()
		end
	end
end

-- ============================================================================
-- 🔌 EVENT CONNECTIONS
-- ============================================================================

function BattleSystem.connectEvents()
	if Events.BattleAttack then
		Events.BattleAttack.OnServerEvent:Connect(function(player)
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

-- Handle Trigger Response
function BattleSystem.handleTriggerResponse(player, action, data)
	print("Battle Trigger Response:", player.Name, action)

	if action == "Fight" then
		if data and data.Type == "PvE" then
			local chosenPoke = nil

			if data.SelectedPokemonName then
				local inventory = player:FindFirstChild("PokemonInventory")
				if inventory then
					chosenPoke = inventory:FindFirstChild(data.SelectedPokemonName)
				end
			end

			BattleSystem.startPvE(player, chosenPoke, data.Rarity)

		elseif data and data.Type == "PvP" then
			local target = data.Target
			if target then
				BattleSystem.startPvP(player, target)
			end
		end
	else
		if data and data.Type == "PvP" then
			print("🏃 Declined PvP. Resuming Tile Event.")
			TurnManager.resumeTurn(player)
		else
			TurnManager.nextTurn()
		end
	end
end


return BattleSystem

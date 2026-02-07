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
BattleSystem.lastRollTime = {}  -- Track last roll time per player (anti-spam)
BattleSystem.lastBattleOpponent = {} -- Key: UserId, Value: OpponentUserId
BattleSystem.pendingBattles = {} -- Key: DefenderUserId, Value: {Attacker, AttackerPokeName}

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

-- Check if player is busy (Active Battle or Pending PvP)
function BattleSystem.isPlayerBusy(player)
	-- 1. Active Battle
	if BattleSystem.activeBattles[player.UserId] then return true end
	
	-- 2. Pending Battle (Defender)
	if BattleSystem.pendingBattles[player.UserId] then return true end

	-- 3. Pending Battle (Attacker)
	for _, data in pairs(BattleSystem.pendingBattles) do
		if data.Attacker == player then return true end
	end
	
	return false
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

function BattleSystem.spawnPokemonModel(modelName, stageObj, pokemonName, rarity, faceNegativeZ)
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


	-- Calculate spawn position and rotation
	local anchorPos = anchor.CFrame.Position
	local anchorTopY = anchorPos.Y + (anchor.Size.Y / 2)

	-- Get model bounding box to find the actual bottom
	local modelCF, modelSize = clone:GetBoundingBox()
	local currentPivot = clone:GetPivot()

	-- Calculate the distance from the current pivot to the bottom of the model
	local modelCenterY = modelCF.Position.Y
	local modelBottomY = modelCenterY - (modelSize.Y / 2)
	local pivotToBottomOffset = currentPivot.Position.Y - modelBottomY

	-- Rotation: 0 degrees for -Z face (faceNegativeZ=true), 180 degrees for +Z face (faceNegativeZ=false)
	local yRotation = faceNegativeZ and 0 or math.rad(180)

	-- Position model so its bottom sits exactly on top of the stage
	local spawnCF = CFrame.new(anchorPos.X, anchorTopY + pivotToBottomOffset, anchorPos.Z) * CFrame.Angles(0, yRotation, 0)

	clone:PivotTo(spawnCF)
	print(("✅ Spawned '%s' on %s (facing %s)"):format(modelName, key, faceNegativeZ and "+Z" or "-Z"))

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

	-- 3. Reset Pokemon HP to full before battle
	local maxHP = myPoke:GetAttribute("MaxHP") or 10
	myPoke:SetAttribute("CurrentHP", maxHP)

	-- 4. Setup Battle State
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

	-- Safe teleport (no PrimaryPart needed) - Player faces -Z
	do
		local anchor = (p1Stage and (p1Stage:IsA("BasePart") and p1Stage or p1Stage:FindFirstChildWhichIsA("BasePart", true))) or nil
		if anchor and player.Character then
			local anchorPos = anchor.CFrame.Position
			local anchorTopY = anchorPos.Y + (anchor.Size.Y / 2) + 3
			player.Character:PivotTo(CFrame.new(anchorPos.X, anchorTopY, anchorPos.Z)) -- Face +Z (no rotation)
		else
			warn("⚠️ PlayerStage1 missing/bad. Aborting battle.")
			return
		end
	end

	local myModelName = myPoke:GetAttribute("ModelName") or resolveModelName(myPoke.Name)
	local myRarity = myPoke.Value or "Common"
	BattleSystem.spawnPokemonModel(myModelName, pokeStage1, myPoke.Name, myRarity, true) -- Face -Z

	-- prefer DB model name if it exists, fallback to resolving by name
	local enemyModel = (encounter and encounter.Data and encounter.Data.Model) or resolveModelName(enemyStats.Name)
	local enemyRarity = (encounter and encounter.Data and encounter.Data.Rarity) or "Common"
	BattleSystem.spawnPokemonModel(enemyModel, pokeStage2, enemyStats.Name, enemyRarity, false) -- Face +Z


	-- 4. Notify Player
	if Events.Notify then
		Events.Notify:FireClient(player, "Go! " .. myPoke.Name .. "!")
		-- Broadcast to all players
		Events.Notify:FireAllClients("⚔️ " .. player.Name .. " entered a PvE battle!")
	end

	-- 5. Send Client Event to Active Player
	Events.BattleStart:FireClient(player, "PvE", BattleSystem.activeBattles[player.UserId])

	-- 6. Send to Spectators (watch-only mode)
	for _, spectator in ipairs(game.Players:GetPlayers()) do
		if spectator ~= player then
			local spectatorData = {
				Type = "PvE",
				Player = player,
				MyStats = BattleSystem.activeBattles[player.UserId].MyStats,
				EnemyStats = BattleSystem.activeBattles[player.UserId].EnemyStats,
				IsSpectator = true  -- Flag to hide Roll button
			}
			Events.BattleStart:FireClient(spectator, "PvE", spectatorData)
		end
	end
end

-- Start PvP (Player vs Player)
function BattleSystem.startPvP(player1, player2, p1ChosenPoke, p2ChosenPoke)
	print("⚔️ PvP Started: " .. player1.Name .. " vs " .. player2.Name)

	local p1Poke = p1ChosenPoke or BattleSystem.getFirstAlivePokemon(player1)
	local p2Poke = p2ChosenPoke or BattleSystem.getFirstAlivePokemon(player2)

	if not p1Poke or not p2Poke then
		if Events.Notify then 
			if not p1Poke then Events.Notify:FireClient(player1, "❌ You have no alive Pokemon!") end
			if not p2Poke then Events.Notify:FireClient(player1, "❌ " .. player2.Name .. " has no alive Pokemon!") end
		end
		TurnManager.resumeTurn(player1) -- Cancel PvP, resume turn
		return
	end

	-- Force cleanup any existing encounter on Client/Server
	if EncounterSystem then
		EncounterSystem.clearCenterStage()
	end
	if TimerSystem then TimerSystem.cancelTimer() end

	-- Reset both Pokemon HP to full before battle
	local p1MaxHP = p1Poke:GetAttribute("MaxHP") or 10
	local p2MaxHP = p2Poke:GetAttribute("MaxHP") or 10
	p1Poke:SetAttribute("CurrentHP", p1MaxHP)
	p2Poke:SetAttribute("CurrentHP", p2MaxHP)

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

	local function safeTeleport(plr, stageObj, label, faceNegativeZ)
		local anchor = (stageObj and (stageObj:IsA("BasePart") and stageObj or stageObj:FindFirstChildWhichIsA("BasePart", true))) or nil
		if anchor and plr.Character then
			local anchorPos = anchor.CFrame.Position
			local anchorTopY = anchorPos.Y + (anchor.Size.Y / 2) + 3
			local yRotation = faceNegativeZ and 0 or math.rad(180)  -- Inverted
			plr.Character:PivotTo(CFrame.new(anchorPos.X, anchorTopY, anchorPos.Z) * CFrame.Angles(0, yRotation, 0))
			return true
		end
		warn("⚠️ " .. label .. " missing/bad. Aborting battle.")
		return false
	end

	if not safeTeleport(player1, p1Stage, "PlayerStage1", true) then return end  -- Face -Z
	if not safeTeleport(player2, p2Stage, "PlayerStage2", false) then return end -- Face +Z

	local aModel = p1Poke:GetAttribute("ModelName") or resolveModelName(p1Poke.Name)
	local dModel = p2Poke:GetAttribute("ModelName") or resolveModelName(p2Poke.Name)
	local aRarity = p1Poke.Value or "Common"
	local dRarity = p2Poke.Value or "Common"
	BattleSystem.spawnPokemonModel(aModel, pokeStage1, p1Poke.Name, aRarity, true) -- Face -Z
	BattleSystem.spawnPokemonModel(dModel, pokeStage2, p2Poke.Name, dRarity, false) -- Face +Z


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
				MyStats = battleData.AttackerStats, -- Left side (attacker)
				EnemyStats = battleData.DefenderStats, -- Right side (defender)
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
	if battle.Resolved then return end

	-- Anti-spam: Check cooldown (1 second between rolls)
	local now = tick()
	local lastRoll = BattleSystem.lastRollTime[player.UserId] or 0
	if (now - lastRoll) < 1 then
		warn("⚠️ Battle roll spam detected from " .. player.Name)
		return
	end
	BattleSystem.lastRollTime[player.UserId] = now

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

	-- ============================================
	-- BATTLE WITH HP/DAMAGE SYSTEM
	-- Winner deals damage based on Attack stat
	-- Battle ends when HP reaches 0
	-- Draw = re-roll (return and wait for next roll)
	-- ============================================

	if roll1 == roll2 then
		local drawData = {
			PlayerRoll = roll1, EnemyRoll = roll2, 
			AttackerRoll = roll1, DefenderRoll = roll2,
			PlayerHP = battle.Type == "PvE" and battle.MyStats.CurrentHP or battle.AttackerStats.CurrentHP,
			EnemyHP = battle.Type == "PvE" and battle.EnemyStats.CurrentHP or battle.DefenderStats.CurrentHP,
			AttackerHP = battle.Type == "PvP" and battle.AttackerStats.CurrentHP or nil,
			DefenderHP = battle.Type == "PvP" and battle.DefenderStats.CurrentHP or nil
		}
		if battle.Type == "PvP" then
			battle.AttackerRoll = nil
			battle.DefenderRoll = nil
			Events.BattleAttack:FireAllClients("Draw", 0, drawData)
		elseif battle.Type == "PvE" then
			Events.BattleAttack:FireAllClients("Draw", 0, drawData)
		end
		return -- Re-roll on draw
	end

	if battle.Type == "PvE" then
		local damage = 0
		if roll1 > roll2 then
			winner = "Player"
			damage = battle.MyStats.Attack or 5
			battle.EnemyStats.CurrentHP = math.max(0, battle.EnemyStats.CurrentHP - damage)
		else
			winner = "Enemy"
			damage = battle.EnemyStats.Attack or 5
			battle.MyStats.CurrentHP = math.max(0, battle.MyStats.CurrentHP - damage)
		end

		-- Fire result to ALL clients with HP update
		Events.BattleAttack:FireAllClients(winner, damage, {
			PlayerRoll = roll1, EnemyRoll = roll2,
			PlayerHP = battle.MyStats.CurrentHP, 
			EnemyHP = battle.EnemyStats.CurrentHP,
			PlayerMaxHP = battle.MyStats.MaxHP,
			EnemyMaxHP = battle.EnemyStats.MaxHP,
			AttackerRoll = roll1, DefenderRoll = roll2
		})

		-- Check if battle is over (someone's HP reached 0)
		if battle.EnemyStats.CurrentHP <= 0 then
			battle.Resolved = true
			task.spawn(function()
				task.wait(5) -- Wait for client dice animation + result display
				BattleSystem.endBattle(battle, "Win")
			end)
		elseif battle.MyStats.CurrentHP <= 0 then
			battle.Resolved = true
			task.spawn(function()
				task.wait(5) -- Wait for client dice animation + result display
				BattleSystem.endBattle(battle, "Lose")
			end)
		end
		-- If neither HP is 0, battle continues (wait for next roll)

	elseif battle.Type == "PvP" then
		local damage = 0
		if roll1 > roll2 then
			winner = "Attacker"
			damage = battle.AttackerStats.Attack or 5
			battle.DefenderStats.CurrentHP = math.max(0, battle.DefenderStats.CurrentHP - damage)
		else
			winner = "Defender"
			damage = battle.DefenderStats.Attack or 5
			battle.AttackerStats.CurrentHP = math.max(0, battle.AttackerStats.CurrentHP - damage)
		end

		local updateData = {
			Winner = winner, Damage = damage,
			AttackerRoll = roll1, DefenderRoll = roll2,
			AttackerHP = battle.AttackerStats.CurrentHP,
			DefenderHP = battle.DefenderStats.CurrentHP,
			AttackerMaxHP = battle.AttackerStats.MaxHP,
			DefenderMaxHP = battle.DefenderStats.MaxHP,
			PlayerRoll = roll1, EnemyRoll = roll2,
			PlayerHP = battle.AttackerStats.CurrentHP, 
			EnemyHP = battle.DefenderStats.CurrentHP
		}
		Events.BattleAttack:FireAllClients(winner, damage, updateData)

		-- Check if battle is over (someone's HP reached 0)
		if battle.DefenderStats.CurrentHP <= 0 then
			battle.Resolved = true
			task.spawn(function()
				task.wait(5) -- Wait for client dice animation + result display
				BattleSystem.endBattle(battle, "AttackerWin")
			end)
		elseif battle.AttackerStats.CurrentHP <= 0 then
			battle.Resolved = true
			task.spawn(function()
				task.wait(5) -- Wait for client dice animation + result display
				BattleSystem.endBattle(battle, "DefenderWin")
			end)
		end
		-- If neither HP is 0, battle continues (wait for next roll)
	end
end

-- ============================================================================
-- 🏁 END BATTLE + CLEANUP (WITH REWARDS/PENALTIES)
-- ============================================================================

function BattleSystem.endBattle(battle, result)
	print("🏁 Battle Ended: " .. result)

	local tilesFolder = workspace:FindFirstChild("Tiles")

	local winnerName = "Someone"
	local loserName = "Someone"
	local finalMsg = ""

	if battle.Type == "PvE" then
		winnerName = (result == "Win") and battle.Player.Name or battle.EnemyStats.Name
		loserName = (result == "Win") and battle.EnemyStats.Name or battle.Player.Name

		if result == "Win" then
			finalMsg = "🏆 " .. winnerName .. " defeated wild " .. loserName .. "!"

			-- Winner gets evolution or money
			local success = EvolutionSystem.tryEvolve(battle.Player)
			if not success then
				battle.Player.leaderstats.Money.Value += 3
				if Events.Notify then Events.Notify:FireClient(battle.Player, "⭐ No evolution available. +3 Coins!") end
			end
		else
			finalMsg = "💀 " .. winnerName .. " knocked out " .. loserName .. "!"

			-- Loser loses money and Pokemon dies
			battle.Player.leaderstats.Money.Value = math.max(0, battle.Player.leaderstats.Money.Value - 5)
			if battle.MyPokeObj then
				battle.MyPokeObj:SetAttribute("Status", "Dead")
				battle.MyPokeObj:SetAttribute("CurrentHP", 0)
			end
			if Events.Notify then Events.Notify:FireClient(battle.Player, "💀 Your " .. battle.MyStats.Name .. " fainted! -5 Coins") end
		end

		Events.BattleEnd:FireAllClients(finalMsg)
		BattleSystem.activeBattles[battle.Player.UserId] = nil

		if tilesFolder then
			PlayerManager.teleportToLastTile(battle.Player, tilesFolder)
		end
		TurnManager.nextTurn()

	elseif battle.Type == "PvP" then
		local winner, loser = nil, nil
		local winnerPokeObj, loserPokeObj = nil, nil
		local winnerPokeName, loserPokeName = "", ""

		if result == "AttackerWin" then
			winner = battle.Attacker
			loser = battle.Defender
			winnerName = battle.Attacker.Name
			loserName = battle.Defender.Name
			winnerPokeObj = battle.AttackerPokeObj
			loserPokeObj = battle.DefenderPokeObj
			winnerPokeName = battle.AttackerStats.Name
			loserPokeName = battle.DefenderStats.Name
		else
			winner = battle.Defender
			loser = battle.Attacker
			winnerName = battle.Defender.Name
			loserName = battle.Attacker.Name
			winnerPokeObj = battle.DefenderPokeObj
			loserPokeObj = battle.AttackerPokeObj
			winnerPokeName = battle.DefenderStats.Name
			loserPokeName = battle.AttackerStats.Name
		end

		finalMsg = "⚔️ PvP Result: " .. winnerName .. " defeated " .. loserName .. "!"


		-- Check for Team Rocket Passive (Steal Pokemon)
		local stolen = false
		if winner:GetAttribute("Job") == "Rocket" and loserPokeObj then
			local wInv = winner:FindFirstChild("PokemonInventory")
			if wInv and #wInv:GetChildren() < 6 then -- Check space
				stolen = true
				loserPokeObj.Parent = wInv
				
				-- FIX: Stolen Pokemon remains DEAD (0 HP)
				loserPokeObj:SetAttribute("CurrentHP", 0) 
				loserPokeObj:SetAttribute("Status", "Dead") -- Stolen as dead
				
				if Events.Notify then 
					Events.Notify:FireClient(winner, "🚀 Team Rocket Passive! Stole " .. loserPokeName .. "!") 
					Events.Notify:FireClient(loser, "🚀 Team Rocket stole your " .. loserPokeName .. "!") 
				end
				finalMsg = "🚀 " .. winnerName .. " (Team Rocket) stole " .. loserPokeName .. " from " .. loserName .. "!"
			else
				if Events.Notify then Events.Notify:FireClient(winner, "⚠️ Party full! Cannot steal Pokemon.") end
			end
		end

		-- FIX: Wining Pokemon gets Full HP Recovery
		if winnerPokeObj then
			local maxHP = winnerPokeObj:GetAttribute("MaxHP") or 10
			winnerPokeObj:SetAttribute("CurrentHP", maxHP)
		end

		-- Winner ALWAYS gets evolution check or money (Even if stole)
		local success = EvolutionSystem.tryEvolve(winner)
		if not success then
			winner.leaderstats.Money.Value += 3
			if Events.Notify then Events.Notify:FireClient(winner, "⭐ No evolution available. +3 Coins!") end
		end

		-- Loser loses money and Pokemon dies (Unless stolen)
		loser.leaderstats.Money.Value = math.max(0, loser.leaderstats.Money.Value - 5)
		
		if not stolen then
			if loserPokeObj then
				loserPokeObj:SetAttribute("Status", "Dead")
				loserPokeObj:SetAttribute("CurrentHP", 0)
				if Events.Notify then Events.Notify:FireClient(loser, "💀 Your " .. loserPokeName .. " fainted! -5 Coins") end
			end
		else
			-- If stolen, still lose money but Pokemon is gone (already handled)
			if Events.Notify then Events.Notify:FireClient(loser, "💸 You lost 5 Coins.") end
		end

		Events.BattleEnd:FireAllClients(finalMsg)

		BattleSystem.activeBattles[battle.Attacker.UserId] = nil
		BattleSystem.activeBattles[battle.Defender.UserId] = nil

		-- บันทึกว่าเพิ่ง Battle กับใคร (ต้องเดินก่อนถึงจะ Battle กันได้อีก)
		BattleSystem.lastBattleOpponent[battle.Attacker.UserId] = battle.Defender.UserId
		BattleSystem.lastBattleOpponent[battle.Defender.UserId] = battle.Attacker.UserId

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
			-- FIX: Validate player is actually in a battle before processing roll
			local battle = BattleSystem.activeBattles[player.UserId]
			if not battle then
				warn("⚠️ [BattleSystem] " .. player.Name .. " tried to roll but is not in a battle!")
				return
			end
			
			-- For PvP, also check they are either Attacker or Defender
			if battle.Type == "PvP" then
				if player ~= battle.Attacker and player ~= battle.Defender then
					warn("⚠️ [BattleSystem] " .. player.Name .. " tried to roll but is not part of this PvP battle!")
					return
				end
			end
			
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
				if inventory then chosenPoke = inventory:FindFirstChild(data.SelectedPokemonName) end
			end
			BattleSystem.startPvE(player, chosenPoke, data.Rarity)

		elseif data and data.Type == "PvP" then
			local target = data.Target
			if target then
				-- Check for recent battle
				if BattleSystem.lastBattleOpponent[player.UserId] == target.UserId then
					if Events.Notify then Events.Notify:FireClient(player, "❌ เพิ่ง Battle กับคนนี้! ต้องเดินก่อน") end
					-- FIX: Don't call resumeTurn (it triggers PvE on Red Tile)
					-- Instead, go directly to Roll Phase
					TurnManager.enterRollPhase(player, true) -- true = skip PvP check
					return
				end
				
				-- FIX: Check if defender has any alive Pokemon BEFORE sending challenge
				local defenderHasPokemon = BattleSystem.getFirstAlivePokemon(target) ~= nil
				if not defenderHasPokemon then
					print("⚠️ Defender " .. target.Name .. " has no alive Pokemon! Skipping PvP.")
					if Events.Notify then 
						Events.Notify:FireClient(player, "❌ " .. target.Name .. " ไม่มี Pokemon ที่มีชีวิต! ข้ามการต่อสู้")
					end
					-- Resume attacker's turn normally (process tile event)
					TurnManager.resumeTurn(player)
					return
				end
				
				-- 1. Store Pending Request
				BattleSystem.pendingBattles[target.UserId] = {
					Attacker = player,
					Defender = target,
					AttackerPokeName = data.SelectedPokemonName
				}
				
				-- 2. Send Challenge to Defender
				if Events.BattleTrigger then
					print("⚔️ Sending PvP Challenge to " .. target.Name)
					Events.BattleTrigger:FireClient(target, "Defend", { 
						Attacker = player,
						AttackerName = player.Name
					})
				end
				
				if Events.Notify then
					print("Notification: Waiting for " .. target.Name)
					Events.Notify:FireClient(player, "⏳ รอ " .. target.Name .. " เลือก Pokemon...")
				end
				
	-- FIX: Add timeout for pending PvP (30 seconds)
				-- If defender doesn't respond, auto-decline
				task.delay(30, function()
					local stillPending = BattleSystem.pendingBattles[target.UserId]
					if stillPending and stillPending.Attacker == player then
						print("⏰ PvP Timeout! " .. target.Name .. " did not respond. Auto-declining.")
						BattleSystem.pendingBattles[target.UserId] = nil
						if Events.Notify then
							Events.Notify:FireClient(player, "⏰ " .. target.Name .. " ไม่ตอบ! ข้ามการต่อสู้")
							Events.Notify:FireClient(target, "⏰ หมดเวลาตอบรับ Battle!")
						end
						TurnManager.resumeTurn(player)
					end
				end)
			end
		end
		
	elseif action == "DefendFight" then
		-- Defender Accepted
		local pending = BattleSystem.pendingBattles[player.UserId]
		if pending then
			local attacker = pending.Attacker
			local defender = player
			
			-- Get Pokemon Objects
			local attackerPoke = nil
			local defenderPoke = nil
			
			local aInv = attacker:FindFirstChild("PokemonInventory")
			if aInv then attackerPoke = aInv:FindFirstChild(pending.AttackerPokeName) end
			
			local dInv = defender:FindFirstChild("PokemonInventory")
			if dInv and data.SelectedPokemonName then 
				defenderPoke = dInv:FindFirstChild(data.SelectedPokemonName) 
			end
			
			-- Start actual PvP
			BattleSystem.startPvP(attacker, defender, attackerPoke, defenderPoke)
			
			-- Clear pending
			BattleSystem.pendingBattles[player.UserId] = nil
		else
			warn("⚠️ No pending battle found for " .. player.Name)
		end

	else
		-- Run / Decline
		if data and data.Type == "PvP" then
			-- Attacker ran/declined the PvP opportunity
			print("🏃 Declined PvP. Resuming Tile Event.")
			
			-- FIX: Mark that these players had encounter (prevents defender from challenging on their turn)
			if data.Target then
				BattleSystem.lastBattleOpponent[player.UserId] = data.Target.UserId
				BattleSystem.lastBattleOpponent[data.Target.UserId] = player.UserId
				print("📝 Set lastBattleOpponent: " .. player.Name .. " <-> " .. data.Target.Name)
			end
			
			TurnManager.resumeTurn(player)
		elseif action == "DefendRun" then
			-- Defender ran (Automatic Forfeit? Or just Decline Conflict?)
			local pending = BattleSystem.pendingBattles[player.UserId]
			if pending then
				if Events.Notify then Events.Notify:FireClient(pending.Attacker, "🏃 " .. player.Name .. " หนีการต่อสู้!") end
				
				-- FIX: Mark that these players had encounter (prevents re-challenge)
				BattleSystem.lastBattleOpponent[player.UserId] = pending.Attacker.UserId
				BattleSystem.lastBattleOpponent[pending.Attacker.UserId] = player.UserId
				print("📝 Set lastBattleOpponent: " .. player.Name .. " <-> " .. pending.Attacker.Name)
				
				-- FIX: Defender ran -> Attacker gets to process the tile event (e.g. Red Tile / Shop)
				-- Old code called TurnManager.nextTurn() which skipped the event!
				local attacker = pending.Attacker
				BattleSystem.pendingBattles[player.UserId] = nil
				TurnManager.resumeTurn(attacker)
			end
		else
			TurnManager.nextTurn()
		end
	end
end


return BattleSystem

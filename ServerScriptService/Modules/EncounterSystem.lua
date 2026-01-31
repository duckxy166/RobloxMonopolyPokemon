--[[
================================================================================
                      🐾 ENCOUNTER SYSTEM - Pokemon Battles
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Pokemon spawning
        - Catch/Run logic
        - Center stage management
================================================================================
--]]
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local pendingCatch = {} -- Key: userId, Value: {Name, Rarity, Stats}

local EncounterSystem = {}

-- Load PokemonDB
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))

-- State
local currentSpawnedPokemon = nil
local activeEncounterData = nil -- Store current encounter data
local centerStage = nil
local pokemonModels = nil

-- Dependencies
local Events = nil
local TimerSystem = nil
local TurnManager = nil
local PlayerManager = nil

-- Initialize with dependencies
function EncounterSystem.init(events, timerSystem, turnManager, playerManager)
	Events = events
	TimerSystem = timerSystem
	TurnManager = turnManager
	PlayerManager = playerManager

	-- Fix: Look inside "Stage" folder
	local stageFolder = Workspace:WaitForChild("Stage", 10)
	if stageFolder then
		centerStage = stageFolder:WaitForChild("CenterStage", 10)
	else
		warn("⚠️ CRITICAL: 'Stage' folder not found in Workspace!")
	end

	if not centerStage then
		warn("⚠️ CRITICAL: CenterStage not found in Workspace.Stage! EncounterSystem will not work.")
		return -- Exit init early to prevent further errors
	end
	centerStage.Transparency = 0 -- 👁️ Visible
	centerStage.CanCollide = true -- 🧱 Solid so things can stand on it
	centerStage.Anchored = true -- 🔒 Fixed in place
	pokemonModels = ServerStorage:WaitForChild("PokemonModels")
	pokemonModels = ServerStorage:WaitForChild("PokemonModels")

	print("✅ EncounterSystem initialized")
	print("📂 PokemonModels folder found. Contents:")
	for _, child in ipairs(pokemonModels:GetChildren()) do
		print("   - '" .. child.Name .. "' (" .. child.ClassName .. ")")
	end
	print("📂 PokemonModels folder found. Contents:")
	for _, child in ipairs(pokemonModels:GetChildren()) do
		print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
	end
end

-- Clear spawned pokemon
function EncounterSystem.clearCenterStage()
	if currentSpawnedPokemon then 
		currentSpawnedPokemon:Destroy()
		currentSpawnedPokemon = nil 
	end
	-- Do NOT hide center stage anymore
end

-- Force run and end encounter
function EncounterSystem.forceRunAndEnd(player)
	EncounterSystem.clearCenterStage()
	print("Timer: Force Run triggered for " .. player.Name) -- Moved print after clear
	TimerSystem.cancelTimer()
	Events.Run:FireAllClients(player)
	TurnManager.nextTurn()
end

-- Spawn pokemon encounter
function EncounterSystem.spawnPokemonEncounter(player, tileColorName)
	-- Use PokemonDB to get encounter based on Tile Color (or random if not provided)
	-- Fallback to "Default" if no color provided
	local encounter = PokemonDB.GetEncounterFromTile(tileColorName or "Default")

	-- Handle Case: No encounter found (None rolled)
	if not encounter then
		print("🍃 No encounter (Rolled None). Next turn.")
		if Events.Notify then
			Events.Notify:FireClient(player, "🍃 Quiet area... No Pokemon here.")
		end
		task.wait(1)
		TurnManager.nextTurn()
		return
	end

	local pokeName = encounter.Name
	local pokeData = encounter.Data
	print("🔍 Spawning: " .. pokeName .. " (Rarity: " .. (pokeData.Rarity or "?") .. ")")

	-- Helper to find model safely
	local function findModel(name)
		-- 1. Try exact match
		local m = pokemonModels:FindFirstChild(name)
		if m then return m end

		-- 2. Try trimming whitespace
		for _, child in ipairs(pokemonModels:GetChildren()) do
			if child.Name:match("^%s*" .. name .. "%s*$") then
				return child
			end
		end

		-- 3. Try case insensitive
		for _, child in ipairs(pokemonModels:GetChildren()) do
			if child.Name:lower() == name:lower() then
				return child
			end
		end

		return nil
	end

	local modelTemplate = findModel(pokeData.Model)

	if modelTemplate then
		local success, err = pcall(function()
			print("   ✅ Model found: '" .. modelTemplate.Name .. "'")
			local clonedModel = modelTemplate:Clone()
	
			-- Calculate nice spawn position on TOP of the stage
			-- Handle if CenterStage is a Model or Part
			local centerPos = centerStage.Position
			local centerSizeY = centerStage.Size.Y
			
			if centerStage:IsA("Model") then
				local cf, size = centerStage:GetBoundingBox()
				centerPos = cf.Position
				centerSizeY = size.Y
			end
	
			local stageTopY = centerPos.Y + (centerSizeY / 2)
			local spawnPos = CFrame.new(centerPos.X, stageTopY, centerPos.Z)
	
			clonedModel:PivotTo(spawnPos)
			clonedModel.Parent = Workspace
			currentSpawnedPokemon = clonedModel
	
			-- Adjust height based on HipHeight if Humanoid exists
			local pokeHumanoid = clonedModel:FindFirstChild("Humanoid")
			if pokeHumanoid and pokeHumanoid:IsA("Humanoid") then
				clonedModel:PivotTo(spawnPos + Vector3.new(0, pokeHumanoid.HipHeight + 1, 0))
				pokeHumanoid.AutomaticScalingEnabled = false
				
				-- Optional: Freeze animation or loaded animation?
				-- For now, just let it be
			else
				-- Fallback: Just bump it up a bit
				clonedModel:PivotTo(spawnPos + Vector3.new(0, 2, 0))
			end
	
			local mainPart = clonedModel.PrimaryPart or clonedModel:FindFirstChild("HumanoidRootPart") or clonedModel:FindFirstChildWhichIsA("BasePart", true)
	
			if mainPart then
				-- Weld parts to main part to anchor them together
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
	
			mainPart.Anchored = true -- Anchor to prevent falling
				mainPart.CanCollide = false -- Prevent physics collision with player
				mainPart.Massless = false
			end

			-- Add Name Label with Rarity Color
			local UIHelpers = require(game:GetService("ReplicatedStorage"):WaitForChild("UIHelpers"))
			UIHelpers.CreateNameLabel(clonedModel, pokeName, pokeData.Rarity)
		end)
		
		if not success then
			warn("❌ Error spawning Pokemon model: " .. tostring(err))
		end
	else
		warn("❌ CRITICAL: Model NOT found for: " .. pokeName .. " (Expected: " .. pokeData.Model .. ")")
	end

	-- Send encounter data to clients
	local encounterData = {
		Name = pokeName,
		Rarity = pokeData.Rarity,
		Type = pokeData.Type,
		HP = pokeData.HP,
		Attack = pokeData.Attack,
		Icon = pokeData.Icon,
		Image = pokeData.Image,
		CatchDifficulty = PokemonDB.GetCatchDifficulty(pokeName) or 3 -- Safety fallback
	}
	activeEncounterData = encounterData -- Update server state
	Events.Encounter:FireAllClients(player, encounterData)
	
	-- Broadcast to all players
	if Events.Notify then
		Events.Notify:FireAllClients("🐾 " .. player.Name .. " encountered a wild " .. pokeName .. " (" .. pokeData.Rarity .. ")!")
	end

	TurnManager.turnPhase = "Encounter"
	TimerSystem.startPhaseTimer(TimerSystem.ENCOUNTER_TIMEOUT, "Encounter", function()
		if TurnManager.turnPhase == "Encounter" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
			EncounterSystem.forceRunAndEnd(player)
		end
	end)
end

-- Constants
local MAX_PARTY_SIZE = 6

-- Handle catch attempt
function EncounterSystem.handleCatch(player)
	print("DEBUG: handleCatch called")
	TimerSystem.cancelTimer()

	local pokeData = activeEncounterData -- Use server state
	if not pokeData then
		warn("❌ CRITICAL: No active encounter data found for catch!")
		return
	end

	-- Check if party is full (6/6)
	local inventory = player:FindFirstChild("PokemonInventory")
	if inventory and #inventory:GetChildren() >= MAX_PARTY_SIZE then
		if Events.Notify then Events.Notify:FireClient(player, "❌ Party full! (6/6)") end
		-- Restart encounter timer so they don't get stuck
		TurnManager.turnPhase = "Encounter"
		TimerSystem.startPhaseTimer(TimerSystem.ENCOUNTER_TIMEOUT, "Encounter", function()
			if TurnManager.turnPhase == "Encounter" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				EncounterSystem.forceRunAndEnd(player)
			end
		end)
		return
	end

	local balls = player.leaderstats.Pokeballs
	balls.Value = balls.Value - 1

	local target = PokemonDB.GetCatchDifficulty(pokeData.Name)
	local roll = math.random(1, 6)
	local success = roll >= target

	if success then
		-- Store data in memory instead of parenting the item now
		pendingCatch[player.UserId] = {
			Name = pokeData.Name,
			Rarity = pokeData.Rarity,
			Stats = PokemonDB.GetPokemon(pokeData.Name)
		}
	end

	local isFinished = success
	Events.CatchPokemon:FireAllClients(player, success, roll, target, isFinished)
	
	-- Broadcast catch result
	if Events.Notify then
		if success then
			Events.Notify:FireAllClients("✨ " .. player.Name .. " caught " .. pokeData.Name .. "!")
		else
			Events.Notify:FireAllClients("❌ " .. player.Name .. " failed to catch " .. pokeData.Name .. "...")
		end
	end

	if isFinished then
		TurnManager.turnPhase = "CatchResult"
		-- We give the player 5 seconds to watch the animation before moving to next turn
		TimerSystem.startPhaseTimer(5, "Result", function()
			EncounterSystem.clearCenterStage()
			TurnManager.nextTurn()
		end)
	else
		-- Failed catch -> allow retry or run
		TurnManager.turnPhase = "Encounter"
		TimerSystem.startPhaseTimer(TimerSystem.ENCOUNTER_TIMEOUT, "Encounter", function()
			if TurnManager.turnPhase == "Encounter" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
				EncounterSystem.forceRunAndEnd(player)
			end
		end)
	end
end

-- Handle run
function EncounterSystem.handleRun(player)
	TimerSystem.cancelTimer()
	Events.Run:FireAllClients(player)
	task.wait(1)
	EncounterSystem.clearCenterStage()
	TurnManager.nextTurn()
end

local eventsConnected = false
local animProcessing = {}
-- Connect events
function EncounterSystem.connectEvents()
	if eventsConnected then
		warn("[EncounterSystem] connectEvents() called again -> skipping")
		return
	end
	eventsConnected = true

	Events.CatchPokemon.OnServerEvent:Connect(EncounterSystem.handleCatch)
	Events.Run.OnServerEvent:Connect(EncounterSystem.handleRun)

	local animDoneEvent = ReplicatedStorage:WaitForChild("CatchAnimationDoneEvent")
	animDoneEvent.OnServerEvent:Connect(function(player)
		local uid = player.UserId
		if animProcessing[uid] then return end
		animProcessing[uid] = true

		local data = pendingCatch[uid]
		pendingCatch[uid] = nil -- clear ASAP to prevent duplicates

		if data then
			local newPoke = Instance.new("StringValue")
			newPoke.Name = data.Name
			newPoke.Value = data.Rarity
			newPoke:SetAttribute("CurrentHP", data.Stats.HP)
			newPoke:SetAttribute("MaxHP", data.Stats.HP)
			newPoke:SetAttribute("Attack", data.Stats.Attack)
			newPoke:SetAttribute("Status", "Alive")
			newPoke.Parent = player.PokemonInventory
		end

		animProcessing[uid] = nil
	end)
end


return EncounterSystem

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
function EncounterSystem.spawnPokemonEncounter(player)
	-- Use PokemonDB for random encounter
	local encounter = PokemonDB.GetRandomEncounter()
	local pokeName = encounter.Name
	local pokeData = encounter.Data
	print("🔍 Attempting to spawn: " .. pokeName)

	-- Helper to find model safely
	local function findModel(name)
		-- 1. Try exact match
		local m = pokemonModels:FindFirstChild(name)
		if m then return m end

		-- 2. Try trimming whitespace
		for _, child in ipairs(pokemonModels:GetChildren()) do
			if child.Name:match("^%s*" .. name .. "%s*$") then
				print("   ⚠️ Found model with whitespace: '" .. child.Name .. "'")
				return child
			end
		end

		-- 3. Try case insensitive
		for _, child in ipairs(pokemonModels:GetChildren()) do
			if child.Name:lower() == name:lower() then
				print("   ⚠️ Found model with different case: '" .. child.Name .. "'")
				return child
			end
		end

		return nil
	end

	local modelTemplate = findModel(pokeData.Model)

	if modelTemplate then
		print("   ✅ Model found: '" .. modelTemplate.Name .. "'")
		local clonedModel = modelTemplate:Clone()

		-- Calculate nice spawn position on TOP of the stage
		local stageTopY = centerStage.Position.Y + (centerStage.Size.Y / 2)
		local spawnPos = CFrame.new(centerStage.Position.X, stageTopY, centerStage.Position.Z)

		clonedModel:PivotTo(spawnPos)
		clonedModel.Parent = Workspace
		currentSpawnedPokemon = clonedModel

		-- Adjust height based on HipHeight if Humanoid exists
		local pokeHumanoid = clonedModel:FindFirstChild("Humanoid")
		if pokeHumanoid then
			clonedModel:PivotTo(spawnPos + Vector3.new(0, pokeHumanoid.HipHeight + 1, 0))
		else
			-- Fallback: Just bump it up a bit
			clonedModel:PivotTo(spawnPos + Vector3.new(0, 2, 0))
		end

		local mainPart = clonedModel.PrimaryPart or clonedModel:FindFirstChild("HumanoidRootPart") or clonedModel:FindFirstChildWhichIsA("BasePart", true)
		local pokeHumanoid = clonedModel:FindFirstChild("Humanoid")

		if mainPart then
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
			mainPart.CanCollide = true
			mainPart.Massless = false

			-- No Gyro needed if anchored
			-- local gyro = Instance.new("BodyGyro")
			-- gyro.Name = "Stabilizer"
			-- gyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
			-- gyro.P = 5000
			-- gyro.CFrame = CFrame.new()
			-- gyro.Parent = mainPart

			if pokeHumanoid then
				pokeHumanoid.AutomaticScalingEnabled = false
				pokeHumanoid.HipHeight = 0
			end
		end
	else
		warn("❌ CRITICAL: Model NOT found for: " .. pokeName)
		warn("   Expected name: '" .. pokeData.Model .. "'")
		warn("   Available models in folder:")
		for _, child in ipairs(pokemonModels:GetChildren()) do
			warn("      - '" .. child.Name .. "'")
		end
	end

	-- Send encounter data to clients
	local encounterData = {
		Name = pokeName,
		Rarity = pokeData.Rarity,
		Type = pokeData.Type,
		HP = pokeData.HP,
		Attack = pokeData.Attack,
		Icon = pokeData.Icon,
		Image = pokeData.Image
	}
	Events.Encounter:FireAllClients(player, encounterData)

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
function EncounterSystem.handleCatch(player, pokeData)
	TimerSystem.cancelTimer()

	-- Check if party is full (6/6)
	local inventory = player:FindFirstChild("PokemonInventory")
	if inventory and #inventory:GetChildren() >= MAX_PARTY_SIZE then
		Events.Notify:FireClient(player, "❌ Party full! (6/6)")
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
	--local roll = math.random(1, 6)
	local roll = (6)
	local success = roll >= target

	if success then
		-- Store data in memory instead of parenting the item now
		pendingCatch[player.UserId] = {
			Name = pokeData.Name,
			Rarity = pokeData.Rarity,
			Stats = PokemonDB.GetPokemon(pokeData.Name)
		}
		player.leaderstats.Money.Value = player.leaderstats.Money.Value + 5
	end

	local isFinished = success or (balls.Value <= 0)
	Events.CatchPokemon:FireAllClients(player, success, roll, target, isFinished)

	if isFinished then
		TurnManager.turnPhase = "CatchResult"
		-- We give the player 5 seconds to watch the animation before moving to next turn
		TimerSystem.startPhaseTimer(5, "Result", function()
			EncounterSystem.clearCenterStage()
			TurnManager.nextTurn()
		end)
	else
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

-- Connect events
function EncounterSystem.connectEvents()
	Events.CatchPokemon.OnServerEvent:Connect(EncounterSystem.handleCatch)
	Events.Run.OnServerEvent:Connect(EncounterSystem.handleRun)
	local animDoneEvent = ReplicatedStorage:WaitForChild("CatchAnimationDoneEvent")
	animDoneEvent.OnServerEvent:Connect(function(player)
		local data = pendingCatch[player.UserId]
		if data then
			local newPoke = Instance.new("StringValue")
			newPoke.Name = data.Name
			newPoke.Value = data.Rarity
			newPoke:SetAttribute("CurrentHP", data.Stats.HP)
			newPoke:SetAttribute("MaxHP", data.Stats.HP)
			newPoke:SetAttribute("Attack", data.Stats.Attack)
			newPoke:SetAttribute("Status", "Alive")
			newPoke.Parent = player.PokemonInventory
			pendingCatch[player.UserId] = nil 
		end
	end)
end

return EncounterSystem

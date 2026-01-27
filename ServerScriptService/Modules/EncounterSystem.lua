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
local Workspace = game:GetService("Workspace")

local EncounterSystem = {}

-- Pokemon database
EncounterSystem.POKEMON_DB = {
	{ Name = "Bulbasaur", Rarity = "Common", ModelName = "Bulbasaur" }, 
	{ Name = "Charmander", Rarity = "Common", ModelName = "Charmander" },
	{ Name = "Squirtle", Rarity = "Common", ModelName = "Squirtle" },
	{ Name = "Pikachu", Rarity = "Rare", ModelName = "Pikachu" },
	{ Name = "Mewtwo", Rarity = "Legendary", ModelName = "Mewtwo" }
}

EncounterSystem.DIFFICULTY = { 
	["Common"] = 2, 
	["Rare"] = 4, 
	["Legendary"] = 6 
}

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
	
	centerStage = Workspace:WaitForChild("CenterStage")
	centerStage.Transparency = 1
	centerStage.CanCollide = false
	pokemonModels = ServerStorage:WaitForChild("PokemonModels")
	
	print("✅ EncounterSystem initialized")
end

-- Clear spawned pokemon
function EncounterSystem.clearCenterStage()
	if currentSpawnedPokemon then 
		currentSpawnedPokemon:Destroy()
		currentSpawnedPokemon = nil 
	end
	if centerStage then
		centerStage.Transparency = 1
	end
end

-- Force run and end encounter
function EncounterSystem.forceRunAndEnd(player)
	print("Timer: Force Run triggered for " .. player.Name)
	TimerSystem.cancelTimer()
	Events.Run:FireAllClients(player)
	EncounterSystem.clearCenterStage()
	TurnManager.nextTurn()
end

-- Spawn pokemon encounter
function EncounterSystem.spawnPokemonEncounter(player)
	local randomPoke = EncounterSystem.POKEMON_DB[math.random(1, #EncounterSystem.POKEMON_DB)]
	local modelTemplate = pokemonModels:FindFirstChild(randomPoke.ModelName)

	if modelTemplate then
		centerStage.Transparency = 0
		local clonedModel = modelTemplate:Clone()
		clonedModel:PivotTo(centerStage.CFrame + Vector3.new(0, 20, 0))
		clonedModel.Parent = Workspace
		currentSpawnedPokemon = clonedModel

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

			mainPart.Anchored = false
			mainPart.CanCollide = true
			mainPart.Massless = false

			local gyro = Instance.new("BodyGyro")
			gyro.Name = "Stabilizer"
			gyro.MaxTorque = Vector3.new(math.huge, 0, math.huge)
			gyro.P = 5000
			gyro.CFrame = CFrame.new()
			gyro.Parent = mainPart

			if pokeHumanoid then
				pokeHumanoid.AutomaticScalingEnabled = false
				pokeHumanoid.HipHeight = 0
			end
		end
	else
		warn("⚠️ Model not found: " .. randomPoke.ModelName)
	end

	Events.Encounter:FireAllClients(player, randomPoke)

	TurnManager.turnPhase = "Encounter"
	TimerSystem.startPhaseTimer(TimerSystem.ENCOUNTER_TIMEOUT, "Encounter", function()
		if TurnManager.turnPhase == "Encounter" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
			EncounterSystem.forceRunAndEnd(player)
		end
	end)
end

-- Handle catch attempt
function EncounterSystem.handleCatch(player, pokeData)
	TimerSystem.cancelTimer()
	
	local balls = player.leaderstats.Pokeballs
	balls.Value = balls.Value - 1

	local target = EncounterSystem.DIFFICULTY[pokeData.Rarity] or 2
	local roll = math.random(1, 6)
	local success = roll >= target

	if success then
		local newPoke = Instance.new("StringValue")
		newPoke.Name = pokeData.Name
		newPoke.Value = pokeData.Rarity
		newPoke.Parent = player.PokemonInventory
		player.leaderstats.Money.Value = player.leaderstats.Money.Value + 5
	end

	local isFinished = success or (balls.Value <= 0)
	Events.CatchPokemon:FireAllClients(player, success, roll, target, isFinished)

	if isFinished then
		TurnManager.turnPhase = "CatchResult"
		TimerSystem.startPhaseTimer(3, "Result", function()
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
end

return EncounterSystem

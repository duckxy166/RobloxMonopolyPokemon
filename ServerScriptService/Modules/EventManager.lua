--[[
================================================================================
                      📡 EVENT MANAGER - Remote Events Management
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Create and manage all RemoteEvents
        - Centralized event access
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventManager = {}

-- Cache for events
EventManager.Events = {}

-- Create or get existing RemoteEvent
function EventManager.getOrCreate(name)
	local ev = ReplicatedStorage:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = ReplicatedStorage
		print("🔹 Created RemoteEvent: " .. name)
	end
	EventManager.Events[name] = ev
	return ev
end

-- Create or get existing RemoteFunction
function EventManager.getOrCreateFunction(name)
	local func = ReplicatedStorage:FindFirstChild(name)
	if not func then
		func = Instance.new("RemoteFunction")
		func.Name = name
		func.Parent = ReplicatedStorage
		print("🔹 Created RemoteFunction: " .. name)
	end
	EventManager.Events[name] = func
	return func
end

-- Initialize all game events
function EventManager.init()
	local events = {
		DrawCard = EventManager.getOrCreate("DrawCardEvent"),
		PlayCard = EventManager.getOrCreate("PlayCardEvent"),
		RollDice = EventManager.getOrCreate("RollDiceEvent"),
		Encounter = EventManager.getOrCreate("EncounterEvent"),
		CatchPokemon = EventManager.getOrCreate("CatchPokemonEvent"),
		Run = EventManager.getOrCreate("RunEvent"),
		UpdateTurn = EventManager.getOrCreate("UpdateTurnEvent"),
		Notify = EventManager.getOrCreate("NotifyEvent"),
		Shop = EventManager.getOrCreate("ShopEvent"),
		UseItem = EventManager.getOrCreate("UseItemEvent"),
		BattleStart = EventManager.getOrCreate("BattleStartEvent"),
		BattleTrigger = EventManager.getOrCreate("BattleTriggerEvent"),
		BattleTriggerResponse = EventManager.getOrCreate("BattleTriggerResponseEvent"),
		BattleAttack = EventManager.getOrCreate("BattleAttackEvent"),
		BattleEnd = EventManager.getOrCreate("BattleEndEvent"),
		EndTurn = EventManager.getOrCreate("EndTurnEvent"),
		PhaseChange = EventManager.getOrCreate("PhaseChangeEvent"),
		TimerUpdate = EventManager.getOrCreate("TimerUpdateEvent"),
		DrawPhase = EventManager.getOrCreate("DrawPhaseEvent"),
		ResetCharacter = EventManager.getOrCreate("ResetCharacterEvent"),
		
		-- Sell System Events
		SellUI = EventManager.getOrCreate("SellUIEvent"),
		SellPokemon = EventManager.getOrCreate("SellPokemonEvent"),
		SellUIClose = EventManager.getOrCreate("SellUICloseEvent"),
		
		-- Starter Selection
		ShowStarterSelection = EventManager.getOrCreate("ShowStarterSelectionEvent"),
		SelectStarter = EventManager.getOrCreate("SelectStarterEvent"),
		
		-- Reaction / Counter
		RequestReaction = EventManager.getOrCreateFunction("RequestReactionFunction"),

		-- Evolution Events
		EvolutionRequest = EventManager.getOrCreate("EvolutionRequestEvent"),
		EvolutionSelect = EventManager.getOrCreate("EvolutionSelectEvent"),
		
		-- Card Management
		DiscardCard = EventManager.getOrCreate("DiscardCardEvent"),
		
		-- Game State
		GameStarted = EventManager.getOrCreate("GameStartedEvent"),
		
		-- Card Usage Notification (for UI display to all players)
		CardNotification = EventManager.getOrCreate("CardNotificationEvent"),
		
		-- Game End (for final results UI)
		GameEnd = EventManager.getOrCreate("GameEndEvent"),

		-- 4-Phase Turn System Events
		PhaseUpdate = EventManager.getOrCreate("PhaseUpdateEvent"),
		AdvancePhase = EventManager.getOrCreate("AdvancePhaseEvent"),
		UseAbility = EventManager.getOrCreate("UseAbilityEvent"),
		SwitchPhase = EventManager.getOrCreate("SwitchPhaseEvent"),

		-- Status Effects
		StatusChanged = EventManager.getOrCreate("StatusChangedEvent"),
		
		-- Laps
		LapUpdate = EventManager.getOrCreate("LapUpdateEvent"),
	}

	print("✅ EventManager initialized with " .. #events .. " events")
	return events
end

return EventManager

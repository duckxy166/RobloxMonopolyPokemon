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
		BattleAttack = EventManager.getOrCreate("BattleAttackEvent"),
		BattleEnd = EventManager.getOrCreate("BattleEndEvent"),
		EndTurn = EventManager.getOrCreate("EndTurnEvent"),
		PhaseChange = EventManager.getOrCreate("PhaseChangeEvent"),
		TimerUpdate = EventManager.getOrCreate("TimerUpdateEvent"),
		DrawPhase = EventManager.getOrCreate("DrawPhaseEvent"),
		ResetCharacter = EventManager.getOrCreate("ResetCharacterEvent"),
	}
	
	print("✅ EventManager initialized with " .. #events .. " events")
	return events
end

return EventManager

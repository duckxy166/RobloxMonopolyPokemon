--[[
================================================================================
                      🎮 GAME LOOP - Main Orchestrator
================================================================================
    📌 Location: ServerScriptService
    📌 Responsibilities:
        - Initialize all modules
        - Connect dependencies
        - Start game
    
    📌 Module Dependencies:
        - Modules/EventManager
        - Modules/TimerSystem
        - Modules/CardSystem
        - Modules/TurnManager
        - Modules/PlayerManager
        - Modules/ShopSystem
        - Modules/EncounterSystem
        
    📌 Version: 2.0 (Modular)
================================================================================
--]]

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULE REFERENCES
local Modules = ServerScriptService:WaitForChild("Modules")
local EventManager = require(Modules:WaitForChild("EventManager"))

-- STEP 1: Initialize Events (CRITICAL: Do this first so Clients don't timeout)
print("🔹 [GameLoop] Initializing Events...")
local Events = EventManager.init()

local TimerSystem = require(Modules:WaitForChild("TimerSystem"))
local CardSystem = require(Modules:WaitForChild("CardSystem"))
local PlayerManager = require(Modules:WaitForChild("PlayerManager"))
local TurnManager = require(Modules:WaitForChild("TurnManager"))
local ShopSystem = require(Modules:WaitForChild("ShopSystem"))
local EncounterSystem = require(Modules:WaitForChild("EncounterSystem"))
local BattleSystem = require(Modules:WaitForChild("BattleSystem"))
local SellSystem = require(Modules:WaitForChild("SellSystem"))
local EvolutionSystem = require(Modules:WaitForChild("EvolutionSystem"))

print("=====================================")
print("🎮 Pokemon Monopoly - Loading...")
print("=====================================")

-- STEP 2: Initialize Systems

-- STEP 2: Initialize Systems
TimerSystem.init(Events)
print("✅ TimerSystem Initialized")
CardSystem.init(Events)
print("✅ CardSystem Initialized")
TurnManager.init(Events, TimerSystem, CardSystem, PlayerManager)
print("✅ TurnManager Initialized")
ShopSystem.init(Events, TimerSystem, TurnManager, PlayerManager)
print("✅ ShopSystem Initialized")
EncounterSystem.init(Events, TimerSystem, TurnManager, PlayerManager)
print("✅ EncounterSystem Initialized")
BattleSystem.init(Events, TimerSystem, TurnManager, PlayerManager)
print("✅ BattleSystem Initialized")
SellSystem.init(Events, TimerSystem, TurnManager, PlayerManager)
print("✅ SellSystem Initialized")
EvolutionSystem.init(Events)
print("✅ EvolutionSystem Initialized")

-- STEP 3: Fix circular dependencies
TurnManager.setSystems(EncounterSystem, BattleSystem)
PlayerManager.init(CardSystem, TurnManager)

-- STEP 4: Connect all events
TurnManager.connectEvents()
ShopSystem.connectEvents()
EncounterSystem.connectEvents()
PlayerManager.connectEvents()
BattleSystem.connectEvents()
SellSystem.connectEvents()
CardSystem.connectEvents(Events, TurnManager, PlayerManager)

-- STEP 5: Handle Item Usage
Events.UseItem.OnServerEvent:Connect(function(player, itemName)
	-- Turn validation: Block items during other players' turns
	local currentPlayer = PlayerManager.playersInGame[TurnManager.currentTurnIndex]
	if currentPlayer and player ~= currentPlayer then
		if Events.Notify then
			Events.Notify:FireClient(player, "❌ Cannot use items during another player's turn!")
		end
		return
	end
	
	local itemsFolder = player:FindFirstChild("Items")
	local item = itemsFolder and itemsFolder:FindFirstChild(itemName)

	if item then
		if itemName == "Rare Candy" then
			player.leaderstats.Money.Value += 10
		elseif itemName == "Repel" then
			PlayerManager.playerRepelSteps[player.UserId] = 3
		elseif itemName == "Revive" then
			player.leaderstats.Pokeballs.Value += 2
		end

		item:Destroy()
		print("✅ " .. player.Name .. " used " .. itemName)
	end
end)

print("=====================================")
print("✅ Pokemon Monopoly - Ready!")
print("=====================================")

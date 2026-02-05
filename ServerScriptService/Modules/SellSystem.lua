--[[
================================================================================
                      💰 SELL SYSTEM - Pokemon Selling Logic
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Open sell UI when player reaches Tile 0
        - Calculate sell price based on rarity
        - Handle sell confirmation
        - Update player inventory and money
================================================================================
--]]

local SellSystem = {}

-- Constants (Updated with Divine tier)
SellSystem.SELL_PRICES = {
	["Common"] = 3,
	["Uncommon"] = 6,
	["Rare"] = 10,
	["Epic"] = 18,
	["Divine"] = 28,
	["Legend"] = 40
}

SellSystem.MIN_PARTY_SIZE = 1 -- Must keep at least 1 Pokemon

-- Dependencies
local Events = nil
local TimerSystem = nil
local TurnManager = nil
local PlayerManager = nil

-- State
local playerInSell = {} -- Track who is in sell menu

-- Initialize
function SellSystem.init(events, timerSystem, turnManager, playerManager)
	Events = events
	TimerSystem = timerSystem
	TurnManager = turnManager
	PlayerManager = playerManager
	print("✅ SellSystem initialized")
end

-- Get sellable Pokemon list
function SellSystem.getSellableList(player)
	local inventory = player:FindFirstChild("PokemonInventory")
	if not inventory then return {} end

	local pokemons = inventory:GetChildren()
	local sellable = {}

	-- Filter: Only alive Pokemon can be sold
	for _, poke in ipairs(pokemons) do
		local status = poke:GetAttribute("Status") or "Alive"

		if status == "Alive" then
			local rarity = poke.Value
			local price = SellSystem.SELL_PRICES[rarity] or 3

			table.insert(sellable, {
				Name = poke.Name,
				Rarity = rarity,
				Price = price,
				Status = status,
				HP = poke:GetAttribute("CurrentHP"),
				MaxHP = poke:GetAttribute("MaxHP")
			})
		end
	end

	return sellable
end

-- Open Sell UI
function SellSystem.openSellUI(player)
	if playerInSell[player.UserId] then return end -- Already open

	local sellList = SellSystem.getSellableList(player)

	if #sellList == 0 then
		if Events.Notify then
			Events.Notify:FireClient(player, "⚠️ No Pokemon to sell, but opening Sell Center.")
		end
		-- Continue to open UI so player can close it manually
	end

	playerInSell[player.UserId] = true
	Events.SellUI:FireClient(player, sellList)

	-- Start Timer (20 seconds to sell)
	TurnManager.turnPhase = "Sell"
	TimerSystem.startPhaseTimer(20, "Sell", function()
		if TurnManager.turnPhase == "Sell" and player == PlayerManager.playersInGame[TurnManager.currentTurnIndex] then
			print("⏱️ Sell timeout - closing UI")
			SellSystem.closeSellUI(player)
		end
	end)
end

-- Close Sell UI
function SellSystem.closeSellUI(player)
	playerInSell[player.UserId] = false
	Events.SellUI:FireClient(player, nil) -- Close signal
	TimerSystem.cancelTimer()
	
	-- CHECK LAPS for Finish Condition
	local laps = PlayerManager.playerLaps[player.UserId] or 1
	-- Note: Lap starts at 1. Completing 3 laps means starting Lap 4 (or Laps > 3).
	-- Let's say completing 3 full loops.
	if laps > 3 then
		PlayerManager.playerFinished[player.UserId] = true
		print("🏁 " .. player.Name .. " finished the game!")
		if Events.Notify then
			Events.Notify:FireClient(player, "🎉 You have finished the race! Waiting for others...")
		end
	end

	TurnManager.nextTurn()
end

-- Handle Sell Action
function SellSystem.handleSell(player, pokemonName)
	-- Verify turn
	if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then 
		warn("❌ Not player's turn!")
		return 
	end

	-- Find Pokemon
	local inventory = player:FindFirstChild("PokemonInventory")
	if not inventory then return end

	local targetPoke = inventory:FindFirstChild(pokemonName)
	if not targetPoke then 
		warn("❌ Pokemon not found:", pokemonName)
		return 
	end

	-- Check if Pokemon is alive (Dead Pokemon cannot be sold)
	local status = targetPoke:GetAttribute("Status") or "Alive"
	if status == "Dead" then
		if Events.Notify then
			Events.Notify:FireClient(player, "❌ Cannot sell dead Pokemon!")
		end
		return
	end
	
	-- Check minimum party size - must keep at least 1 Pokemon
	local totalPokemon = #inventory:GetChildren()
	if totalPokemon <= SellSystem.MIN_PARTY_SIZE then
		if Events.Notify then
			Events.Notify:FireClient(player, "❌ Cannot sell your last Pokemon! Must keep at least 1.")
		end
		return
	end

	-- Calculate price
	local rarity = targetPoke.Value
	local price = SellSystem.SELL_PRICES[rarity] or 3

	-- Add money
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")
	if money then
		money.Value = money.Value + price
	end

	-- Remove Pokemon
	targetPoke:Destroy()

	-- Notify
	if Events.Notify then
		Events.Notify:FireClient(player, "💰 Sold " .. pokemonName .. " for " .. price .. " coins!")
	end

	print("✅ " .. player.Name .. " sold " .. pokemonName .. " for " .. price)

	-- Check if any left to sell
	task.wait(0.5)
	local remaining = SellSystem.getSellableList(player)
	if #remaining == 0 then
		SellSystem.closeSellUI(player)
	else
		-- Update UI with new list
		Events.SellUI:FireClient(player, remaining)
	end
end

-- Connect Events
function SellSystem.connectEvents()
	if Events.SellPokemon then
		Events.SellPokemon.OnServerEvent:Connect(SellSystem.handleSell)
	end

	if Events.SellUIClose then
		Events.SellUIClose.OnServerEvent:Connect(SellSystem.closeSellUI)
	end
end

return SellSystem

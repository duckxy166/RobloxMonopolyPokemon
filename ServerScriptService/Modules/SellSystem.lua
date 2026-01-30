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

-- Constants
SellSystem.SELL_PRICES = {
	["None"] = 3,
	["Common"] = 5,
	["Uncommon"] = 8,
	["Rare"] = 12,
	["Legend"] = 20
}

SellSystem.MIN_PARTY_SIZE = 0 -- Can sell all Pokemon (no minimum required)

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
			Events.Notify:FireClient(player, "❌ No alive Pokemon to sell!")
		end
		-- Skip sell phase
		TurnManager.nextTurn()
		return
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

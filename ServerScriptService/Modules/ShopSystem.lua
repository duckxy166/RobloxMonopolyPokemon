--[[
================================================================================
                      🛒 SHOP SYSTEM - Shop Logic
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Shop event handling
        - Buy/Exit actions
        - Price and purchase logic
================================================================================
--]]

local ShopSystem = {}

-- Constants
ShopSystem.BALL_PRICE = 1

-- State
local shopDebounce = {}

-- Dependencies
local Events = nil
local TimerSystem = nil
local TurnManager = nil
local PlayerManager = nil

-- Initialize with dependencies
function ShopSystem.init(events, timerSystem, turnManager, playerManager)
	Events = events
	TimerSystem = timerSystem
	TurnManager = turnManager
	PlayerManager = playerManager
	print("✅ ShopSystem initialized")
end

-- Handle shop action
function ShopSystem.handleShopAction(player, action)
	-- Verify it's player's turn
	if player ~= PlayerManager.playersInGame[TurnManager.currentTurnIndex] then return end

	-- Check if player is in shop
	if not PlayerManager.playerInShop[player.UserId] then
		warn("❌ Player not in shop but tried:", player.Name, action)
		return
	end

	-- Debounce
	local now = os.clock()
	if shopDebounce[player.UserId] and (now - shopDebounce[player.UserId]) < 0.12 then
		return
	end
	shopDebounce[player.UserId] = now

	print("Shop Server: Action = " .. tostring(action))

	if action == "Buy" then
		local leaderstats = player:FindFirstChild("leaderstats")
		local money = leaderstats and leaderstats:FindFirstChild("Money")
		local balls = leaderstats and leaderstats:FindFirstChild("Pokeballs")

		if money and balls then
			if money.Value >= ShopSystem.BALL_PRICE then
				money.Value -= ShopSystem.BALL_PRICE
				balls.Value += 1

				-- 🔊 tell ONLY this player to play purchase sound
				if Events.Shop then
					Events.Shop:FireClient(player, "Purchased")
				end

				if Events.Notify then
					Events.Notify:FireClient(player, ("Bought Pokeball +1 (Money left: %d)"):format(money.Value))
				end
			else
				if Events.Notify then
					Events.Notify:FireClient(player, "Not enough money!")
				end
			end
		end
		return -- Don't end turn, allow multiple purchases
	end

	if action == "Exit" then
		print("Player finished shop action: Exit -> End Turn")
		TimerSystem.cancelTimer()
		PlayerManager.playerInShop[player.UserId] = false
		task.wait(0.5)
		TurnManager.nextTurn()
	end
end

-- Connect shop event
function ShopSystem.connectEvents()
	if Events.Shop then
		Events.Shop.OnServerEvent:Connect(ShopSystem.handleShopAction)
	end
end

return ShopSystem

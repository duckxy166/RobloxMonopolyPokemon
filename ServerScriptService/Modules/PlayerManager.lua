--[[
================================================================================
                      👤 PLAYER MANAGER - Player Setup & Stats
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Player initialization on join
        - Leaderstats, inventory, hand, status folders
        - Player position tracking
        - Player removal handling
================================================================================
--]]
local Players = game:GetService("Players")

local PlayerManager = {}

-- State
PlayerManager.playersInGame = {}
PlayerManager.playerPositions = {}
PlayerManager.playerRepelSteps = {}
PlayerManager.playerSlots = {}
PlayerManager.playerInShop = {}

-- Token offset positions
local TOKEN_OFFSETS = {
	[1] = Vector3.new(-2, 0, -2),  -- Front-Left
	[2] = Vector3.new(2, 0, -2),   -- Front-Right
	[3] = Vector3.new(-2, 0, 2),   -- Back-Left
	[4] = Vector3.new(2, 0, 2),    -- Back-Right
}

-- Dependencies
local CardSystem = nil
local TurnManager = nil

-- Initialize with dependencies
function PlayerManager.init(cardSystem, turnManager)
	CardSystem = cardSystem
	TurnManager = turnManager
	print("✅ PlayerManager initialized")
end

-- Get player tile position with offset
function PlayerManager.getPlayerTilePosition(player, tile)
	local slot = PlayerManager.playerSlots[player.UserId] or 1
	local offset = TOKEN_OFFSETS[slot] or Vector3.new(0, 0, 0)
	return tile.Position + offset + Vector3.new(0, 3, 0)
end

-- Get player leaderstats
function PlayerManager.getLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Money"), ls and ls:FindFirstChild("Pokeballs")
end

-- Teleport player to their last tile
function PlayerManager.teleportToLastTile(player, tilesFolder)
	local tileIndex = PlayerManager.playerPositions[player.UserId] or 0
	local tile = tilesFolder:FindFirstChild(tostring(tileIndex))
	local char = player.Character
	if tile and char and char.PrimaryPart then
		char:SetPrimaryPartCFrame(CFrame.new(PlayerManager.getPlayerTilePosition(player, tile)))
		print("Reset: Teleported " .. player.Name .. " to tile " .. tileIndex)
	end
end

-- Setup new player
function PlayerManager.onPlayerAdded(player)
	print("✅ [Server] onPlayerAdded:", player.Name)
	for _, p in ipairs(PlayerManager.playersInGame) do 
		if p == player then return end 
	end
	table.insert(PlayerManager.playersInGame, player)
	print("👥 [Server] Player added to game! Total players:", #PlayerManager.playersInGame)
	
	PlayerManager.playerPositions[player.UserId] = 0 
	PlayerManager.playerRepelSteps[player.UserId] = 0 
	PlayerManager.playerSlots[player.UserId] = #PlayerManager.playersInGame

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 10
	money.Parent = leaderstats
	
	local balls = Instance.new("IntValue")
	balls.Name = "Pokeballs"
	balls.Value = 5
	balls.Parent = leaderstats
	
	-- Create inventory
	local inventory = Instance.new("Folder")
	inventory.Name = "PokemonInventory"
	inventory.Parent = player

	-- Create items folder
	local items = Instance.new("Folder")
	items.Name = "Items"
	items.Parent = player

	-- Create hand folder
	local hand = Instance.new("Folder")
	hand.Name = "Hand"
	hand.Parent = player

	-- Draw starter cards (2 cards at game start)
	if CardSystem then
		for i = 1, 2 do
			CardSystem.drawOneCard(player)
		end
	end

	-- Create status folder
	local status = Instance.new("Folder")
	status.Name = "Status"
	status.Parent = player
	
	local shield = Instance.new("BoolValue")
	shield.Name = "Shield"
	shield.Value = false
	shield.Parent = status
	
	local sleep = Instance.new("IntValue")
	sleep.Name = "SleepTurns"
	sleep.Value = 0
	sleep.Parent = status

	-- Add starter pokemon
	local starterPoke = Instance.new("StringValue")
	starterPoke.Name = "Bulbasaur"
	starterPoke.Value = "Common"
	starterPoke.Parent = inventory

	-- Start game if first player
	if #PlayerManager.playersInGame == 1 and TurnManager then
		print("🚀 [Server] First player joined! Starting game in 3 seconds...")
		task.wait(3)
		TurnManager.currentTurnIndex = 0
		TurnManager.nextTurn()
	end
end

-- Handle player leaving
function PlayerManager.onPlayerRemoving(player)
	for i, p in ipairs(PlayerManager.playersInGame) do
		if p == player then
			table.remove(PlayerManager.playersInGame, i)
			if TurnManager then
				if i == TurnManager.currentTurnIndex then 
					TurnManager.currentTurnIndex = TurnManager.currentTurnIndex - 1
					TurnManager.nextTurn()
				elseif i < TurnManager.currentTurnIndex then 
					TurnManager.currentTurnIndex = TurnManager.currentTurnIndex - 1 
				end
			end
			break
		end
	end
end

-- Connect to player events
function PlayerManager.connectEvents()
	Players.PlayerAdded:Connect(PlayerManager.onPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerManager.onPlayerRemoving)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do 
		print("🔍 [Server] Found existing player:", player.Name)
		PlayerManager.onPlayerAdded(player) 
	end
end

return PlayerManager

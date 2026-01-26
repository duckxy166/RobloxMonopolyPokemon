local Players = game:GetService("Players")

-- Player Initialization and Data Setup
local START_MONEY = 10     -- Starting currency
local START_BALLS = 5      -- Starting balls
local START_POKEMON = "Bulbasaur" -- Starter Pokemon name

Players.PlayerAdded:Connect(function(player)
	-- 1. Create Leaderstats (Currency/Balls)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money" -- Internal name for currency
	money.Value = START_MONEY
	money.Parent = leaderstats

	local balls = Instance.new("IntValue")
	balls.Name = "Pokeballs"
	balls.Value = START_BALLS
	balls.Parent = leaderstats

	-- 2. Create Pokemon Inventory (Hidden from player list)
	-- Separate from Leaderstats to keep the UI clean
	local inventory = Instance.new("Folder")
	inventory.Name = "PokemonInventory"
	inventory.Parent = player

	-- Give 1 starter pokemon
	local starterPoke = Instance.new("StringValue")
	starterPoke.Name = START_POKEMON
	starterPoke.Value = "Common" -- Set rarity as value
	starterPoke.Parent = inventory

	print("✅ Player initialization for " .. player.Name .. " complete!")
end)
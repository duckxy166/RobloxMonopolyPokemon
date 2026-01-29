local ReplicatedStorage = game:GetService("ReplicatedStorage")

local catchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local catchAnimDoneEvent = ReplicatedStorage:WaitForChild("CatchAnimationDoneEvent")

-- store caught pokemon until client says "animation finished"
local pendingCatch = {} -- [userId] = pokemonName

local DIFFICULTY = { Common = 2, Rare = 4, Legendary = 6 }

catchEvent.OnServerEvent:Connect(function(player, pokeData)
	-- pokeData should include Name + Rarity (from your EncounterEvent)
	if typeof(pokeData) ~= "table" then return end
	local pokemonName = pokeData.Name
	local rarity = pokeData.Rarity or "Common"
	if not pokemonName then return end

	-- Roll dice on server
	local diceRoll = math.random(1, 6)
	local need = DIFFICULTY[rarity] or 2
	local success = (diceRoll >= need)

	-- If success, DON'T add to inventory yet. Wait for client "done" signal.
	if success then
		pendingCatch[player.UserId] = pokemonName
	end

	-- Tell everyone result (your client already listens to this)
	-- Params match your client: (activePlayer, success, diceRoll, target, isFinished)
	local isFinished = success -- if you want retries on fail, keep false when fail
	catchEvent:FireAllClients(player, success, diceRoll, pokemonName, isFinished)
end)

-- Client calls this when catch phase UI finishes
catchAnimDoneEvent.OnServerEvent:Connect(function(player)
	local pokemonName = pendingCatch[player.UserId]
	if not pokemonName then return end

	-- Add to player's inventory NOW (this is what updates your left HUD later)
	local inv = player:FindFirstChild("PokemonInventory")
	if not inv then
		inv = Instance.new("Folder")
		inv.Name = "PokemonInventory"
		inv.Parent = player
	end

	local v = Instance.new("StringValue")
	v.Name = pokemonName
	v.Parent = inv

	pendingCatch[player.UserId] = nil
end)

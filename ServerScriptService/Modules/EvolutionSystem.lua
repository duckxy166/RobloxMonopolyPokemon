--[[
================================================================================
                      🧬 EVOLUTION SYSTEM - Pokemon Evolution Logic
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Handle evolution checks
        - Perform evolution (Update Inventory)
================================================================================
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))

local EvolutionSystem = {}
local Events = nil

function EvolutionSystem.init(events)
	Events = events
	
	-- Listen for Client Selection
	if Events.EvolutionSelect then
		Events.EvolutionSelect.OnServerEvent:Connect(function(player, pokeObj)
			EvolutionSystem.handleEvolutionSelection(player, pokeObj)
		end)
	end
	
	print("✅ EvolutionSystem initialized")
end

-- Start Evolution Process (Opens UI)
-- Returns true if UI opened (candidates exist), false if no candidates (fallback)
function EvolutionSystem.tryEvolve(player) -- Keeping name tryEvolve for compatibility with existing calls
	local inventory = player:FindFirstChild("PokemonInventory")
	if not inventory then return false end
	
	-- 1. Find Candidates
	local candidates = {}
	for _, pokeVal in ipairs(inventory:GetChildren()) do
		local name = pokeVal.Name
		local data = PokemonDB.GetPokemon(name)
		
		if data and data.EvolveTo then
			local nextStageData = PokemonDB.GetPokemon(data.EvolveTo)
			if nextStageData then
				table.insert(candidates, pokeVal) -- Object Reference
			end
		end
	end
	
	-- 2. Check candidates
	if #candidates == 0 then
		return false
	end
	
	-- 3. Request Client Selection
	print("🧬 Requesting Evolution Selection for " .. player.Name)
	if Events and Events.EvolutionRequest then
		-- Serialize for Client? Or just array of instances. Instances work locally.
		Events.EvolutionRequest:FireClient(player, candidates)
	end
	
	return true
end

-- Handle Client Selection
function EvolutionSystem.handleEvolutionSelection(player, targetPokeVal)
	if not targetPokeVal or targetPokeVal.Parent ~= player:FindFirstChild("PokemonInventory") then
		warn("⚠️ Invalid Evolution Selection from " .. player.Name)
		return
	end

	local currentName = targetPokeVal.Name
	local dbData = PokemonDB.GetPokemon(currentName)
	
	if not dbData or not dbData.EvolveTo then
		warn("⚠️ Pokemon cannot evolve: " .. tostring(currentName))
		return
	end
	
	local nextName = dbData.EvolveTo
	local nextData = PokemonDB.GetPokemon(nextName)
	
	if not nextData then return end

	print("🧬 Evolving " .. currentName .. " -> " .. nextName .. " for " .. player.Name)

	-- Update Inventory (Swap Objects to trigger UI updates)
	local inventory = player:FindFirstChild("PokemonInventory")
	local newPoke = Instance.new("StringValue")
	newPoke.Name = nextName
	newPoke.Value = nextData.Rarity
	newPoke:SetAttribute("MaxHP", nextData.HP)
	newPoke:SetAttribute("Attack", nextData.Attack)
	newPoke:SetAttribute("CurrentHP", nextData.HP) -- Heal on Evolve
	newPoke:SetAttribute("Status", "Alive")
	newPoke.Parent = inventory
	
	targetPokeVal:Destroy()
	
	-- Notify
	if Events and Events.Notify then
		Events.Notify:FireClient(player, "🧬 Evolution! " .. currentName .. " ➡ " .. nextName .. "!")
	end
end

return EvolutionSystem

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Collision Group Name
local groupName = "PlayersGroup"

-- Register Group (may error if already exists)
pcall(function()
	PhysicsService:RegisterCollisionGroup(groupName)
end)

-- Set Group Non-Collidable with itself (False = no collision)
PhysicsService:CollisionGroupSetCollidable(groupName, groupName, false)

-- Assign all character parts to group
local function setCollisionGroup(character)
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

-- Apply to each player on join
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for essential parts
		character:WaitForChild("HumanoidRootPart")
		character:WaitForChild("Head")
		character:WaitForChild("Humanoid")

		setCollisionGroup(character)

		-- Handle future descendants (e.g. hat, accessories)
		character.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				descendant.CollisionGroup = groupName
			end
		end)
	end)
end)
--[[
================================================================================
                      ✨ EVOLUTION UI CONTROLLER
================================================================================
    📌 Location: StarterGui/EvolutionUI/LocalScript
    📌 Responsibilities:
        - Show list of Pokemon eligible for evolution
        - Allow player to select one to evolve
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EvolutionGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.5, 0, 0.6, 0)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
container.BorderSizePixel = 0
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", container).Color = Color3.fromRGB(100, 255, 255)
Instance.new("UIStroke", container).Thickness = 2

local title = Instance.new("TextLabel")
title.Text = "EVOLUTION TIME! Choose one:"
title.Size = UDim2.new(1, 0, 0.15, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 24
title.Parent = container

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.9, 0, 0.7, 0)
scroll.Position = UDim2.new(0.05, 0, 0.2, 0)
scroll.BackgroundTransparency = 1
scroll.Parent = container
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)

-- Events
-- Events
local Events = {
	EvolutionRequest = ReplicatedStorage:WaitForChild("EvolutionRequestEvent"),
	EvolutionSelect = ReplicatedStorage:WaitForChild("EvolutionSelectEvent")
}

local function createSlot(pokeObj)
	local pokeName = pokeObj.Name
	local rarity = pokeObj.Value
	local hp = pokeObj:GetAttribute("MaxHP") or "?"
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 60)
	btn.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
	btn.Text = "" -- Rich layout inside
	btn.Parent = scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	-- Info Labels
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Text = pokeName
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn
	
	local detailLabel = Instance.new("TextLabel")
	detailLabel.Text = rarity .. " | HP: " .. hp
	detailLabel.Font = Enum.Font.Gotham
	detailLabel.TextSize = 14
	detailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
	detailLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.Parent = btn

	local selectLabel = Instance.new("TextLabel")
	selectLabel.Text = "SELECT"
	selectLabel.Font = Enum.Font.GothamBlack
	selectLabel.TextSize = 14
	selectLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	selectLabel.BackgroundTransparency = 1
	selectLabel.Size = UDim2.new(0.3, 0, 1, 0)
	selectLabel.Position = UDim2.new(0.7, 0, 0, 0)
	selectLabel.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		-- Fire evolution selection
		print("Selected to evolve: " .. pokeName)
		Events.EvolutionSelect:FireServer(pokeObj)
		screenGui.Enabled = false
	end)
end

-- Listen for Evolution Trigger
if Events.EvolutionRequest then
	Events.EvolutionRequest.OnClientEvent:Connect(function(candidates)
		print("✨ Evolution UI triggered! Candidates: " .. #candidates)
		
		-- Clear old
		for _, v in pairs(scroll:GetChildren()) do
			if v:IsA("GuiObject") then v:Destroy() end
		end
		
		-- Populate
		for _, pokeObj in ipairs(candidates) do
			createSlot(pokeObj)
		end
		
		screenGui.Enabled = true
	end)
end

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
title.Text = "✨ EVOLUTION TIME! Choose one:"
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
local NotifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent") -- Using Notify for now, need specific event
-- Ideally, we need "OpenEvolutionEvent"

local function createSlot(pokeName, pokeIdObj)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	btn.Text = pokeName
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Parent = scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	btn.MouseButton1Click:Connect(function()
		-- Fire evolution selection
		-- Events.EvolutionSelect:FireServer(pokeIdObj) -- Placeholder
		screenGui.Enabled = false
	end)
end

-- Listen for Evolution Trigger (Need to implement in Server Event)
-- For now, placeholder structure

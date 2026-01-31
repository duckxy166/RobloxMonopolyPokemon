--[[
================================================================================
                      🏆 GAME RESULTS UI
================================================================================
    📌 Location: StarterGui/GameResultsUI/LocalScript
    📌 Responsibilities:
        - Display final game results when all players finish
        - Show leaderboard with rankings
================================================================================
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Events
local gameEndEvent = ReplicatedStorage:WaitForChild("GameEndEvent", 10)

-- Rank Colors
local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 215, 0),   -- Gold
	[2] = Color3.fromRGB(192, 192, 192), -- Silver
	[3] = Color3.fromRGB(205, 127, 50),  -- Bronze
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameResultsUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 200
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Background Overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.Parent = screenGui

-- Main Container
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 500, 0, 400)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 20)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 200, 50)
stroke.Thickness = 4
stroke.Parent = container

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🏆 GAME OVER 🏆"
title.Font = Enum.Font.FredokaOne
title.TextSize = 36
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Parent = container

-- Results List Container
local listContainer = Instance.new("ScrollingFrame")
listContainer.Name = "ResultsList"
listContainer.Size = UDim2.new(1, -40, 1, -120)
listContainer.Position = UDim2.new(0, 20, 0, 70)
listContainer.BackgroundTransparency = 1
listContainer.ScrollBarThickness = 6
listContainer.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = listContainer

-- Winner Banner
local winnerBanner = Instance.new("TextLabel")
winnerBanner.Name = "WinnerBanner"
winnerBanner.Size = UDim2.new(1, -40, 0, 40)
winnerBanner.Position = UDim2.new(0, 20, 1, -50)
winnerBanner.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
winnerBanner.Text = "🎉 WINNER: ???"
winnerBanner.Font = Enum.Font.FredokaOne
winnerBanner.TextSize = 24
winnerBanner.TextColor3 = Color3.fromRGB(0, 0, 0)
winnerBanner.Parent = container
Instance.new("UICorner", winnerBanner).CornerRadius = UDim.new(0, 10)

-- Create Result Row
local function createResultRow(data, index)
	local row = Instance.new("Frame")
	row.Name = "Row_" .. index
	row.Size = UDim2.new(1, 0, 0, 60)
	row.BackgroundColor3 = RANK_COLORS[data.Rank] or Color3.fromRGB(60, 60, 80)
	row.BackgroundTransparency = data.Rank <= 3 and 0.3 or 0.5
	row.Parent = listContainer
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	
	-- Rank
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 50, 1, 0)
	rankLabel.Position = UDim2.new(0, 5, 0, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "#" .. tostring(data.Rank)
	rankLabel.Font = Enum.Font.FredokaOne
	rankLabel.TextSize = 28
	rankLabel.TextColor3 = RANK_COLORS[data.Rank] or Color3.fromRGB(255, 255, 255)
	rankLabel.Parent = row
	
	-- Player Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 60, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 20
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row
	
	-- Highlight if this is the local player
	if data.UserId == player.UserId then
		nameLabel.Text = "⭐ " .. data.Name .. " (YOU)"
		nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	end
	
	-- Money
	local moneyLabel = Instance.new("TextLabel")
	moneyLabel.Size = UDim2.new(0.25, 0, 1, 0)
	moneyLabel.Position = UDim2.new(0.45, 0, 0, 0)
	moneyLabel.BackgroundTransparency = 1
	moneyLabel.Text = "💰 $" .. tostring(data.Money)
	moneyLabel.Font = Enum.Font.GothamBold
	moneyLabel.TextSize = 18
	moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	moneyLabel.Parent = row
	
	-- Pokemon Count
	local pokeLabel = Instance.new("TextLabel")
	pokeLabel.Size = UDim2.new(0.25, 0, 1, 0)
	pokeLabel.Position = UDim2.new(0.72, 0, 0, 0)
	pokeLabel.BackgroundTransparency = 1
	pokeLabel.Text = "🔴 " .. tostring(data.PokemonCount) .. " Pokemon"
	pokeLabel.Font = Enum.Font.GothamBold
	pokeLabel.TextSize = 14
	pokeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	pokeLabel.Parent = row
	
	return row
end

-- Show Results
local function showResults(results)
	-- Clear old rows
	for _, child in ipairs(listContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Create rows for each player
	for i, data in ipairs(results) do
		createResultRow(data, i)
	end
	
	-- Update canvas size
	listContainer.CanvasSize = UDim2.new(0, 0, 0, #results * 70)
	
	-- Set winner banner
	if results[1] then
		winnerBanner.Text = "🎉 WINNER: " .. results[1].Name .. " 🎉"
	end
	
	-- Animate in
	container.Position = UDim2.new(0.5, 0, -0.5, 0)
	screenGui.Enabled = true
	
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()
end

-- Listen for Game End
if gameEndEvent then
	gameEndEvent.OnClientEvent:Connect(function(results)
		showResults(results)
	end)
end

print("✅ GameResultsUI loaded")

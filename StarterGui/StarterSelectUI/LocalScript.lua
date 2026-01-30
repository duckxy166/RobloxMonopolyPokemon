--[[
================================================================================
                      🎮 STARTER SELECTION UI
================================================================================
    📌 Location: StarterGui/StarterSelectUI/LocalScript
    📌 Responsibilities:
        - Show starter pokemon list
        - Send selection to server
        - Wait info
================================================================================
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarterSelectGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true -- Full screen
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
bg.Parent = screenGui

local title = Instance.new("TextLabel")
title.Text = "CHOOSE YOUR PARTNER"
title.Size = UDim2.new(1, 0, 0.1, 0)
title.Position = UDim2.new(0, 0, 0.05, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.FredokaOne
title.TextSize = 40
title.Parent = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.9, 0, 0.7, 0)
scroll.Position = UDim2.new(0.05, 0, 0.2, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Parent = bg

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.18, 0, 0.3, 0)
grid.CellPadding = UDim2.new(0.02, 0, 0.02, 0)
grid.Parent = scroll

-- Waiting Screen
local waitFrame = Instance.new("Frame")
waitFrame.Size = UDim2.new(1, 0, 1, 0)
waitFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
waitFrame.Visible = false
waitFrame.Parent = screenGui

local waitText = Instance.new("TextLabel")
waitText.Text = "Waiting for other players..."
waitText.Size = UDim2.new(1, 0, 0.2, 0)
waitText.Position = UDim2.new(0, 0, 0.4, 0)
waitText.BackgroundTransparency = 1
waitText.TextColor3 = Color3.fromRGB(255, 255, 255)
waitText.Font = Enum.Font.GothamBold
waitText.TextSize = 30
waitText.Parent = waitFrame

-- Events
local Events = {
	ShowStarterSelection = ReplicatedStorage:WaitForChild("ShowStarterSelectionEvent"),
	SelectStarter = ReplicatedStorage:WaitForChild("SelectStarterEvent"),
	UpdateTurn = ReplicatedStorage:WaitForChild("UpdateTurnEvent")
}

local function createCard(name)
	local data = PokemonDB.GetPokemon(name)
	if not data then return end
	
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.Image = "" -- No button image
	btn.AutoButtonColor = true
	btn.Parent = scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
	
	-- Pokemon Image/Icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = data.Icon or data.Image or "rbxassetid://0"
	icon.Size = UDim2.new(0.8, 0, 0.55, 0)
	icon.Position = UDim2.new(0.1, 0, 0.05, 0)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = btn
	
	-- Name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text = name
	nameLbl.Size = UDim2.new(1, 0, 0.15, 0)
	nameLbl.Position = UDim2.new(0, 0, 0.65, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 16
	nameLbl.TextScaled = true
	nameLbl.Parent = btn
	
	-- Stats
	local statsLbl = Instance.new("TextLabel")
	statsLbl.Text = "HP: " .. data.HP .. " | ATK: " .. data.Attack
	statsLbl.Size = UDim2.new(1, 0, 0.15, 0)
	statsLbl.Position = UDim2.new(0, 0, 0.8, 0)
	statsLbl.BackgroundTransparency = 1
	statsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsLbl.Font = Enum.Font.Gotham
	statsLbl.TextSize = 14
	statsLbl.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		Events.SelectStarter:FireServer(name)
		bg.Visible = false
		waitFrame.Visible = true
	end)
end

-- Initialize List
task.spawn(function()
	-- Wait for DB to be potentially updated? Already required.
	for _, name in ipairs(PokemonDB.Starters or {}) do
		createCard(name)
	end
end)

-- Listen for trigger
Events.ShowStarterSelection.OnClientEvent:Connect(function()
	print("✨ Opening Starter Selection")
	screenGui.Enabled = true
	bg.Visible = true
	waitFrame.Visible = false
end)

-- Hide UI when game starts
Events.UpdateTurn.OnClientEvent:Connect(function()
	if screenGui.Enabled then
		print("🚀 Game Started! Hiding Selection UI.")
		screenGui.Enabled = false
	end
end)

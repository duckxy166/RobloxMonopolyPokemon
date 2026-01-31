--[[
================================================================================
                      🎯 CARD TARGET SELECTION UI
================================================================================
    📌 Location: StarterGui/CardTargetUI/LocalScript
    📌 Responsibilities:
        - Show list of other players
        - Select target for cards (Twisted Spoon, Robbery, etc.)
        - Fire PlayCardEvent with target
================================================================================
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playCardEvent = ReplicatedStorage:WaitForChild("PlayCardEvent")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CardTargetGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true -- Full screen cover
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.5
bg.Parent = screenGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 400, 0, 300)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
container.Parent = bg
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", container).Color = Color3.fromRGB(255, 100, 100)
Instance.new("UIStroke", container).Thickness = 2

local title = Instance.new("TextLabel")
title.Text = "SELECT TARGET"
title.Size = UDim2.new(1, 0, 0.2, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 24
title.Parent = container

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(0.9, 0, 0.6, 0)
scroll.Position = UDim2.new(0.05, 0, 0.25, 0)
scroll.BackgroundTransparency = 1
scroll.Parent = container
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Text = "CANCEL"
closeBtn.Size = UDim2.new(0.4, 0, 0.1, 0)
closeBtn.Position = UDim2.new(0.3, 0, 0.88, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = container
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

-- State
local currentCardName = nil

local function createPlayerButton(p)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	btn.Text = p.Name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.Parent = scroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		if currentCardName then
			print("🎯 Target Selected: " .. p.Name .. " for " .. currentCardName)
			playCardEvent:FireServer(currentCardName, p)
			screenGui.Enabled = false
		end
	end)
end

-- Listen for Open Request
local function connectBindable()
	local bindable = ReplicatedStorage:WaitForChild("Client_OpenCardTarget", 5)
	if not bindable then
		-- Create if missing (Should be created by HandUI usually)
		bindable = Instance.new("BindableEvent")
		bindable.Name = "Client_OpenCardTarget"
		bindable.Parent = ReplicatedStorage
	end

	bindable.Event:Connect(function(cardName)
		print("🎯 Opening Target UI for: " .. cardName)
		currentCardName = cardName

		-- Refresh List
		for _, child in pairs(scroll:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end

		local found = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				createPlayerButton(p)
				found = true
			end
		end

		if not found then
			-- No players? Auto-cancel or show empty
			local lbl = Instance.new("TextLabel")
			lbl.Text = "No other players found!"
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			lbl.Parent = scroll
		end

		screenGui.Enabled = true
	end)
end

task.spawn(connectBindable)

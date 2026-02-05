--[[
================================================================================
               📍 PHASE UI CONTROLLER - Modern Design
================================================================================
    📌 4-PHASE TURN STRUCTURE:
        Draw -> Item -> Ability -> Roll
================================================================================
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================
local PhaseUpdateEvent = ReplicatedStorage:WaitForChild("PhaseUpdateEvent", 5)
local UpdateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")
local AdvancePhaseEvent = ReplicatedStorage:WaitForChild("AdvancePhaseEvent", 5)
local RollDiceEvent = ReplicatedStorage:WaitForChild("RollDiceEvent")

-- ============================================================================
-- CONSTANTS & CONFIG
-- ============================================================================
local PHASES = {"Draw", "Item", "Ability", "Roll"}
local PHASE_ICONS = {
	Draw = "🃏",
	Item = "🎒",
	Ability = "⚡",
	Roll = "🎲"
}

-- Modern Palette
local COLORS = {
	Backdrop = Color3.fromRGB(20, 20, 30),
	ActivePhase = Color3.fromRGB(255, 255, 255),
	InactivePhase = Color3.fromRGB(100, 100, 120),
	
	-- Action Button Colors
	Green = Color3.fromRGB(46, 204, 113),
	Blue = Color3.fromRGB(52, 152, 219),
	Red = Color3.fromRGB(231, 76, 60),
	Orange = Color3.fromRGB(243, 156, 18),
	Disabled = Color3.fromRGB(60, 60, 70)
}

-- ============================================================================
-- UI CONSTRUCTION
-- ============================================================================
local screenGui = script.Parent
if not screenGui:IsA("ScreenGui") then
	-- In case the script is not direct child of ScreenGui (legacy support)
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PhaseUI_Modern"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

local mainContainer
local phaseNodes = {}
local actionButton, actionLabel, actionIcon
local messageLabel

local function createModernUI()
	if screenGui:FindFirstChild("MainContainer") then
		screenGui.MainContainer:Destroy()
	end

	-- 1. Main Container (Center of screen, near the circle)
	mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, 380, 0, 140)
	mainContainer.Position = UDim2.new(0.5, 0, 0.1, 0) -- Center of screen (near the circle)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundColor3 = COLORS.Backdrop
	mainContainer.BackgroundTransparency = 0.1
	mainContainer.BorderSizePixel = 0
	mainContainer.Parent = screenGui

	-- Glass blur effect (optional)
	-- local uiBlur = Instance.new("BlurEffect", game.Lighting) -- Not good for specific frame
	-- Using ImageLabel with blur texture is common, but basic frame is fine for now

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 20)
	uiCorner.Parent = mainContainer

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(80, 80, 100)
	uiStroke.Thickness = 2
	uiStroke.Parent = mainContainer
	
	-- 2. Phase Tracker (Top Half)
	local trackerFrame = Instance.new("Frame")
	trackerFrame.Name = "TrackerFrame"
	trackerFrame.Size = UDim2.new(1, -20, 0, 50)
	trackerFrame.Position = UDim2.new(0, 10, 0, 10)
	trackerFrame.BackgroundTransparency = 1
	trackerFrame.Parent = mainContainer

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5) -- Dynamic padding based on width
	layout.Parent = trackerFrame

	-- Create Nodes for each phase
	for i, pName in ipairs(PHASES) do
		local node = Instance.new("Frame")
		node.Name = pName
		node.LayoutOrder = i
		node.Size = UDim2.new(0.23, 0, 1, 0)
		node.BackgroundTransparency = 1
		node.Parent = trackerFrame

		local bg = Instance.new("Frame")
		bg.Name = "BG"
		bg.Size = UDim2.new(1, 0, 0, 4) -- Thin line bottom
		bg.Position = UDim2.new(0, 0, 1, -2)
		bg.BackgroundColor3 = COLORS.InactivePhase
		bg.BorderSizePixel = 0
		bg.Parent = node
		
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 0, 30)
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = PHASE_ICONS[pName]
		icon.TextSize = 20
		icon.TextColor3 = COLORS.InactivePhase
		icon.Parent = node

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 0, 15)
		label.Position = UDim2.new(0, 0, 0, 30)
		label.BackgroundTransparency = 1
		label.Text = pName:upper()
		label.Font = Enum.Font.GothamBold
		label.TextSize = 10
		label.TextColor3 = COLORS.InactivePhase
		label.Parent = node

		phaseNodes[pName] = {
			Frame = node,
			BG = bg,
			Icon = icon,
			Label = label
		}
	end

	-- 3. Dynamic Action Button (Bottom Right)
	actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.Size = UDim2.new(0, 120, 0, 50)
	actionButton.Position = UDim2.new(1, -20, 1, -20)
	actionButton.AnchorPoint = Vector2.new(1, 1)
	actionButton.BackgroundColor3 = COLORS.Green
	actionButton.AutoButtonColor = false -- We do custom animations
	actionButton.Text = ""
	actionButton.Parent = mainContainer

	Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 12)
	
	-- Shadow/3D effect
	local btnShadow = Instance.new("Frame")
	btnShadow.Name = "Shadow"
	btnShadow.Size = UDim2.new(1, 0, 1, 4)
	btnShadow.Position = UDim2.new(0, 0, 0, 4)
	btnShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btnShadow.BackgroundTransparency = 0.5
	btnShadow.ZIndex = -1
	btnShadow.Parent = actionButton
	Instance.new("UICorner", btnShadow).CornerRadius = UDim.new(0, 12)

	-- Button Content
	actionLabel = Instance.new("TextLabel")
	actionLabel.Name = "Text"
	actionLabel.Size = UDim2.new(1, -30, 1, 0)
	actionLabel.Position = UDim2.new(0, 0, 0, 0)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Text = "NEXT"
	actionLabel.Font = Enum.Font.FredokaOne
	actionLabel.TextSize = 18
	actionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionLabel.Parent = actionButton
	
	actionIcon = Instance.new("TextLabel")
	actionIcon.Name = "Icon"
	actionIcon.Size = UDim2.new(0, 30, 1, 0)
	actionIcon.Position = UDim2.new(1, -30, 0, 0)
	actionIcon.BackgroundTransparency = 1
	actionIcon.Text = "➡️"
	actionIcon.TextSize = 18
	actionIcon.Parent = actionButton

	-- 4. Message Area (Bottom Left)
	messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, -160, 0, 50) -- Fills remaining space left of button
	messageLabel.Position = UDim2.new(0, 20, 1, -20)
	messageLabel.AnchorPoint = Vector2.new(0, 1)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = "Waiting for players..."
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	messageLabel.Font = Enum.Font.GothamMedium
	messageLabel.TextSize = 14
	messageLabel.TextWrapped = true
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.Parent = mainContainer
end

createModernUI()

-- ============================================================================
-- STATE
-- ============================================================================
local currentPhase = "Waiting"
local isMyTurn = false
local isRolling = false

-- ============================================================================
-- UI UPDATER
-- ============================================================================

local function updatePhaseTracker(activePhaseStr)
	for phaseName, nodes in pairs(phaseNodes) do
		local isActive = (phaseName == activePhaseStr)
		
		local targetColor = isActive and COLORS.ActivePhase or COLORS.InactivePhase
		local targetScale = isActive and 1.2 or 0.95
		local targetAlpha = isActive and 0 or 0.5
		
		TweenService:Create(nodes.Icon, TweenInfo.new(0.3), {
			TextColor3 = targetColor, 
			TextTransparency = targetAlpha
		}):Play()
		
		TweenService:Create(nodes.Label, TweenInfo.new(0.3), {
			TextColor3 = targetColor, 
			TextTransparency = targetAlpha
		}):Play()
		
		TweenService:Create(nodes.BG, TweenInfo.new(0.3), {
			BackgroundColor3 = isActive and COLORS.ActivePhase or COLORS.InactivePhase
		}):Play()
	end
end

local function updateActionButton(mode)
	local btnColor = COLORS.Disabled
	local text = "WAITING"
	local icon = "⏳"
	local active = false
	
	if mode == "Next" then
		btnColor = COLORS.Blue
		text = "NEXT PHASE"
		icon = "➡️"
		active = true
	elseif mode == "Skip" then
		btnColor = COLORS.Orange
		text = "SKIP THIS"
		icon = "⏭️"
		active = true
	elseif mode == "Roll" then
		btnColor = COLORS.Green
		text = "ROLL DICE"
		icon = "🎲"
		active = true
	elseif mode == "Rolling" then
		btnColor = COLORS.Backdrop
		text = "ROLLING..."
		icon = "🌀"
		active = false
	elseif mode == "Wait" then
		btnColor = COLORS.Disabled
		text = "WAITING"
		icon = "⏳"
		active = false
	end
	
	actionButton.Active = active
	actionLabel.Text = text
	actionIcon.Text = icon
	
	TweenService:Create(actionButton, TweenInfo.new(0.3), {
		BackgroundColor3 = btnColor
	}):Play()
	
	-- Pulsing effect for Roll
	if mode == "Roll" then
		task.spawn(function()
			while currentPhase == "Roll" and isMyTurn and not isRolling do
				TweenService:Create(actionButton, TweenInfo.new(0.5), {Size = UDim2.new(0, 125, 0, 55)}):Play()
				task.wait(0.5)
				TweenService:Create(actionButton, TweenInfo.new(0.5), {Size = UDim2.new(0, 120, 0, 50)}):Play()
				task.wait(0.5)
			end
			-- Reset size
			actionButton.Size = UDim2.new(0, 120, 0, 50) 
		end)
	end
end

local function updateUI(phase, message)
	currentPhase = phase
	
	-- 1. Tracker Update
	updatePhaseTracker(phase)
	
	-- 2. Message Update
	if message then
		messageLabel.Text = message
		-- Flash text
		messageLabel.TextTransparency = 1
		TweenService:Create(messageLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
	end
	
	-- 3. Action Button Logic
	if isMyTurn then
		if phase == "Draw" then
			-- Valid Phase but no action button needed usually, unless confirming draw
			updateActionButton("Wait") 
			
		elseif phase == "Item" then
			updateActionButton("Next")
			
		elseif phase == "Ability" then
			updateActionButton("Next") -- Or Skip if we detect no ability (server handles that mostly)
			
		elseif phase == "Roll" then
			updateActionButton("Roll")
			isRolling = false
		else
			updateActionButton("Wait")
		end
	else
		updateActionButton("Wait")
	end
end

-- ============================================================================
-- EVENT LISTENERS
-- ============================================================================

-- Phase Update
if PhaseUpdateEvent then
	PhaseUpdateEvent.OnClientEvent:Connect(function(phase, message)
		print("📍 [ModernUI] Phase:", phase)
		isMyTurn = true
		updateUI(phase, message)
	end)
end

-- Turn Update
UpdateTurnEvent.OnClientEvent:Connect(function(currentPlayerName, phase)
	print("🔄 [ModernUI] Turn:", currentPlayerName)
	if currentPlayerName == player.Name then
		isMyTurn = true
		updateUI(phase or "Roll", "It's your turn! " .. (phase and "" or "Roll to start."))
	else
		isMyTurn = false
		currentPhase = "Waiting"
		updatePhaseTracker("None") -- Gray out all
		updateActionButton("Wait")
		messageLabel.Text = "⏳ Waiting for " .. currentPlayerName .. "..."
	end
end)

-- Button Interaction
actionButton.MouseButton1Click:Connect(function()
	if not isMyTurn then return end
	if not actionButton.Active then return end
	
	-- Pulse Animation on Click
	local originalSize = UDim2.new(0, 120, 0, 50)
	local shrinkSize = UDim2.new(0, 110, 0, 45)
	
	local t1 = TweenService:Create(actionButton, TweenInfo.new(0.05), {Size = shrinkSize})
	t1:Play()
	t1.Completed:Wait()
	TweenService:Create(actionButton, TweenInfo.new(0.05), {Size = originalSize}):Play()
	
	-- Logic
	if currentPhase == "Item" or currentPhase == "Ability" then
		print("➡️ Advancing Phase")
		actionButton.Active = false -- Debounce
		if AdvancePhaseEvent then AdvancePhaseEvent:FireServer() end
		
	elseif currentPhase == "Roll" then
		if isRolling then return end
		print("🎲 Rolling...")
		isRolling = true
		updateActionButton("Rolling")
		if RollDiceEvent then RollDiceEvent:FireServer() end
	end
end)

-- Hover Effects
actionButton.MouseEnter:Connect(function()
	if actionButton.Active then
		TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
	end
end)
actionButton.MouseLeave:Connect(function()
	if actionButton.Active then
		TweenService:Create(actionButton, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
	end
end)

print("✅ PhaseUI Modern Controller Loaded")

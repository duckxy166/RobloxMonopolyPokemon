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
local UseAbilityEvent = ReplicatedStorage:WaitForChild("UseAbilityEvent", 5)
local SwitchPhaseEvent = ReplicatedStorage:WaitForChild("SwitchPhaseEvent", 5)

-- Reference to Hand UI for hiding during Ability Phase
local HandUI = nil
task.spawn(function()
	task.wait(1)
	local handScreen = playerGui:FindFirstChild("HandUI")
	if handScreen then
		HandUI = handScreen
	end
end)

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
	Purple = Color3.fromRGB(156, 89, 182),
	Disabled = Color3.fromRGB(60, 60, 70)
}

-- Job Ability Data
local ABILITY_DATA = {
	Gambler = {name = "Lucky Guess", icon = "🎰", inputType = "number", description = "ทายเลข 1-6 ถูกได้ 6 เหรียญ"},
	Esper = {name = "Mind Move", icon = "🔮", inputType = "choice", choices = {1, 2}, description = "กำหนดช่องเดิน 1-2 ช่อง"},
	Shaman = {name = "Curse", icon = "🌿", inputType = "target", description = "สาปให้ทิ้งการ์ด + เสียเงิน"},
	Biker = {name = "Turbo Boost", icon = "🏍️", inputType = "instant", description = "เดินเพิ่ม +2 ช่อง"},
	Trainer = {name = "Extra Hand", icon = "🎒", inputType = "passive", description = "ถือการ์ดได้ 6 ใบ (Passive)"},
	Fisherman = {name = "Steal Card", icon = "🎣", inputType = "target", description = "แย่งการ์ดจากผู้เล่นอื่น"},
	Rocket = {name = "Steal Pokemon", icon = "💠", inputType = "passive", description = "ขโมย Pokemon เมื่อชนะ PvP (Passive)"},
	NurseJoy = {name = "Revive", icon = "💖", inputType = "instant", description = "ฟื้นฟู Pokemon ที่ตาย"}
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
local abilityButton, abilityPopup
local phaseTabFrame, itemTabBtn, abilityTabBtn

local function createModernUI()
	if screenGui:FindFirstChild("MainContainer") then
		screenGui.MainContainer:Destroy()
	end

	-- 1. Main Container (Center of screen, near the circle)
	mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, 380, 0, 180)
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
	messageLabel.Size = UDim2.new(1, -300, 0, 50) -- Adjusted for ability button
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

	-- 5. Ability Button (Only visible in Ability Phase)
	abilityButton = Instance.new("TextButton")
	abilityButton.Name = "AbilityButton"
	abilityButton.Size = UDim2.new(0, 120, 0, 50)
	abilityButton.Position = UDim2.new(1, -150, 1, -20)
	abilityButton.AnchorPoint = Vector2.new(1, 1)
	abilityButton.BackgroundColor3 = COLORS.Purple
	abilityButton.AutoButtonColor = false
	abilityButton.Text = ""
	abilityButton.Visible = false
	abilityButton.Parent = mainContainer

	Instance.new("UICorner", abilityButton).CornerRadius = UDim.new(0, 12)

	local abilityLabel = Instance.new("TextLabel")
	abilityLabel.Name = "Text"
	abilityLabel.Size = UDim2.new(1, 0, 1, 0)
	abilityLabel.BackgroundTransparency = 1
	abilityLabel.Text = "⚡ ABILITY"
	abilityLabel.Font = Enum.Font.FredokaOne
	abilityLabel.TextSize = 16
	abilityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	abilityLabel.Parent = abilityButton

	-- 6. Ability Popup Frame
	abilityPopup = Instance.new("Frame")
	abilityPopup.Name = "AbilityPopup"
	abilityPopup.Size = UDim2.new(0, 320, 0, 220)
	abilityPopup.Position = UDim2.new(0.5, 0, 0.5, 0)
	abilityPopup.AnchorPoint = Vector2.new(0.5, 0.5)
	abilityPopup.BackgroundColor3 = COLORS.Backdrop
	abilityPopup.BackgroundTransparency = 0.1
	abilityPopup.Visible = false
	abilityPopup.ZIndex = 10
	abilityPopup.Parent = screenGui

	Instance.new("UICorner", abilityPopup).CornerRadius = UDim.new(0, 16)
	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = COLORS.Purple
	popupStroke.Thickness = 2
	popupStroke.Parent = abilityPopup

	local popupTitle = Instance.new("TextLabel")
	popupTitle.Name = "Title"
	popupTitle.Size = UDim2.new(1, 0, 0, 40)
	popupTitle.Position = UDim2.new(0, 0, 0, 0)
	popupTitle.BackgroundTransparency = 1
	popupTitle.Text = "⚡ USE ABILITY"
	popupTitle.Font = Enum.Font.FredokaOne
	popupTitle.TextSize = 20
	popupTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	popupTitle.Parent = abilityPopup

	local popupContent = Instance.new("Frame")
	popupContent.Name = "Content"
	popupContent.Size = UDim2.new(1, -20, 1, -100)
	popupContent.Position = UDim2.new(0.5, 0, 0, 45)
	popupContent.AnchorPoint = Vector2.new(0.5, 0)
	popupContent.BackgroundTransparency = 1
	popupContent.Parent = abilityPopup

	local popupClose = Instance.new("TextButton")
	popupClose.Name = "CloseBtn"
	popupClose.Size = UDim2.new(0, 100, 0, 35)
	popupClose.Position = UDim2.new(0.5, 0, 1, -10)
	popupClose.AnchorPoint = Vector2.new(0.5, 1)
	popupClose.BackgroundColor3 = COLORS.Red
	popupClose.Text = "✕ CLOSE"
	popupClose.Font = Enum.Font.FredokaOne
	popupClose.TextSize = 14
	popupClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	popupClose.Parent = abilityPopup
	Instance.new("UICorner", popupClose).CornerRadius = UDim.new(0, 8)

	popupClose.MouseButton1Click:Connect(function()
		abilityPopup.Visible = false
	end)

	-- 7. Phase Tab Frame (Switch between Item/Ability)
	phaseTabFrame = Instance.new("Frame")
	phaseTabFrame.Name = "PhaseTabFrame"
	phaseTabFrame.Size = UDim2.new(0, 240, 0, 36)
	phaseTabFrame.Position = UDim2.new(0.5, 0, 1, -75)
	phaseTabFrame.AnchorPoint = Vector2.new(0.5, 1)
	phaseTabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	phaseTabFrame.BackgroundTransparency = 0.3
	phaseTabFrame.Visible = false
	phaseTabFrame.Parent = mainContainer
	Instance.new("UICorner", phaseTabFrame).CornerRadius = UDim.new(0, 10)

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = phaseTabFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = phaseTabFrame

	itemTabBtn = Instance.new("TextButton")
	itemTabBtn.Name = "ItemTab"
	itemTabBtn.LayoutOrder = 1 -- Item Left
	itemTabBtn.Size = UDim2.new(0, 100, 0, 28)
	itemTabBtn.BackgroundColor3 = COLORS.Blue
	itemTabBtn.Text = "🎒 ITEM"
	itemTabBtn.Font = Enum.Font.FredokaOne
	itemTabBtn.TextSize = 14
	itemTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemTabBtn.Parent = phaseTabFrame
	Instance.new("UICorner", itemTabBtn).CornerRadius = UDim.new(0, 6)

	abilityTabBtn = Instance.new("TextButton")
	abilityTabBtn.Name = "AbilityTab"
	abilityTabBtn.LayoutOrder = 2 -- Ability Right
	abilityTabBtn.Size = UDim2.new(0, 100, 0, 28)
	abilityTabBtn.BackgroundColor3 = COLORS.Purple
	abilityTabBtn.Text = "⚡ ABILITY"
	abilityTabBtn.Font = Enum.Font.FredokaOne
	abilityTabBtn.TextSize = 14
	abilityTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	abilityTabBtn.Parent = phaseTabFrame
	Instance.new("UICorner", abilityTabBtn).CornerRadius = UDim.new(0, 6)

	itemTabBtn.MouseButton1Click:Connect(function()
		if currentPhase == "Item" then return end
		if SwitchPhaseEvent then SwitchPhaseEvent:FireServer("Item") end
	end)

	abilityTabBtn.MouseButton1Click:Connect(function()
		if currentPhase == "Ability" then return end
		if SwitchPhaseEvent then SwitchPhaseEvent:FireServer("Ability") end
	end)
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
	
	-- 3. Ability Button Visibility + Hand UI + Phase Tabs
	if phase == "Ability" and isMyTurn then
		local playerJob = player:GetAttribute("Job")
		local abilityData = ABILITY_DATA[playerJob]
		if abilityData and abilityData.inputType ~= "passive" then
			abilityButton.Visible = true
			-- Hide Hand during Ability phase (active abilities)
			if HandUI then HandUI.Enabled = false end
		else
			abilityButton.Visible = false
			-- Show passive message and hide Hand
			if abilityData then
				messageLabel.Text = abilityData.icon .. " Passive: " .. abilityData.description
			end
			if HandUI then HandUI.Enabled = false end
		end
		-- Update tab button styles
		itemTabBtn.BackgroundColor3 = COLORS.Disabled
		abilityTabBtn.BackgroundColor3 = COLORS.Purple
	else
		abilityButton.Visible = false
		abilityPopup.Visible = false
		-- Show Hand in Item phase
		if phase == "Item" and isMyTurn then
			if HandUI then HandUI.Enabled = true end
			itemTabBtn.BackgroundColor3 = COLORS.Blue
			abilityTabBtn.BackgroundColor3 = COLORS.Disabled
		end
	end
	
	-- 4. Phase Tab Visibility (only in Item or Ability phase)
	if isMyTurn and (phase == "Item" or phase == "Ability") then
		phaseTabFrame.Visible = true
	else
		phaseTabFrame.Visible = false
		-- Restore Hand UI when not in Item/Ability
		if phase ~= "Ability" and HandUI then
			HandUI.Enabled = true
		end
	end
	
	-- 4. Action Button Logic
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

-- Show Ability Popup based on player job
local function showAbilityPopup()
	local playerJob = player:GetAttribute("Job")
	local abilityData = ABILITY_DATA[playerJob]
	if not abilityData then return end
	
	-- Clear previous content
	local content = abilityPopup:FindFirstChild("Content")
	for _, child in ipairs(content:GetChildren()) do
		child:Destroy()
	end
	
	-- Update title
	local titleLabel = abilityPopup:FindFirstChild("Title")
	if titleLabel then
		titleLabel.Text = abilityData.icon .. " " .. abilityData.name
	end
	
	-- Create content based on input type
	if abilityData.inputType == "number" then
		-- Gambler: 6 number buttons
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 25)
		desc.BackgroundTransparency = 1
		desc.Text = abilityData.description
		desc.TextColor3 = Color3.fromRGB(200, 200, 220)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 12
		desc.Parent = content
		
		local btnContainer = Instance.new("Frame")
		btnContainer.Size = UDim2.new(1, 0, 0, 50)
		btnContainer.Position = UDim2.new(0, 0, 0, 30)
		btnContainer.BackgroundTransparency = 1
		btnContainer.Parent = content
		
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, 8)
		layout.Parent = btnContainer
		
		for i = 1, 6 do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 40, 0, 40)
			btn.BackgroundColor3 = COLORS.Blue
			btn.Text = tostring(i)
			btn.Font = Enum.Font.FredokaOne
			btn.TextSize = 20
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Parent = btnContainer
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			
			btn.MouseButton1Click:Connect(function()
				abilityPopup.Visible = false
				if UseAbilityEvent then
					UseAbilityEvent:FireServer("LuckyGuess", {guess = i})
				end
			end)
		end
		
	elseif abilityData.inputType == "choice" then
		-- Esper: 2 choice buttons
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 25)
		desc.BackgroundTransparency = 1
		desc.Text = abilityData.description
		desc.TextColor3 = Color3.fromRGB(200, 200, 220)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 12
		desc.Parent = content
		
		local btnContainer = Instance.new("Frame")
		btnContainer.Size = UDim2.new(1, 0, 0, 50)
		btnContainer.Position = UDim2.new(0, 0, 0, 35)
		btnContainer.BackgroundTransparency = 1
		btnContainer.Parent = content
		
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Padding = UDim.new(0, 20)
		layout.Parent = btnContainer
		
		for _, choice in ipairs(abilityData.choices) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 80, 0, 45)
			btn.BackgroundColor3 = COLORS.Purple
			btn.Text = tostring(choice) .. " ช่อง"
			btn.Font = Enum.Font.FredokaOne
			btn.TextSize = 16
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Parent = btnContainer
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			
			btn.MouseButton1Click:Connect(function()
				abilityPopup.Visible = false
				if UseAbilityEvent then
					UseAbilityEvent:FireServer("MindMove", {move = choice})
				end
			end)
		end
		
	elseif abilityData.inputType == "target" then
		-- Shaman/Fisherman: Player list
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 25)
		desc.BackgroundTransparency = 1
		desc.Text = "เลือกผู้เล่นเป้าหมาย:"
		desc.TextColor3 = Color3.fromRGB(200, 200, 220)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 12
		desc.Parent = content
		
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Size = UDim2.new(1, 0, 0, 70)
		scrollFrame.Position = UDim2.new(0, 0, 0, 30)
		scrollFrame.BackgroundTransparency = 0.8
		scrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		scrollFrame.ScrollBarThickness = 4
		scrollFrame.Parent = content
		
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.Parent = scrollFrame
		
		local abilityName = playerJob == "Shaman" and "Curse" or "StealCard"
		
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -10, 0, 30)
				btn.BackgroundColor3 = COLORS.Orange
				btn.Text = p.Name
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 14
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.Parent = scrollFrame
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
				
				btn.MouseButton1Click:Connect(function()
					abilityPopup.Visible = false
					if UseAbilityEvent then
						UseAbilityEvent:FireServer(abilityName, {targetUserId = p.UserId})
					end
				end)
			end
		end
		
	elseif abilityData.inputType == "instant" then
		-- Biker/NurseJoy: Single button
		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, 0, 0, 30)
		desc.BackgroundTransparency = 1
		desc.Text = abilityData.description
		desc.TextColor3 = Color3.fromRGB(200, 200, 220)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 14
		desc.Parent = content
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 150, 0, 45)
		btn.Position = UDim2.new(0.5, 0, 0, 45)
		btn.AnchorPoint = Vector2.new(0.5, 0)
		btn.BackgroundColor3 = COLORS.Green
		btn.Text = "⚡ ใช้เลย!"
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 18
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = content
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		
		local abilityName = playerJob == "Biker" and "TurboBoost" or "Revive"
		
		btn.MouseButton1Click:Connect(function()
			abilityPopup.Visible = false
			if UseAbilityEvent then
				UseAbilityEvent:FireServer(abilityName, {})
			end
		end)
	end
	
	abilityPopup.Visible = true
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
		abilityButton.Visible = false
		abilityPopup.Visible = false
		phaseTabFrame.Visible = false
		if HandUI then HandUI.Enabled = true end -- Restore Hand when not my turn
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

-- Ability Button Click
abilityButton.MouseButton1Click:Connect(function()
	if not isMyTurn then return end
	if currentPhase ~= "Ability" then return end
	showAbilityPopup()
end)

print("✅ PhaseUI Modern Controller Loaded")

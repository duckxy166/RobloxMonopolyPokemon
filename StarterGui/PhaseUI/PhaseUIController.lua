--[[
================================================================================
               📍 PHASE UI CONTROLLER - Client-side Phase Management
================================================================================
    📌 Location: StarterGui/PhaseUI/LocalScript
    📌 Responsibilities:
        - Display current phase indicator
        - Show "Next Phase" button during Item/Ability phases
        - Enable/Disable Roll button based on phase
        
    📌 4-PHASE TURN STRUCTURE:
        Phase 1: Draw Phase - แสดงการ์ดที่จั่วได้
        Phase 2: Item Phase - ใช้การ์ดได้ + ปุ่ม "Next Phase"
        Phase 3: Ability Phase - ใช้ Skill อาชีพ + ปุ่ม "Next Phase"  
        Phase 4: Roll Phase - ปุ่ม Roll Dice ใช้งานได้
================================================================================
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================
local PhaseUpdateEvent = Events:WaitForChild("PhaseUpdate", 5)
local UpdateTurnEvent = Events:WaitForChild("UpdateTurn")
local AdvancePhaseEvent = Events:WaitForChild("AdvancePhase", 5)
local RollDiceEvent = Events:WaitForChild("RollDice")

-- ============================================================================
-- UI REFERENCES
-- ============================================================================
local screenGui = script.Parent
local mainFrame = screenGui:WaitForChild("MainFrame", 5)

-- Create UI elements if they don't exist
local function createUI()
	-- Main Frame (if not exists)
	if not mainFrame then
		mainFrame = Instance.new("Frame")
		mainFrame.Name = "MainFrame"
		mainFrame.Size = UDim2.new(0, 300, 0, 120)
		mainFrame.Position = UDim2.new(0.5, -150, 0, 10)
		mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		mainFrame.BackgroundTransparency = 0.2
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = screenGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = mainFrame
		
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(100, 100, 120)
		stroke.Thickness = 2
		stroke.Parent = mainFrame
	end
	
	-- Phase Indicator
	local phaseLabel = mainFrame:FindFirstChild("PhaseLabel")
	if not phaseLabel then
		phaseLabel = Instance.new("TextLabel")
		phaseLabel.Name = "PhaseLabel"
		phaseLabel.Size = UDim2.new(1, -20, 0, 30)
		phaseLabel.Position = UDim2.new(0, 10, 0, 5)
		phaseLabel.BackgroundTransparency = 1
		phaseLabel.Font = Enum.Font.FredokaOne
		phaseLabel.TextSize = 20
		phaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		phaseLabel.Text = "Phase: Waiting..."
		phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
		phaseLabel.Parent = mainFrame
	end
	
	-- Phase Message
	local phaseMsg = mainFrame:FindFirstChild("PhaseMessage")
	if not phaseMsg then
		phaseMsg = Instance.new("TextLabel")
		phaseMsg.Name = "PhaseMessage"
		phaseMsg.Size = UDim2.new(1, -20, 0, 25)
		phaseMsg.Position = UDim2.new(0, 10, 0, 35)
		phaseMsg.BackgroundTransparency = 1
		phaseMsg.Font = Enum.Font.Gotham
		phaseMsg.TextSize = 14
		phaseMsg.TextColor3 = Color3.fromRGB(200, 200, 200)
		phaseMsg.Text = ""
		phaseMsg.TextXAlignment = Enum.TextXAlignment.Center
		phaseMsg.Parent = mainFrame
	end
	
	-- Next Phase Button
	local nextPhaseBtn = mainFrame:FindFirstChild("NextPhaseButton")
	if not nextPhaseBtn then
		nextPhaseBtn = Instance.new("TextButton")
		nextPhaseBtn.Name = "NextPhaseButton"
		nextPhaseBtn.Size = UDim2.new(0.45, 0, 0, 40)
		nextPhaseBtn.Position = UDim2.new(0.025, 0, 0, 65)
		nextPhaseBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		nextPhaseBtn.Font = Enum.Font.FredokaOne
		nextPhaseBtn.TextSize = 16
		nextPhaseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		nextPhaseBtn.Text = "➡️ NEXT PHASE"
		nextPhaseBtn.Visible = false
		nextPhaseBtn.Parent = mainFrame
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = nextPhaseBtn
		
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(100, 200, 100)
		btnStroke.Thickness = 2
		btnStroke.Parent = nextPhaseBtn
	end
	
	-- Roll Dice Button
	local rollBtn = mainFrame:FindFirstChild("RollDiceButton")
	if not rollBtn then
		rollBtn = Instance.new("TextButton")
		rollBtn.Name = "RollDiceButton"
		rollBtn.Size = UDim2.new(0.45, 0, 0, 40)
		rollBtn.Position = UDim2.new(0.525, 0, 0, 65)
		rollBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		rollBtn.Font = Enum.Font.FredokaOne
		rollBtn.TextSize = 16
		rollBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		rollBtn.Text = "🎲 ROLL DICE"
		rollBtn.Active = false
		rollBtn.AutoButtonColor = false
		rollBtn.Parent = mainFrame
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = rollBtn
		
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(100, 100, 100)
		btnStroke.Thickness = 2
		btnStroke.Parent = rollBtn
	end
	
	return phaseLabel, phaseMsg, nextPhaseBtn, rollBtn
end

local phaseLabel, phaseMsg, nextPhaseBtn, rollBtn = createUI()

-- ============================================================================
-- PHASE COLORS
-- ============================================================================
local PHASE_COLORS = {
	Draw = Color3.fromRGB(100, 200, 255),    -- Light Blue
	Item = Color3.fromRGB(255, 200, 50),     -- Gold
	Ability = Color3.fromRGB(200, 100, 255), -- Purple
	Roll = Color3.fromRGB(100, 255, 100),    -- Green
	Waiting = Color3.fromRGB(150, 150, 150)  -- Gray
}

local PHASE_ICONS = {
	Draw = "🃏",
	Item = "🎒",
	Ability = "⚡",
	Roll = "🎲"
}

-- ============================================================================
-- STATE
-- ============================================================================
local currentPhase = "Waiting"
local isMyTurn = false
local isRolling = false

-- ============================================================================
-- UI UPDATE FUNCTIONS
-- ============================================================================

local function updatePhaseUI(phase, message)
	currentPhase = phase
	local icon = PHASE_ICONS[phase] or "⏳"
	local color = PHASE_COLORS[phase] or PHASE_COLORS.Waiting
	
	-- Update Phase Label with animation
	local targetText = icon .. " Phase: " .. phase
	
	-- Fade out
	local fadeOut = TweenService:Create(phaseLabel, TweenInfo.new(0.15), {TextTransparency = 1})
	fadeOut:Play()
	fadeOut.Completed:Wait()
	
	phaseLabel.Text = targetText
	phaseLabel.TextColor3 = color
	
	-- Fade in
	local fadeIn = TweenService:Create(phaseLabel, TweenInfo.new(0.15), {TextTransparency = 0})
	fadeIn:Play()
	
	-- Update message
	if message then
		phaseMsg.Text = message
	end
	
	-- Update button visibility based on phase
	if isMyTurn then
		if phase == "Item" or phase == "Ability" then
			-- Show Next Phase button, disable Roll
			nextPhaseBtn.Visible = true
			nextPhaseBtn.Active = true
			
			rollBtn.Active = false
			rollBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			rollBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			rollBtn.AutoButtonColor = false
			
		elseif phase == "Roll" then
			-- Hide Next Phase button, enable Roll
			nextPhaseBtn.Visible = false
			
			rollBtn.Active = true
			rollBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
			rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			rollBtn.AutoButtonColor = true
			isRolling = false
			
		else
			-- Draw phase or waiting - hide both action buttons
			nextPhaseBtn.Visible = false
			rollBtn.Active = false
			rollBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			rollBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
			rollBtn.AutoButtonColor = false
		end
	else
		-- Not my turn - hide all action buttons
		nextPhaseBtn.Visible = false
		rollBtn.Active = false
		rollBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		rollBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

local function setWaitingState(waitingForName)
	isMyTurn = false
	currentPhase = "Waiting"
	
	phaseLabel.Text = "⏳ " .. waitingForName .. "'s Turn"
	phaseLabel.TextColor3 = PHASE_COLORS.Waiting
	phaseMsg.Text = "Waiting..."
	
	nextPhaseBtn.Visible = false
	rollBtn.Active = false
	rollBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	rollBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Phase Update from Server
if PhaseUpdateEvent then
	PhaseUpdateEvent.OnClientEvent:Connect(function(phase, message)
		print("📍 [Client] Phase Update:", phase, message)
		isMyTurn = true
		updatePhaseUI(phase, message)
	end)
end

-- Turn Update from Server
UpdateTurnEvent.OnClientEvent:Connect(function(currentPlayerName, phase)
	print("🔄 [Client] Turn Update:", currentPlayerName, "Phase:", phase or "Roll")
	
	if currentPlayerName == player.Name then
		isMyTurn = true
		if phase then
			updatePhaseUI(phase, nil)
		else
			-- Legacy support: if no phase provided, assume Roll
			updatePhaseUI("Roll", "กดทอยเต๋าได้เลย!")
		end
	else
		setWaitingState(currentPlayerName)
	end
end)

-- ============================================================================
-- BUTTON CLICK HANDLERS
-- ============================================================================

-- Next Phase Button
nextPhaseBtn.MouseButton1Click:Connect(function()
	if not isMyTurn then return end
	if currentPhase ~= "Item" and currentPhase ~= "Ability" then return end
	
	print("📍 [Client] Advancing to next phase from:", currentPhase)
	
	-- Disable button to prevent double-click
	nextPhaseBtn.Active = false
	nextPhaseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	
	-- Fire server event
	if AdvancePhaseEvent then
		AdvancePhaseEvent:FireServer()
	end
end)

-- Roll Dice Button
rollBtn.MouseButton1Click:Connect(function()
	if not isMyTurn then return end
	if currentPhase ~= "Roll" then 
		-- Show warning
		phaseMsg.Text = "❌ Complete previous phases first!"
		phaseMsg.TextColor3 = Color3.fromRGB(255, 100, 100)
		task.delay(2, function()
			phaseMsg.TextColor3 = Color3.fromRGB(200, 200, 200)
		end)
		return 
	end
	if isRolling then return end
	
	print("🎲 [Client] Rolling dice...")
	isRolling = true
	
	-- Disable button
	rollBtn.Active = false
	rollBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	rollBtn.Text = "🎲 Rolling..."
	
	-- Fire server event
	RollDiceEvent:FireServer()
end)

-- ============================================================================
-- HOVER EFFECTS
-- ============================================================================

nextPhaseBtn.MouseEnter:Connect(function()
	if nextPhaseBtn.Active then
		TweenService:Create(nextPhaseBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(70, 180, 70)
		}):Play()
	end
end)

nextPhaseBtn.MouseLeave:Connect(function()
	if nextPhaseBtn.Active then
		TweenService:Create(nextPhaseBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		}):Play()
	end
end)

rollBtn.MouseEnter:Connect(function()
	if rollBtn.Active then
		TweenService:Create(rollBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(70, 220, 120)
		}):Play()
	end
end)

rollBtn.MouseLeave:Connect(function()
	if rollBtn.Active then
		TweenService:Create(rollBtn, TweenInfo.new(0.1), {
			BackgroundColor3 = Color3.fromRGB(50, 200, 100)
		}):Play()
	end
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================
print("✅ PhaseUI Controller Loaded (4-Phase System)")
updatePhaseUI("Waiting", "Waiting for game to start...")

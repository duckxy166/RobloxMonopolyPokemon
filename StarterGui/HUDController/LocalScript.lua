local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [[ 🎨 UI CONSTRUCTION ]] --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false -- Don't flicker on respawn
screenGui.Parent = playerGui

-- 1. ROLL BUTTON
local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 200, 0, 80)
rollButton.Position = UDim2.new(1, -220, 0.5, -40) -- Center Right
rollButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Grey initially
rollButton.Text = "Loading..."
rollButton.Font = Enum.Font.FredokaOne
rollButton.TextSize = 24
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.Visible = true
rollButton.Parent = screenGui

local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 12)
rollCorner.Parent = rollButton

-- 2. RESET CAM BUTTON
local resetCamButton = Instance.new("TextButton")
resetCamButton.Name = "ResetCamButton"
resetCamButton.Size = UDim2.new(0, 120, 0, 40)
resetCamButton.Position = UDim2.new(1, -140, 1, -60) -- Bottom Right
resetCamButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
resetCamButton.Text = "🔄 Reset Cam"
resetCamButton.Font = Enum.Font.GothamBold
resetCamButton.TextSize = 14
resetCamButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetCamButton.Parent = screenGui

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 8)
resetCorner.Parent = resetCamButton

-- 3. TIMER / STATUS LABEL
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 300, 0, 50)
timerLabel.Position = UDim2.new(0.5, 0, 0, 20) -- Top Center
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.BackgroundTransparency = 0.5
timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Text = "Connecting to Server..."
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 20
timerLabel.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 8)
timerCorner.Parent = timerLabel

-- [[ 🔌 CONNECTION ]] --
local rollEvent, updateTurnEvent, resetCamEvent, lockEvent

task.spawn(function()
	rollEvent = ReplicatedStorage:WaitForChild("RollDiceEvent")
	updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")
	
	-- Bindable Event for Camera Reset
	resetCamEvent = ReplicatedStorage:FindFirstChild("ResetCameraEvent")
	if not resetCamEvent then
		resetCamEvent = Instance.new("BindableEvent")
		resetCamEvent.Name = "ResetCameraEvent"
		resetCamEvent.Parent = ReplicatedStorage
	end

	-- Camera Lock Event (for internal use)
	lockEvent = ReplicatedStorage:FindFirstChild("CameraLockEvent") 
	if not lockEvent then
		lockEvent = Instance.new("BindableEvent")
		lockEvent.Name = "CameraLockEvent"
		lockEvent.Parent = ReplicatedStorage
	end
	
	-- Ready!
	timerLabel.Text = "Waiting for game..."
	
	-- Event: Update Turn
	updateTurnEvent.OnClientEvent:Connect(function(currentName)
		if currentName == player.Name then
			-- My turn
			rollButton.Text = "🎲 ROLL DICE!" 
			rollButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0) 
			timerLabel.Text = "YOUR TURN!" 
			timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		else
			-- Enemy turn
			rollButton.Text = "WAIT..."
			rollButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			timerLabel.Text = "Waiting for " .. currentName
			timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)

	-- Event: Roll Result (Animation)
	rollEvent.OnClientEvent:Connect(function(rollResult)
		if lockEvent then lockEvent:Fire(true) end
		rollButton.Visible = false 
		timerLabel.Text = "🎲 " .. rollResult .. "!"

		local dice
		local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
		local camera = workspace.CurrentCamera
		
		if diceTemplate then dice = diceTemplate:Clone() else dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) end
		dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false
		
		-- Spin Animation
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not dice.Parent then connection:Disconnect() return end
			local cf = camera.CFrame; local pos = cf + (cf.LookVector * 10)
			dice.CFrame = CFrame.new(pos.Position) * CFrame.Angles(math.rad(os.clock()*700), math.rad(os.clock()*500), math.rad(os.clock()*600))
		end)

		task.wait(1.5)
		connection:Disconnect()

		-- Show Final Face
		local ROTATION_OFFSETS = {
			[1] = CFrame.Angles(0, 0, 0),
			[2] = CFrame.Angles(math.rad(-90), 0, 0),
			[3] = CFrame.Angles(0, math.rad(90), 0),
			[4] = CFrame.Angles(0, math.rad(-90), 0),
			[5] = CFrame.Angles(math.rad(90), 0, 0),
			[6] = CFrame.Angles(0, math.rad(180), 0)
		}
		
		local finalCF = camera.CFrame
		local dicePos = (finalCF + finalCF.LookVector * 8).Position
		local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[rollResult]
		})
		tw:Play()

		task.wait(1.5)
		dice:Destroy()
		if lockEvent then lockEvent:Fire(false) end
	end)
end)

-- Assets
local camera = workspace.CurrentCamera

-- [[ 🧠 LOGIC ]] --

local isRolling = false

-- Logic: Roll Button
rollButton.MouseButton1Click:Connect(function()
	if isRolling then return end
	-- Check button text/color to imply turn, or rely on server validation
	if rollButton.Text == "WAIT..." or rollButton.Text == "Loading..." then return end

	isRolling = true
	rollButton.Visible = false 
	timerLabel.Text = "Rolling..."
	
	if rollEvent then rollEvent:FireServer() end
end)

-- Logic: Reset Cam
resetCamButton.MouseButton1Click:Connect(function()
	print("Reset Camera Clicked")
	if resetCamEvent then resetCamEvent:Fire() end
end)


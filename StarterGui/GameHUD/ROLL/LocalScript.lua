local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- รอ RemoteEvents จาก Server (ไม่มี timeout เพราะ Server อาจโหลดช้ากว่า)
print("🎲 [Client] Waiting for RemoteEvents...")

local rollEvent = ReplicatedStorage:WaitForChild("RollDiceEvent") -- รอจนกว่าจะเจอ
local updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent") -- รอจนกว่าจะเจอ

print("✅ [Client] RemoteEvents found!")

-- CameraLockEvent (optional - สร้างเองถ้าไม่มี)
local lockEvent = ReplicatedStorage:FindFirstChild("CameraLockEvent") 
if not lockEvent then
	lockEvent = Instance.new("BindableEvent")
	lockEvent.Name = "CameraLockEvent"
	lockEvent.Parent = ReplicatedStorage
end

local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel") 

local button = script.Parent

-- ?? ScreenGui ??????
local screenGui = button:FindFirstAncestorWhichIsA("ScreenGui") 
local timerLabel = nil
if screenGui then timerLabel = screenGui:FindFirstChild("TimerLabel", true) end

local camera = workspace.CurrentCamera
local ROTATION_OFFSETS = {
	[1] = CFrame.Angles(0, 0, 0),
	[2] = CFrame.Angles(math.rad(-90), 0, 0),
	[3] = CFrame.Angles(0, math.rad(90), 0),
	[4] = CFrame.Angles(0, math.rad(-90), 0),
	[5] = CFrame.Angles(math.rad(90), 0, 0),
	[6] = CFrame.Angles(0, math.rad(180), 0)
}

local isRolling = false
local isMyTurn = true  -- เริ่มต้น true เพื่อให้ผู้เล่นคนแรกทอยได้

-- ทำให้ปุ่มเห็นได้ตั้งแต่เริ่ม
button.Visible = true
print("🎲 Dice LocalScript loaded! Player:", player.Name)

button.MouseButton1Click:Connect(function()
	print("🖱️ Button clicked! isRolling:", isRolling, "isMyTurn:", isMyTurn)
	
	if isRolling then 
		print("❌ Already rolling, ignoring click")
		return 
	end
	if not isMyTurn then 
		print("❌ Not my turn, ignoring click")
		return 
	end 

	isRolling = true
	isMyTurn = false 

	button.Visible = false 
	if timerLabel then timerLabel.Text = "Rolling..." end

	print("🎲 Firing RollDiceEvent to server!")
	rollEvent:FireServer()
end)

updateTurnEvent.OnClientEvent:Connect(function(currentName)
	-- [[ ? ???????????????????????????? ]] --

	if currentName == player.Name then
		-- ?????????
		isMyTurn = true
		button.Visible = true
		button.Text = "?? ROLL DICE!" 
		button.BackgroundColor3 = Color3.fromRGB(0, 170, 0) 

		if timerLabel then 
			timerLabel.Text = "YOUR TURN!" 
			timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		end
	else
		-- ????????????
		isMyTurn = false
		button.Visible = true 
		button.Text = "WAIT..."
		button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

		if timerLabel then 
			timerLabel.Text = "Waiting for " .. currentName
			timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end)

rollEvent.OnClientEvent:Connect(function(rollResult)
	lockEvent:Fire(true)
	button.Visible = false 
	if timerLabel then timerLabel.Text = "?? ..." end

	local dice
	if diceTemplate then dice = diceTemplate:Clone() else dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) end
	dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not dice.Parent then connection:Disconnect() return end
		local cf = camera.CFrame; local pos = cf + (cf.LookVector * 6)
		dice.CFrame = CFrame.new(pos.Position) * CFrame.Angles(math.rad(os.clock()*700), math.rad(os.clock()*500), math.rad(os.clock()*600))
	end)

	task.wait(2)
	connection:Disconnect()

	local finalCF = camera.CFrame
	local dicePos = (finalCF + finalCF.LookVector * 5).Position
	local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[rollResult]
	})
	tw:Play()

	task.wait(1.5)
	dice:Destroy()
	lockEvent:Fire(false)
	isRolling = false
end)
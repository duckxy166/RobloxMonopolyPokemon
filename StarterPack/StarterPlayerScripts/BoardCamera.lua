local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- Constants
local BUTTON_NAME = "ResetCamButton" -- Name of the Reset button in ScreenGui

local MOVE_SPEED = 1.0     
local ROTATE_SPEED = 0.2   
local SCROLL_SPEED = 5     
local MIN_ZOOM = 10        
local MAX_ZOOM = 150       
local START_HEIGHT = 60    
local START_ANGLE = math.rad(-45)

-- State
local defaultFocus = Vector3.new(0, 0, 0) -- Target position for camera reset
local cameraFocus = Vector3.new(0, 0, 0)  -- Current target position
local cameraDistance = START_HEIGHT
local currentYaw = 0
local currentPitch = START_ANGLE

-- Initial focus point (CenterStage)
local startPart = Workspace:FindFirstChild("CenterStage")
if startPart then 
	defaultFocus = startPart.Position 
	cameraFocus = defaultFocus -- Initial setup
end

-- Reset Camera Function
local function resetCamera()
	print("Resetting Camera to Player Position...")
	
	-- Reset to player character position
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			cameraFocus = humanoidRootPart.Position
		else
			cameraFocus = defaultFocus -- fallback to default if HRP missing
		end
	else
		cameraFocus = defaultFocus -- fallback to default if no character
	end
	
	cameraDistance = START_HEIGHT -- reset distance
	currentYaw = 0 -- reset yaw
	currentPitch = START_ANGLE -- reset pitch
end

-- Connect Reset Button
local function connectResetButton()
	-- Search for button in PlayerGui
	local btn = playerGui:FindFirstChild(BUTTON_NAME, true) 

	if btn then
		print("✅ Reset Button connected!")
		-- Clean up old connection tag if exists
		if btn:FindFirstChild("Connected") then btn.Connected:Destroy() end

		local tag = Instance.new("BoolValue", btn)
		tag.Name = "Connected"

		btn.MouseButton1Click:Connect(resetCamera)
	else
		warn("⚠️ Button '"..BUTTON_NAME.."' not found! Ensure it exists in StarterGui.")
	end
end

-- Call initial connection
connectResetButton()
-- Reconnect on character respawn (GUI might be recreated)
player.CharacterAdded:Connect(function()
	task.wait(1)
	connectResetButton()
end)

-- Utility Functions
local function freezePlayer(actionName, inputState, inputObject)
	return Enum.ContextActionResult.Sink 
end

ContextActionService:BindActionAtPriority("FreezeMovement", freezePlayer, false, 3000, 
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, 
	Enum.KeyCode.Space, Enum.KeyCode.Tab
)

-- Mouse Input Handling
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Zoom
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		cameraDistance = cameraDistance - (input.Position.Z * SCROLL_SPEED)
		cameraDistance = math.clamp(cameraDistance, MIN_ZOOM, MAX_ZOOM)
	end

	-- Rotate (RMB)
	if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		local delta = input.Delta
		currentYaw = currentYaw - (delta.X * ROTATE_SPEED * 0.01)
		currentPitch = currentPitch - (delta.Y * ROTATE_SPEED * 0.01)
		currentPitch = math.clamp(currentPitch, math.rad(-85), math.rad(-10))
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

-- Render Step Handler (WASD + Camera Update)
RunService.RenderStepped:Connect(function()
	camera.CameraType = Enum.CameraType.Scriptable

	-- WASD Move
	local moveDir = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Vector3.new(0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir + Vector3.new(0, 0, 1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir + Vector3.new(-1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(1, 0, 0) end

	if moveDir.Magnitude > 0 then
		local camCFrame = CFrame.fromEulerAnglesYXZ(0, currentYaw, 0)
		local worldMoveDir = camCFrame:VectorToWorldSpace(moveDir)
		cameraFocus = cameraFocus + (worldMoveDir * MOVE_SPEED)
	end

	-- Update Position
	local rotation = CFrame.fromEulerAnglesYXZ(currentPitch, currentYaw, 0)
	local offset = Vector3.new(0, 0, cameraDistance)
	local finalPos = cameraFocus + (rotation * offset)

	camera.CFrame = CFrame.new(finalPos, cameraFocus)
end)
--[[
================================================================================
                      📷 BOARD CAMERA CONTROLLER (FIXED ANGLES)
================================================================================
    📌 Location: StarterPlayerScripts/BoardCamera.lua
    📌 Features:
        - Fully disables character movement (WASD, Jump, Roblox defaults)
        - Locks camera to MainCamera / EncounterCamera / BattleCamera parts
        - Switches camera mode based on game events
        - Reset returns to CURRENT MODE camera, NOT the character
================================================================================
--]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ================================================================================
--                           🚫 DISABLE ALL CHARACTER MOVEMENT
-- ================================================================================

-- Method 1: Sink all movement inputs with highest priority
local function sinkInput()
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority("SinkMoveForward", sinkInput, false, 10000, Enum.PlayerActions.CharacterForward)
ContextActionService:BindActionAtPriority("SinkMoveBackward", sinkInput, false, 10000, Enum.PlayerActions.CharacterBackward)
ContextActionService:BindActionAtPriority("SinkMoveLeft", sinkInput, false, 10000, Enum.PlayerActions.CharacterLeft)
ContextActionService:BindActionAtPriority("SinkMoveRight", sinkInput, false, 10000, Enum.PlayerActions.CharacterRight)
ContextActionService:BindActionAtPriority("SinkJump", sinkInput, false, 10000, Enum.PlayerActions.CharacterJump)

-- Sink raw keys as well
ContextActionService:BindActionAtPriority("SinkWASD", sinkInput, false, 10000,
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Space, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right
)

-- Method 2: Disable player controls via PlayerModule if available
task.spawn(function()
	local PlayerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
	if PlayerModule then
		local controls = require(PlayerModule):GetControls()
		if controls then
			controls:Disable()
			print("✅ [Camera] PlayerModule controls disabled.")
		end
	end
end)

-- Method 3: Freeze Humanoid WalkSpeed/JumpPower
local function freezeCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	end
end

if player.Character then freezeCharacter(player.Character) end
player.CharacterAdded:Connect(freezeCharacter)

-- ================================================================================
--                           📷 CAMERA MODE STATE
-- ================================================================================

-- Camera Mode: "Main", "Encounter", "Battle"
local currentMode = "Main"

-- Camera Part References (directly in Workspace)
local mainCameraPart = Workspace:WaitForChild("MainCamera", 5)
local encounterCameraPart = Workspace:WaitForChild("EncounterCamera", 5)
local battleCameraPart = Workspace:WaitForChild("BattleCamera", 5)

-- Debug: Print camera parts status
print("📷 [Camera] MainCamera:", mainCameraPart and mainCameraPart:GetFullName() or "NOT FOUND")
print("📷 [Camera] EncounterCamera:", encounterCameraPart and encounterCameraPart:GetFullName() or "NOT FOUND")
print("📷 [Camera] BattleCamera:", battleCameraPart and battleCameraPart:GetFullName() or "NOT FOUND")

-- Helper: Get current mode's camera CFrame
local function getModeCameraCFrame()
	if currentMode == "Encounter" and encounterCameraPart then
		return encounterCameraPart.CFrame
	elseif currentMode == "Battle" and battleCameraPart then
		return battleCameraPart.CFrame
	elseif mainCameraPart then
		return mainCameraPart.CFrame
	end
	return nil
end

-- ================================================================================
--                           🔄 RENDER STEP (CAMERA LOCK)
-- ================================================================================

RunService.RenderStepped:Connect(function()
	if not camera then camera = Workspace.CurrentCamera end
	camera.CameraType = Enum.CameraType.Scriptable

	-- Dynamic Part Retrieval
	if not cameraFolder then cameraFolder = Workspace:FindFirstChild("Camera") end
	if not mainCameraPart and cameraFolder then mainCameraPart = cameraFolder:FindFirstChild("MainCamera") end
	if not encounterCameraPart and cameraFolder then encounterCameraPart = cameraFolder:FindFirstChild("EncounterCamera") end
	if not battleCameraPart and cameraFolder then battleCameraPart = cameraFolder:FindFirstChild("BattleCamera") end

	-- Lock camera to current mode's part
	local targetCFrame = getModeCameraCFrame()
	if targetCFrame then
		camera.CFrame = targetCFrame
	end
end)

-- ================================================================================
--                           ♻️ RESET CAMERA (To Current Mode)
-- ================================================================================

local resetCamEvent = ReplicatedStorage:FindFirstChild("ResetCameraEvent")
if not resetCamEvent then
	resetCamEvent = Instance.new("BindableEvent")
	resetCamEvent.Name = "ResetCameraEvent"
	resetCamEvent.Parent = ReplicatedStorage
end

resetCamEvent.Event:Connect(function()
	print("📷 [Camera] Reset requested -> Returning to", currentMode, "mode camera")
	-- Camera is already locked in RenderStepped, nothing special needed.
	-- If you want a "snap" effect, you could tween here.
end)

-- ================================================================================
--                           📡 CAMERA MODE EVENTS
-- ================================================================================

local EncounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent", 10)
local BattleStartEvent = ReplicatedStorage:WaitForChild("BattleStartEvent", 10)
local BattleEndEvent = ReplicatedStorage:WaitForChild("BattleEndEvent", 10)
local RunEvent = ReplicatedStorage:WaitForChild("RunEvent", 10)
local CatchPokemonEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent", 10)

print("📷 [Camera] Events found:", 
	EncounterEvent and "Encounter✓" or "Encounter✗",
	BattleStartEvent and "BattleStart✓" or "BattleStart✗",
	BattleEndEvent and "BattleEnd✓" or "BattleEnd✗",
	RunEvent and "Run✓" or "Run✗",
	CatchPokemonEvent and "CatchPokemon✓" or "CatchPokemon✗"
)

-- Encounter Started -> Switch to Encounter Camera
if EncounterEvent then
	EncounterEvent.OnClientEvent:Connect(function(targetPlayer, data)
		print("📷 [Camera] EncounterEvent received! targetPlayer:", targetPlayer, "localPlayer:", player)
		
		-- Compare by UserId for safety (works across server/client boundary)
		local targetUserId = (typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player")) and targetPlayer.UserId or nil
		local isMe = (targetPlayer == player) or (targetUserId and targetUserId == player.UserId)
		
		if isMe then
			print("📷 [Camera] ✓ Switching to Encounter Mode")
			currentMode = "Encounter"
		else
			print("📷 [Camera] ✗ Not my encounter, ignoring")
		end
	end)
else
	warn("📷 [Camera] EncounterEvent NOT FOUND!")
end

-- Battle Started -> Switch to Battle Camera
if BattleStartEvent then
	BattleStartEvent.OnClientEvent:Connect(function(battleType, data)
		print("📷 [Camera] BattleStartEvent received! Type:", battleType)
		print("📷 [Camera] ✓ Switching to Battle Mode")
		currentMode = "Battle"
	end)
else
	warn("📷 [Camera] BattleStartEvent NOT FOUND!")
end

-- Battle Ended -> Return to Main Camera
if BattleEndEvent then
	BattleEndEvent.OnClientEvent:Connect(function(result)
		print("📷 [Camera] BattleEndEvent received!")
		print("📷 [Camera] ✓ Battle Ended, returning to Main Mode")
		currentMode = "Main"
	end)
else
	warn("📷 [Camera] BattleEndEvent NOT FOUND!")
end

-- Ran from Encounter -> Return to Main Camera
if RunEvent then
	RunEvent.OnClientEvent:Connect(function(runPlayer)
		print("📷 [Camera] RunEvent received!")
		
		-- Only switch back if it's our encounter that ended
		local runUserId = (typeof(runPlayer) == "Instance" and runPlayer:IsA("Player")) and runPlayer.UserId or nil
		local isMe = (runPlayer == player) or (runUserId and runUserId == player.UserId)
		
		if isMe then
			print("📷 [Camera] ✓ Run Event (me), returning to Main Mode")
			currentMode = "Main"
		end
	end)
else
	warn("📷 [Camera] RunEvent NOT FOUND!")
end

-- Catch Result -> Return to Main Camera if finished
if CatchPokemonEvent then
	CatchPokemonEvent.OnClientEvent:Connect(function(catcher, success, roll, target, isFinished)
		print("📷 [Camera] CatchPokemonEvent received! catcher:", catcher, "finished:", isFinished)
		
		local catcherUserId = (typeof(catcher) == "Instance" and catcher:IsA("Player")) and catcher.UserId or nil
		local isMe = (catcher == player) or (catcherUserId and catcherUserId == player.UserId)
		
		if isMe and isFinished then
			print("📷 [Camera] ✓ Catch finished (me), returning to Main Mode")
			task.delay(1.5, function()
				currentMode = "Main"
			end)
		end
	end)
else
	warn("📷 [Camera] CatchPokemonEvent NOT FOUND!")
end

print("✅ BoardCamera Loaded (Strict: No Movement, Fixed Camera Angles)")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Camera Mode State: "Main", "Encounter", "Battle"
local currentMode = "Main"

-- Camera Folder Reference
local cameraFolder = Workspace:WaitForChild("Camera", 10)

-- Camera Part References
local mainCameraPart = cameraFolder and cameraFolder:FindFirstChild("MainCamera")
local encounterCameraPart = cameraFolder and cameraFolder:FindFirstChild("EncounterCamera")
local battleCameraPart = cameraFolder and cameraFolder:FindFirstChild("BattleCamera")

-- Render Step Handler (Camera Update)
RunService.RenderStepped:Connect(function()
	camera.CameraType = Enum.CameraType.Scriptable

	-- Mode: Main (Lock to MainCamera Part)
	if currentMode == "Main" then
		if mainCameraPart then
			camera.CFrame = mainCameraPart.CFrame
		end

	-- Mode: Encounter (Lock to EncounterCamera Part)
	elseif currentMode == "Encounter" then
		if encounterCameraPart then
			camera.CFrame = encounterCameraPart.CFrame
		end

	-- Mode: Battle (Lock to BattleCamera Part)
	elseif currentMode == "Battle" then
		if battleCameraPart then
			camera.CFrame = battleCameraPart.CFrame
		end
	end
end)

-- ================================================================================
--                           📷 CAMERA MODE EVENTS
-- ================================================================================

-- Events
local EncounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent", 10)
local BattleStartEvent = ReplicatedStorage:WaitForChild("BattleStartEvent", 10)
local BattleEndEvent = ReplicatedStorage:WaitForChild("BattleEndEvent", 10)
local RunEvent = ReplicatedStorage:WaitForChild("RunEvent", 10)
local CatchPokemonEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent", 10)

-- Encounter Started -> Switch to Encounter Camera
if EncounterEvent then
	EncounterEvent.OnClientEvent:Connect(function(targetPlayer, data)
		if targetPlayer == player then
			print("📷 [Camera] Switching to Encounter Mode")
			currentMode = "Encounter"
		end
	end)
end

-- Battle Started -> Switch to Battle Camera
if BattleStartEvent then
	BattleStartEvent.OnClientEvent:Connect(function(type, data)
		print("📷 [Camera] Switching to Battle Mode")
		currentMode = "Battle"
	end)
end

-- Battle Ended -> Return to Main Camera
if BattleEndEvent then
	BattleEndEvent.OnClientEvent:Connect(function()
		print("📷 [Camera] Battle Ended, returning to Main Mode")
		currentMode = "Main"
	end)
end

-- Ran from Encounter -> Return to Main Camera
if RunEvent then
	RunEvent.OnClientEvent:Connect(function()
		print("📷 [Camera] Run Event, returning to Main Mode")
		currentMode = "Main"
	end)
end

-- Catch Result Event -> Return to Main Camera if finished
if CatchPokemonEvent then
	CatchPokemonEvent.OnClientEvent:Connect(function(catcher, success, roll, target, isFinished)
		if catcher == player and isFinished then
			print("📷 [Camera] Catch finished, returning to Main Mode")
			task.delay(1.5, function() -- Delay to allow UI animation
				currentMode = "Main"
			end)
		end
	end)
end

print("✅ BoardCamera Loaded (Fixed Camera Modes: Main, Encounter, Battle)")
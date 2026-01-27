local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [[ 🎨 UI CONSTRUCTION ]] --
-- [[ 🎨 UI CONSTRUCTION ]] --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD_V2"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Players Status Container (Corner Boxes)
local playersContainer = Instance.new("Frame")
playersContainer.Name = "PlayersContainer"
playersContainer.Size = UDim2.new(1, 0, 1, 0)
playersContainer.BackgroundTransparency = 1
playersContainer.Parent = screenGui

local cornerPositions = {
	[1] = {UDim2.new(0, 20, 1, -120), Vector2.new(0, 1)}, -- Bottom Left
	[2] = {UDim2.new(1, -20, 1, -120), Vector2.new(1, 1)}, -- Bottom Right
	[3] = {UDim2.new(0, 20, 0, 20), Vector2.new(0, 0)}, -- Top Left
	[4] = {UDim2.new(1, -20, 0, 20), Vector2.new(1, 0)}, -- Top Right
}

local playerFrames = {} -- Store references by PlayerName

-- Function to create a Player HUD Box
local function createPlayerBox(targetPlayer, index)
	if not targetPlayer then return end
	local pos = cornerPositions[index] or cornerPositions[1]
	
	local box = Instance.new("Frame")
	box.Name = "HUD_" .. targetPlayer.Name
	box.Size = UDim2.new(0, 240, 0, 100) -- Expanded for Pokemon party row
	box.Position = pos[1]
	box.AnchorPoint = pos[2]
	box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	box.BackgroundTransparency = 0.2
	box.BorderSizePixel = 0
	box.Parent = playersContainer
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = box
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = box
	
	-- Profile Picture
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.new(0, 60, 0, 60)
	avatarImg.Position = UDim2.new(0, 10, 0.5, 0)
	avatarImg.AnchorPoint = Vector2.new(0, 0.5)
	avatarImg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	avatarImg.Parent = box
	Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
	
	-- Load Avatar
	task.spawn(function()
		local content, isReady = Players:GetUserThumbnailAsync(targetPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if isReady then avatarImg.Image = content end
	end)
	
	-- Name Label
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -80, 0, 20)
	nameLbl.Position = UDim2.new(0, 80, 0, 10)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = targetPlayer.Name
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = box
	
	-- Stats Row (Money, Cards, Balls)
	local statsRow = Instance.new("Frame")
	statsRow.Size = UDim2.new(1, -80, 0, 30)
	statsRow.Position = UDim2.new(0, 80, 0, 35)
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = box
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.Parent = statsRow
	
	local function createStat(icon, valName, color)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, 45, 1, 0)
		f.BackgroundTransparency = 1
		f.Parent = statsRow
		
		local icn = Instance.new("TextLabel")
		icn.Size = UDim2.new(0, 20, 1, 0)
		icn.BackgroundTransparency = 1
		icn.Text = icon
		icn.TextSize = 14
		icn.Parent = f
		
		local val = Instance.new("TextLabel")
		val.Name = "ValueLabel_" .. valName -- Tag for updating
		val.Size = UDim2.new(1, -20, 1, 0)
		val.Position = UDim2.new(0, 20, 0, 0)
		val.BackgroundTransparency = 1
		val.Text = "0"
		val.TextColor3 = color
		val.Font = Enum.Font.GothamBold
		val.TextSize = 14
		val.TextXAlignment = Enum.TextXAlignment.Left
		val.Parent = f
	end
	
	createStat("🟡", "Money", Color3.fromRGB(255, 220, 0))
	createStat("🃏", "Cards", Color3.fromRGB(200, 200, 200))
	createStat("🔴", "Balls", Color3.fromRGB(255, 100, 100))
	
	-- Pokemon Party Row (6 slots)
	local partyRow = Instance.new("Frame")
	partyRow.Name = "PartyRow"
	partyRow.Size = UDim2.new(1, -20, 0, 24)
	partyRow.Position = UDim2.new(0, 10, 0, 68)
	partyRow.BackgroundTransparency = 1
	partyRow.Parent = box
	
	local partyLayout = Instance.new("UIListLayout")
	partyLayout.FillDirection = Enum.FillDirection.Horizontal
	partyLayout.Padding = UDim.new(0, 4)
	partyLayout.Parent = partyRow
	
	local partySlots = {}
	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.Size = UDim2.new(0, 24, 0, 24)
		slot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		slot.BackgroundTransparency = 0.5
		slot.Parent = partyRow
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)
		
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = ""
		icon.TextSize = 14
		icon.Parent = slot
		
		partySlots[i] = slot
	end
	
	-- Store for updates
	playerFrames[targetPlayer.Name] = {
		Box = box,
		Stroke = uiStroke,
		MoneyLbl = box:FindFirstChild("ValueLabel_Money", true),
		CardLbl = box:FindFirstChild("ValueLabel_Cards", true),
		BallLbl = box:FindFirstChild("ValueLabel_Balls", true),
		PartySlots = partySlots
	}
end

-- Pokemon emoji mapping
local POKEMON_ICONS = {
	["Bulbasaur"] = "🌱",
	["Charmander"] = "🔥",
	["Squirtle"] = "💧",
	["Pikachu"] = "⚡",
	["Mewtwo"] = "🔮",
	["Default"] = "🔵"
}

-- Update Pokemon party icons for a player
local function updatePartyIcons(targetPlayer)
	local frame = playerFrames[targetPlayer.Name]
	if not frame or not frame.PartySlots then return end
	
	local inventory = targetPlayer:FindFirstChild("PokemonInventory")
	if not inventory then return end
	
	local pokemons = inventory:GetChildren()
	for i = 1, 6 do
		local slot = frame.PartySlots[i]
		local icon = slot:FindFirstChild("Icon")
		if icon then
			if pokemons[i] then
				local pokeName = pokemons[i].Name
				icon.Text = POKEMON_ICONS[pokeName] or POKEMON_ICONS["Default"]
				slot.BackgroundTransparency = 0.3
			else
				icon.Text = ""
				slot.BackgroundTransparency = 0.7
			end
		end
	end
end

-- Listen for inventory changes for all players
local function setupInventoryListener(targetPlayer)
	local inventory = targetPlayer:WaitForChild("PokemonInventory", 10)
	if inventory then
		updatePartyIcons(targetPlayer)
		inventory.ChildAdded:Connect(function() updatePartyIcons(targetPlayer) end)
		inventory.ChildRemoved:Connect(function() updatePartyIcons(targetPlayer) end)
	end
end

-- Init Players
for i, p in ipairs(Players:GetPlayers()) do
	createPlayerBox(p, i)
	task.spawn(function() setupInventoryListener(p) end)
end
Players.PlayerAdded:Connect(function(p)
	createPlayerBox(p, #Players:GetPlayers())
	task.spawn(function() setupInventoryListener(p) end)
end)

-- 1. ROLL BUTTON (Updated Style)
local rollButton = Instance.new("TextButton")
rollButton.Name = "RollButton"
rollButton.Size = UDim2.new(0, 160, 0, 80)
-- Move to RIGHT SIDE (Center Vertical)
rollButton.Position = UDim2.new(1, -40, 0.5, 0) 
rollButton.AnchorPoint = Vector2.new(1, 0.5)
rollButton.BackgroundColor3 = Color3.fromRGB(50, 200, 100) -- Green
rollButton.Text = "🎲 ROLL"
rollButton.Font = Enum.Font.FredokaOne
rollButton.TextSize = 28
rollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rollButton.Visible = true
rollButton.Parent = screenGui
Instance.new("UICorner", rollButton).CornerRadius = UDim.new(0, 16)

-- 2. END TURN BUTTON
local endTurnButton = Instance.new("TextButton")
endTurnButton.Name = "EndTurnButton"
endTurnButton.Size = UDim2.new(0, 160, 0, 80)
endTurnButton.Position = UDim2.new(1, -40, 0.5, 0) -- Same spot as Roll
endTurnButton.AnchorPoint = Vector2.new(1, 0.5)
endTurnButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80) -- Red
endTurnButton.Text = "END TURN"
endTurnButton.Font = Enum.Font.FredokaOne
endTurnButton.TextSize = 24
endTurnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
endTurnButton.Visible = false -- Hidden initially
endTurnButton.Parent = screenGui
Instance.new("UICorner", endTurnButton).CornerRadius = UDim.new(0, 16)

-- 2.5 RESET CAMERA + CHARACTER BUTTON
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(0, 120, 0, 50)
resetButton.Position = UDim2.new(1, -40, 0.5, 100) -- Below Roll button
resetButton.AnchorPoint = Vector2.new(1, 0.5)
resetButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200) -- Blue
resetButton.Text = "🔄 RESET"
resetButton.Font = Enum.Font.FredokaOne
resetButton.TextSize = 18
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Visible = true
resetButton.Parent = screenGui
Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 12)

-- 3. STATUS/LOG LABEL (Small top center)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 300, 0, 30)
statusLabel.Position = UDim2.new(0.5, -60, 0, 10) -- Shift left to make room for timer
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Text = "Waiting..."
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 14
statusLabel.Parent = screenGui
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)

-- 4. TIMER COUNTDOWN LABEL (Next to status)
local timerCountdown = Instance.new("TextLabel")
timerCountdown.Name = "TimerCountdown"
timerCountdown.Size = UDim2.new(0, 80, 0, 30)
timerCountdown.Position = UDim2.new(0.5, 95, 0, 10) -- Right of status
timerCountdown.AnchorPoint = Vector2.new(0, 0)
timerCountdown.BackgroundTransparency = 0.3
timerCountdown.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
timerCountdown.TextColor3 = Color3.fromRGB(255, 200, 50)
timerCountdown.Text = ""
timerCountdown.Font = Enum.Font.FredokaOne
timerCountdown.TextSize = 18
timerCountdown.Visible = false
timerCountdown.Parent = screenGui
Instance.new("UICorner", timerCountdown).CornerRadius = UDim.new(0, 8)

-- Rename for compatibility with logic below
local timerLabel = statusLabel

-- Timer countdown state
local countdownConnection = nil
local countdownRemaining = 0

-- [[ 🔌 CONNECTION ]] --
local rollEvent, updateTurnEvent, resetCamEvent, lockEvent, endTurnEvent, phaseEvent, timerUpdateEvent

-- Rolling state (declared here so event handlers can access it)
local isRolling = false

task.spawn(function()
	rollEvent = ReplicatedStorage:WaitForChild("RollDiceEvent")
	updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")
	timerUpdateEvent = ReplicatedStorage:WaitForChild("TimerUpdateEvent", 5)
	
	-- New Events for Manual Turn
	endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent", 5) 
	-- If it doesn't exist yet, we will create it on server soon, but client code needs to be robust
	if not endTurnEvent then
		-- Fallback if server update lags behind client update
		warn("EndTurnEvent missing, waiting...")
		endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent")
	end
	
	phaseEvent = ReplicatedStorage:WaitForChild("PhaseChangeEvent", 5)

	resetCamEvent = ReplicatedStorage:FindFirstChild("ResetCameraEvent") or Instance.new("BindableEvent")
	lockEvent = ReplicatedStorage:FindFirstChild("CameraLockEvent") or Instance.new("BindableEvent")
	
	timerLabel.Text = "Waiting for game..."
	
	-- Timer Update Event Handler (Countdown from server)
	if timerUpdateEvent then
		timerUpdateEvent.OnClientEvent:Connect(function(seconds, phaseName)
			-- Stop existing countdown
			if countdownConnection then
				countdownConnection:Disconnect()
				countdownConnection = nil
			end
			
			if seconds <= 0 or phaseName == "" then
				-- Hide timer
				timerCountdown.Visible = false
				countdownRemaining = 0
				return
			end
			
			-- Start countdown
			countdownRemaining = seconds
			timerCountdown.Visible = true
			timerCountdown.Text = "⏱ " .. tostring(math.ceil(countdownRemaining)) .. "s"
			
			-- Color based on phase
			if phaseName == "Roll" then
				timerCountdown.TextColor3 = Color3.fromRGB(100, 255, 100) -- Green
			elseif phaseName == "Shop" then
				timerCountdown.TextColor3 = Color3.fromRGB(255, 200, 50) -- Gold
			elseif phaseName == "Encounter" then
				timerCountdown.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red
			else
				timerCountdown.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray
			end
			
			-- Countdown animation
			countdownConnection = RunService.Heartbeat:Connect(function(dt)
				countdownRemaining = countdownRemaining - dt
				if countdownRemaining <= 0 then
					timerCountdown.Visible = false
					if countdownConnection then
						countdownConnection:Disconnect()
						countdownConnection = nil
					end
				else
					timerCountdown.Text = "⏱ " .. tostring(math.ceil(countdownRemaining)) .. "s"
					-- Flash red when low
					if countdownRemaining <= 5 then
						timerCountdown.TextColor3 = Color3.fromRGB(255, math.floor(50 + (countdownRemaining / 5) * 50), 50)
					end
				end
			end)
		end)
	end
	
	-- Event: Update Turn (Start of Turn)
	updateTurnEvent.OnClientEvent:Connect(function(currentName)
		print("🔄 [Client] UpdateTurn received. Current:", currentName, "Me:", player.Name)
		
		if currentName == player.Name then
			-- My turn: Phase (Roll)
			rollButton.Text = "🎲 ROLL DICE!" 
			rollButton.Visible = true
			rollButton.Active = true  -- Ensure button is clickable
			endTurnButton.Visible = false
			
			timerLabel.Text = "YOUR TURN!" 
			timerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			
			-- CRITICAL: Reset rolling state so player can click
			isRolling = false
			print("🎲 [Client] My turn! isRolling reset to false")
		else
			-- Enemy turn
			rollButton.Visible = false
			endTurnButton.Visible = false
			
			timerLabel.Text = "Waiting for " .. currentName
			timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
	
	-- Event: Turn Phase Change (Removed - Timer handles auto-end now)
	-- phaseEvent handler no longer needed since timer auto-ends turns


	-- Event: Roll Result (Animation)
	rollEvent.OnClientEvent:Connect(function(roller, rollResult)
		-- If I am the roller, update my UI
		if roller == player then
			if lockEvent then lockEvent:Fire(true) end
			rollButton.Visible = false 
			timerLabel.Text = "🎲 " .. rollResult .. "!"
		else
			-- If someone else rolled, just update text
			timerLabel.Text = roller.Name .. " rolled " .. rollResult .. "!"
		end

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
		
		if roller == player and lockEvent then lockEvent:Fire(false) end
	end)
end)

-- Assets
local camera = workspace.CurrentCamera

-- [[ 🧠 LOGIC ]] --

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

-- Logic: End Turn Button
endTurnButton.MouseButton1Click:Connect(function()
	if endTurnButton.Visible and endTurnEvent then
		endTurnButton.Visible = false
		timerLabel.Text = "Ending Turn..."
		endTurnEvent:FireServer()
	end
end)

-- Logic: Reset Cam (Old code removed - using resetButton handler below)


-- [[ 🔄 REAL-TIME UPDATER ]] --
task.spawn(function()
	while true do
		for pName, data in pairs(playerFrames) do
			local p = Players:FindFirstChild(pName)
			if p then
				-- Money & Balls
				local ls = p:FindFirstChild("leaderstats")
				if ls then
					local mon = ls:FindFirstChild("Money")
					local bal = ls:FindFirstChild("Pokeballs")
					if mon and data.MoneyLbl then data.MoneyLbl.Text = tostring(mon.Value) end
					if bal and data.BallLbl then data.BallLbl.Text = tostring(bal.Value) end
				end
				
				-- Cards (Count children in Hand folder)
				local hand = p:FindFirstChild("Hand")
				if hand and data.CardLbl then
					data.CardLbl.Text = tostring(#hand:GetChildren())
				end
				
				-- Highlight Active Player
				if timerLabel.Text:find(pName) then -- Weak check, but simple
					data.Stroke.Color = Color3.fromRGB(0, 255, 0)
					data.Stroke.Transparency = 0
				else
					data.Stroke.Transparency = 1
				end
			else
				-- Player left? Remove box
				if data.Box then data.Box:Destroy() end
				playerFrames[pName] = nil
			end
		end
		task.wait(0.5)
	end
end)

-- [[ RESET BUTTON CLICK ]] --
local resetCharEvent = ReplicatedStorage:WaitForChild("ResetCharacterEvent", 10)
resetButton.MouseButton1Click:Connect(function()
	-- 1. Fire ResetCameraEvent to BoardCamera
	if resetCamEvent then 
		resetCamEvent:Fire() 
		print("Reset: ResetCameraEvent fired")
	end
	
	-- 2. Reset Camera type to default (in case BoardCamera doesn't exist)
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid")
	
	-- 3. Fire Server to teleport character to last tile
	if resetCharEvent then
		resetCharEvent:FireServer()
	end
	
	print("Reset: Camera reset and teleport requested")
end)

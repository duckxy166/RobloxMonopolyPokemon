local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))
local SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager"))

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
	box.Size = UDim2.new(0, 290, 0, 130) -- Widen to 290px to fit big slots
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
	avatarImg.Position = UDim2.new(0, 10, 0, 10) -- Top-Left align
	avatarImg.AnchorPoint = Vector2.new(0, 0)
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
	statsRow.Position = UDim2.new(0, 80, 0, 40) -- Brought up closer to name
	statsRow.BackgroundTransparency = 1
	statsRow.Parent = box

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.Parent = statsRow

	local function createStat(iconOrId, valName, color)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, 50, 1, 0) -- Slightly wider for icon
		f.BackgroundTransparency = 1
		f.Parent = statsRow

		local isImage = tostring(iconOrId):match("rbxassetid://")

		if isImage then
			local icn = Instance.new("ImageLabel")
			icn.Size = UDim2.new(0, 24, 0, 24) -- 24px Icon
			icn.Position = UDim2.new(0, 0, 0.5, 0)
			icn.AnchorPoint = Vector2.new(0, 0.5)
			icn.BackgroundTransparency = 1
			icn.Image = iconOrId
			icn.Parent = f
		else
			local icn = Instance.new("TextLabel")
			icn.Size = UDim2.new(0, 20, 1, 0)
			icn.BackgroundTransparency = 1
			icn.Text = iconOrId
			icn.TextSize = 14
			icn.Parent = f
		end

		local val = Instance.new("TextLabel")
		val.Name = "ValueLabel_" .. valName -- Tag for updating
		val.Size = UDim2.new(1, -25, 1, 0)
		val.Position = UDim2.new(0, 25, 0, 0)
		val.BackgroundTransparency = 1
		val.Text = "0"
		val.TextColor3 = color
		val.Font = Enum.Font.GothamBold
		val.TextSize = 14
		val.TextXAlignment = Enum.TextXAlignment.Left
		val.Parent = f
	end

	-- REPLACE THESE IDs WITH YOUR UPLOADED IMAGE IDs
	local COIN_ICON_ID = "rbxassetid://88871535760357" -- Put Coin Image ID here
	local BALL_ICON_ID = "rbxassetid://136940926868953" -- Put Pokeball Image ID here
	local CARD_ICON_ID = "rbxassetid://111087840496480" -- 🃏 Put Card Image ID here

	createStat(COIN_ICON_ID, "Money", Color3.fromRGB(255, 220, 0))
	createStat(CARD_ICON_ID, "Cards", Color3.fromRGB(200, 200, 200)) 
	createStat(BALL_ICON_ID, "Balls", Color3.fromRGB(255, 100, 100))

	-- Status Effects Row (Sleep, Poison, Burn icons)
	local statusEffectsRow = Instance.new("Frame")
	statusEffectsRow.Name = "StatusEffectsRow"
	statusEffectsRow.Size = UDim2.new(1, -80, 0, 18)
	statusEffectsRow.Position = UDim2.new(0, 80, 0, 28) -- Between name and stats
	statusEffectsRow.BackgroundTransparency = 1
	statusEffectsRow.Parent = box

	local effectsLayout = Instance.new("UIListLayout")
	effectsLayout.FillDirection = Enum.FillDirection.Horizontal
	effectsLayout.Padding = UDim.new(0, 4)
	effectsLayout.Parent = statusEffectsRow

	-- Status Pill (New)
	local statusPill = Instance.new("Frame")
	statusPill.Name = "StatusPill"
	statusPill.Size = UDim2.new(0, 100, 0, 24)
	statusPill.Position = UDim2.new(1, -10, 0, 10) -- Top-right of box
	statusPill.AnchorPoint = Vector2.new(1, 0)
	statusPill.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	statusPill.Parent = box

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0) -- Pill shape
	pillCorner.Parent = statusPill

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "StatusLabel"
	statusLbl.Size = UDim2.new(1, 0, 1, 0)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "WAITING"
	statusLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLbl.Font = Enum.Font.FredokaOne
	statusLbl.TextSize = 12
	statusLbl.Parent = statusPill

	-- Pokemon Party Row (6 slots)
	local partyRow = Instance.new("Frame")
	partyRow.Name = "PartyRow"
	partyRow.Size = UDim2.new(1, 0, 0, 50) -- Taller row for 42px slots
	partyRow.Position = UDim2.new(0.5, 0, 1, -5)
	partyRow.AnchorPoint = Vector2.new(0.5, 1)
	partyRow.BackgroundTransparency = 1
	partyRow.Parent = box

	local partyLayout = Instance.new("UIListLayout")
	partyLayout.FillDirection = Enum.FillDirection.Horizontal
	partyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center -- Center the slots
	partyLayout.Padding = UDim.new(0, 4)
	partyLayout.Parent = partyRow

	local partySlots = {}
	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.Size = UDim2.new(0, 42, 0, 42) -- Bigger slots!
		slot.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Darker background
		slot.BackgroundTransparency = 0.3 -- More visible background
		slot.Parent = partyRow
		slot.ClipsDescendants = true 
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)
		
		-- New: Add Stroke
		local slotStroke = Instance.new("UIStroke")
		slotStroke.Color = Color3.fromRGB(255, 255, 255)
		slotStroke.Transparency = 0.8 -- Subtle border
		slotStroke.Thickness = 1
		slotStroke.Parent = slot

		local icon = Instance.new("ImageLabel")
		icon.Name = "IconImg"
		-- FIX: Adjusted size to fit within the box instead of zooming in too much
		icon.Size = UDim2.new(0.9, 0, 0.9, 0) 
		-- FIX: Centered position
		icon.Position = UDim2.new(0.5, 0, 0.5, 0) 
		icon.AnchorPoint = Vector2.new(0.5, 0.5) 
		icon.BackgroundTransparency = 1
		icon.Image = ""
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = slot

		-- Status Overlay (Text)
		local statusOv = Instance.new("TextLabel")
		statusOv.Name = "StatusOverlay"
		statusOv.Size = UDim2.new(1, 0, 1, 0)
		statusOv.Position = UDim2.new(0, 0, 0, 0)
		statusOv.BackgroundTransparency = 1
		statusOv.Text = "X"
		statusOv.TextColor3 = Color3.fromRGB(255, 50, 50)
		statusOv.Font = Enum.Font.FredokaOne
		statusOv.TextSize = 24
		statusOv.Visible = false
		statusOv.ZIndex = 2
		statusOv.Parent = slot

		partySlots[i] = slot
	end

	-- Store for updates
	playerFrames[targetPlayer.Name] = {
		Box = box,
		Stroke = uiStroke,
		MoneyLbl = box:FindFirstChild("ValueLabel_Money", true),
		CardLbl = box:FindFirstChild("ValueLabel_Cards", true),
		BallLbl = box:FindFirstChild("ValueLabel_Balls", true),
		PartySlots = partySlots,
		StatusPill = statusPill,
		StatusLabel = statusLbl,
		StatusEffectsRow = statusEffectsRow
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

-- Status Effect Icons Config
local STATUS_EFFECTS_CONFIG = {
	Sleep = {icon = "💤", color = Color3.fromRGB(100, 150, 255)},
	Poison = {icon = "☠️", color = Color3.fromRGB(200, 100, 255)},
	Burn = {icon = "🔥", color = Color3.fromRGB(255, 150, 50)}
}

-- Create/Update Status Effect Icon
local function updateStatusIcon(statusRow, statusType, turns)
	local config = STATUS_EFFECTS_CONFIG[statusType]
	if not config then return end

	local existing = statusRow:FindFirstChild("Status_" .. statusType)

	if turns <= 0 then
		-- Remove icon if turns = 0
		if existing then existing:Destroy() end
		return
	end

	-- Create or update icon
	local iconFrame = existing
	if not iconFrame then
		iconFrame = Instance.new("Frame")
		iconFrame.Name = "Status_" .. statusType
		iconFrame.Size = UDim2.new(0, 32, 0, 16)
		iconFrame.BackgroundColor3 = config.color
		iconFrame.BackgroundTransparency = 0.3
		iconFrame.Parent = statusRow
		Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 6)

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Parent = iconFrame
	end

	local lbl = iconFrame:FindFirstChild("Label")
	if lbl then
		lbl.Text = config.icon .. turns
	end
end

-- Update Pokemon party icons for a player
local function updatePartyIcons(targetPlayer)
	local frame = playerFrames[targetPlayer.Name]
	if not frame or not frame.PartySlots then return end

	local inventory = targetPlayer:FindFirstChild("PokemonInventory")
	if not inventory then return end

	local pokemons = inventory:GetChildren()
	for i = 1, 6 do
		local slot = frame.PartySlots[i]
		local icon = slot:FindFirstChild("IconImg")
		if icon then
			if pokemons[i] then
				local pokeName = pokemons[i].Name
				local dbData = PokemonDB.GetPokemon(pokeName)
				if dbData and dbData.Icon then
					icon.Image = dbData.Icon
				else
					icon.Image = "rbxassetid://0" -- Placeholder
				end
				-- Check Status
				local status = pokemons[i]:GetAttribute("Status")
				local overlay = slot:FindFirstChild("StatusOverlay")

				if status == "Dead" then
					icon.ImageTransparency = 0.7 -- Heavy fade
					icon.ImageColor3 = Color3.fromRGB(100, 100, 100) -- Greyed out
					if overlay then overlay.Visible = true end
				else
					icon.ImageTransparency = 0
					icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
					if overlay then overlay.Visible = false end
				end
				slot.BackgroundTransparency = 0.3
			else
				icon.Image = ""
				slot.BackgroundTransparency = 0.7
				local overlay = slot:FindFirstChild("StatusOverlay")
				if overlay then overlay.Visible = false end
			end
		end
	end
end

-- Update Player Status Visuals
local function updatePlayerStatus(pName, statusType, customText)
	local data = playerFrames[pName]
	if not data then return end

	local box = data.Box
	local pill = data.StatusPill
	local lbl = data.StatusLabel
	local stroke = data.Stroke

	if not (box and pill and lbl and stroke) then return end

	-- Defaults
	local pillColor = Color3.fromRGB(80, 80, 80)
	local text = "WAITING"
	local borderColor = Color3.fromRGB(255, 255, 255)
	local strokeThickness = 2

	if statusType == "Active" then
		pillColor = Color3.fromRGB(255, 200, 50) -- Gold/Orange
		text = customText or "THINKING..."
		borderColor = Color3.fromRGB(255, 220, 0)
		strokeThickness = 4
	elseif statusType == "MyTurn" then
		pillColor = Color3.fromRGB(50, 200, 100) -- Green
		text = customText or "YOUR TURN"
		borderColor = Color3.fromRGB(100, 255, 100)
		strokeThickness = 4
	else
		-- Waiting
		pillColor = Color3.fromRGB(60, 60, 70)
		text = "WAITING"
		borderColor = Color3.fromRGB(100, 100, 120)
		strokeThickness = 2
	end

	-- Animate changes
	TweenService:Create(pill, TweenInfo.new(0.3), {BackgroundColor3 = pillColor}):Play()
	lbl.Text = text
	TweenService:Create(stroke, TweenInfo.new(0.3), {Color = borderColor, Thickness = strokeThickness}):Play()
end

-- Listen for inventory changes for all players
local function setupInventoryListener(targetPlayer)
	local inventory = targetPlayer:WaitForChild("PokemonInventory", 10)
	if inventory then
		updatePartyIcons(targetPlayer)

		-- 1. Inventory Structure Change
		inventory.ChildAdded:Connect(function(child)
			updatePartyIcons(targetPlayer)
			-- Listen to attributes if new child
			child:GetAttributeChangedSignal("Status"):Connect(function()
				updatePartyIcons(targetPlayer)
			end)
		end)
		inventory.ChildRemoved:Connect(function() updatePartyIcons(targetPlayer) end)

		-- 2. Initial Bind for Existing
		for _, child in ipairs(inventory:GetChildren()) do
			child:GetAttributeChangedSignal("Status"):Connect(function()
				updatePartyIcons(targetPlayer)
			end)
		end
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

-- Phase Update Logic (Local Player Only)
local PhaseUpdateEvent = ReplicatedStorage:WaitForChild("PhaseUpdateEvent", 5)
if PhaseUpdateEvent then
	PhaseUpdateEvent.OnClientEvent:Connect(function(phase, message)
		-- Update my own status box
		updatePlayerStatus(player.Name, "MyTurn", phase:upper() .. " PHASE")
	end)
end

-- Status Changed Event (Listen for Sleep/Poison/Burn status updates)
local StatusChangedEvent = ReplicatedStorage:WaitForChild("StatusChangedEvent", 5)
if StatusChangedEvent then
	StatusChangedEvent.OnClientEvent:Connect(function(userId, statusType, turns)
		-- Find player frame by userId
		for pName, data in pairs(playerFrames) do
			local p = Players:FindFirstChild(pName)
			if p and p.UserId == userId then
				local statusRow = data.StatusEffectsRow
				if statusRow then
					updateStatusIcon(statusRow, statusType, turns)
				end
				break
			end
		end
	end)
end



-- 2. END TURN BUTTON
local endTurnButton = Instance.new("TextButton")
endTurnButton.Name = "EndTurnButton"
endTurnButton.Size = UDim2.new(0, 160, 0, 80)
endTurnButton.Position = UDim2.new(1, -40, 0.5, 0)
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
resetButton.Position = UDim2.new(1, -40, 0.5, 100) -- Below End Turn button
resetButton.AnchorPoint = Vector2.new(1, 0.5)
resetButton.BackgroundColor3 = Color3.fromRGB(100, 100, 200) -- Blue
resetButton.Text = "🔄 RESET"
resetButton.Font = Enum.Font.FredokaOne
resetButton.TextSize = 18
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.Visible = true
resetButton.Parent = screenGui
Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 12)

-- NOTE: Status/Timer labels removed - PhaseUIController handles phase display now

-- [[ 🔌 CONNECTION ]] --
local rollEvent, updateTurnEvent, resetCamEvent, lockEvent, endTurnEvent, notifyEvent

local StarterGui = game:GetService("StarterGui")



task.spawn(function()
	rollEvent = ReplicatedStorage:WaitForChild("RollDiceEvent")
	updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")

	-- New Events for Manual Turn
	endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent", 5)
	if not endTurnEvent then
		warn("EndTurnEvent missing, waiting...")
	end

	notifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent", 5)
	if notifyEvent then
		notifyEvent.OnClientEvent:Connect(function(msg)
			print("🔔 Notification:", msg)
			StarterGui:SetCore("SendNotification", {
				Title = "Game Notification";
				Text = msg;
				Duration = 3;
			})
		end)
		endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent")
	end

	resetCamEvent = ReplicatedStorage:FindFirstChild("ResetCameraEvent") or Instance.new("BindableEvent")
	lockEvent = ReplicatedStorage:FindFirstChild("CameraLockEvent") or Instance.new("BindableEvent")



	-- CATCH SOUND
	local catchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent", 5)
	if catchEvent then
		catchEvent.OnClientEvent:Connect(function()
			local s = Instance.new("Sound", workspace)
			s.SoundId = "rbxassetid://90144356226455" -- Land sound
			s.PlayOnRemove = true
			s:Destroy()
		end)
	end

	-- Event: Update Turn (Start of Turn) - Only handle end turn button visibility
	updateTurnEvent.OnClientEvent:Connect(function(currentName)
		print("🔄 [Client] UpdateTurn received. Current:", currentName, "Me:", player.Name)

		-- Update all players status
		for pName, _ in pairs(playerFrames) do
			if pName == currentName then
				if pName == player.Name then
					updatePlayerStatus(pName, "MyTurn", "YOUR TURN")
				else
					updatePlayerStatus(pName, "Active", "PLAYING")
				end
			else
				updatePlayerStatus(pName, "Waiting")
			end
		end

		if currentName == player.Name then
			-- My turn - PhaseUIController handles phase display
			endTurnButton.Visible = false
			print("🎲 [Client] My turn!")
		else
			-- Enemy turn
			endTurnButton.Visible = false
		end
	end)

	-- Event: Roll Result (Animation)
	rollEvent.OnClientEvent:Connect(function(roller, rollResult)
		-- If I am the roller, lock camera
		if roller == player then
			if lockEvent then lockEvent:Fire(true) end
		end

		local dice
		local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
		local camera = workspace.CurrentCamera

		if diceTemplate then dice = diceTemplate:Clone() else dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) end
		dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false

		local LAND_SOUND_ID = "rbxassetid://90144356226455" -- Landing Sound

		local function playSound(id)
			local s = Instance.new("Sound", workspace)
			s.SoundId = id
			s.PlayOnRemove = true
			s:Destroy()
		end

		-- Spin Animation
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not dice.Parent then connection:Disconnect() return end
			local cf = camera.CFrame; local pos = cf + (cf.LookVector * 10)
			dice.CFrame = CFrame.new(pos.Position) * CFrame.Angles(math.rad(os.clock()*700), math.rad(os.clock()*500), math.rad(os.clock()*600))
		end)

		task.wait(0.25)
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

		-- Server now sends base roll (1-6), bonus is handled separately
		local safeRoll = rollResult
		if not ROTATION_OFFSETS[safeRoll] then safeRoll = 1 end

		-- Play Land Sound
		playSound(LAND_SOUND_ID)

		local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[safeRoll]
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



-- Logic: End Turn Button
endTurnButton.MouseButton1Click:Connect(function()
	if endTurnButton.Visible and endTurnEvent then
		endTurnButton.Visible = false
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
					local cardCount = #hand:GetChildren()
					local handLimit = (p:GetAttribute("Job") == "Trainer") and 6 or 5
					data.CardLbl.Text = cardCount .. "/" .. handLimit
				end

				-- NOTE: Player highlight now handled by UIHelpers in TurnManager
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
	SoundManager.Play("ResetClick") -- 🔊 Sound effect
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
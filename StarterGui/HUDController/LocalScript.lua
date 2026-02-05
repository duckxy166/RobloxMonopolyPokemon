local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))

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

	createStat(COIN_ICON_ID, "Money", Color3.fromRGB(255, 220, 0))
	createStat("C", "Cards", Color3.fromRGB(200, 200, 200)) -- Keep Cards as Text 'C' or change if needed
	createStat(BALL_ICON_ID, "Balls", Color3.fromRGB(255, 100, 100))

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
		slot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		slot.BackgroundTransparency = 0.5
		slot.Parent = partyRow
		slot.ClipsDescendants = true -- Clip the zoomed in image
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)

		local icon = Instance.new("ImageLabel")
		icon.Name = "IconImg"
		icon.Size = UDim2.new(2, 0, 2, 0) -- Zoom in (130%)
		icon.Position = UDim2.new(0.5, 0, -0.1, 0) -- Center
		icon.AnchorPoint = Vector2.new(0.5, 0.5) -- Center Anchor
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

-- NOTE: Status/Timer labels removed - PhaseUIController handles phase display now

-- [[ 🔌 CONNECTION ]] --
local rollEvent, updateTurnEvent, resetCamEvent, lockEvent, endTurnEvent

-- Rolling state (declared here so event handlers can access it)
local isRolling = false

task.spawn(function()
	rollEvent = ReplicatedStorage:WaitForChild("RollDiceEvent")
	updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")

	-- New Events for Manual Turn
	endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent", 5)
	if not endTurnEvent then
		warn("EndTurnEvent missing, waiting...")
		endTurnEvent = ReplicatedStorage:WaitForChild("EndTurnEvent")
	end

	resetCamEvent = ReplicatedStorage:FindFirstChild("ResetCameraEvent") or Instance.new("BindableEvent")
	lockEvent = ReplicatedStorage:FindFirstChild("CameraLockEvent") or Instance.new("BindableEvent")

	-- Listen for Battle Start to hide HUD Roll Button
	local battleStartEvent = ReplicatedStorage:WaitForChild("BattleStartEvent", 5)
	if battleStartEvent then
		battleStartEvent.OnClientEvent:Connect(function()
			print("⚔️ [HUD] Battle Started -> Hiding Roll Button")
			rollButton.Visible = false
		end)
	end

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

	-- Event: Update Turn (Start of Turn) - Only handle roll button visibility
	updateTurnEvent.OnClientEvent:Connect(function(currentName)
		print("🔄 [Client] UpdateTurn received. Current:", currentName, "Me:", player.Name)

		if currentName == player.Name then
			-- My turn - PhaseUIController handles phase display
			-- Only show roll button when in Roll phase (PhaseUIController manages this too)
			rollButton.Visible = false -- Hidden by default, PhaseUIController shows its own roll button
			endTurnButton.Visible = false
			isRolling = false
			print("🎲 [Client] My turn! isRolling reset to false")
		else
			-- Enemy turn
			rollButton.Visible = false
			endTurnButton.Visible = false
		end
	end)

	-- Event: Roll Result (Animation)
	rollEvent.OnClientEvent:Connect(function(roller, rollResult)
		-- If I am the roller, update my UI
		if roller == player then
			if lockEvent then lockEvent:Fire(true) end
			rollButton.Visible = false
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

-- Logic: Roll Button (backup - PhaseUIController has main roll button)
rollButton.MouseButton1Click:Connect(function()
	if isRolling then return end
	if rollButton.Text == "WAIT..." or rollButton.Text == "Loading..." then return end

	isRolling = true
	rollButton.Visible = false

	if rollEvent then rollEvent:FireServer() end
end)

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
					data.CardLbl.Text = tostring(#hand:GetChildren())
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
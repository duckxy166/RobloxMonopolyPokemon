local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local layer = player:WaitForChild("PlayerGui")

-- [[ CLEANUP LEGACY ]] --
-- Hide the old MainFrame if this script is still sitting inside the old StarterGui structure
if script.Parent and script.Parent:FindFirstChild("MainFrame") then
	script.Parent.MainFrame.Visible = false
end

-- [[ 1. UI CONSTRUCTION (PURE SCRIPT) ]] --
local gui = Instance.new("ScreenGui")
gui.Name = "EncounterUI_Scripted"
gui.ResetOnSpawn = false
gui.Enabled = false -- Hidden by default
gui.Parent = layer

-- MAIN BANNER CONTAINER
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 500, 0, 140) -- Fixed size for stability
mainFrame.ClipsDescendants = false -- Allow pop-out if we want, but usually keep false for clean UI borders
mainFrame.Position = UDim2.new(0.5, 0, 0.95, -10) -- Bottom Center, slight padding
mainFrame.AnchorPoint = Vector2.new(0.5, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40) -- Dark Slate
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Stroke (Cyan Glow Border)
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 180, 255) 
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- Corner
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 16)
uiCorner.Parent = mainFrame

-- === LEFT: POKEMON IMAGE ===
local imgContainer = Instance.new("Frame")
imgContainer.Name = "ImgContainer"
imgContainer.Size = UDim2.new(0, 130, 0, 130) -- Reduced slightly to fit inside 140px height with padding
imgContainer.Position = UDim2.new(0, 20, 0.5, 0) -- Moved right slightly
imgContainer.AnchorPoint = Vector2.new(0, 0.5) -- Vertically centered
imgContainer.BackgroundTransparency = 1
imgContainer.ZIndex = 2
imgContainer.Parent = mainFrame

local imgLabel = Instance.new("ImageLabel")
imgLabel.Name = "PokemonImage"
imgLabel.Size = UDim2.new(1, 0, 1, 0)
imgLabel.BackgroundTransparency = 1
imgLabel.Image = "" 
imgLabel.ScaleType = Enum.ScaleType.Fit -- Keep aspect ratio!
imgLabel.Visible = false 
imgLabel.Parent = imgContainer

-- === CENTER: INFO & STATS ===
local centerPanel = Instance.new("Frame")
centerPanel.Name = "CenterPanel"
centerPanel.Size = UDim2.new(0.45, 0, 0.8, 0)
centerPanel.Position = UDim2.new(0.35, 0, 0.5, 0)
centerPanel.AnchorPoint = Vector2.new(0, 0.5)
centerPanel.BackgroundTransparency = 1
centerPanel.Parent = mainFrame

-- Name and Type Row
local nameRow = Instance.new("Frame")
nameRow.Size = UDim2.new(1, 0, 0, 30)
nameRow.BackgroundTransparency = 1
nameRow.Parent = centerPanel

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(0, 10, 1, 0)
nameLabel.AutomaticSize = Enum.AutomaticSize.X
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Pikachu"
nameLabel.TextColor3 = Color3.fromRGB(0, 230, 255)
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 24
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = nameRow

-- Dummy Type Badges (Visual Only)
local typeBadge = Instance.new("Frame")
typeBadge.Name = "TypeBadge"
typeBadge.Size = UDim2.new(0, 50, 0, 20)
typeBadge.Position = UDim2.new(0, 0, 0, 5) -- Will adjust by Layout
typeBadge.BackgroundColor3 = Color3.fromRGB(120, 200, 100) -- Greenish
typeBadge.BorderSizePixel = 0
typeBadge.Parent = nameRow

local typeRound = Instance.new("UICorner"); typeRound.Parent = typeBadge; typeRound.CornerRadius = UDim.new(1, 0)
local typeLayout = Instance.new("UIListLayout"); typeLayout.Parent = nameRow; typeLayout.FillDirection = Enum.FillDirection.Horizontal; typeLayout.Padding = UDim.new(0, 10); typeLayout.VerticalAlignment = Enum.VerticalAlignment.Center

-- Ability Text (Placeholder)
local abilityLabel = Instance.new("TextLabel")
abilityLabel.Name = "AbilityLabel"
abilityLabel.Size = UDim2.new(1, 0, 0, 20)
abilityLabel.Position = UDim2.new(0, 0, 0, 35)
abilityLabel.BackgroundTransparency = 1
abilityLabel.Text = "No Ability"
abilityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
abilityLabel.Font = Enum.Font.Gotham
abilityLabel.TextSize = 14
abilityLabel.TextXAlignment = Enum.TextXAlignment.Left
abilityLabel.Parent = centerPanel

-- === RIGHT: STATS & REWARDS ===
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(0.25, 0, 0.8, 0)
rightPanel.Position = UDim2.new(0.98, 0, 0.5, 0)
rightPanel.AnchorPoint = Vector2.new(1, 0.5)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = mainFrame

-- 1. Reward (Gold)
local rewardFrame = Instance.new("Frame")
rewardFrame.Size = UDim2.new(1, 0, 0, 25)
rewardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
rewardFrame.BorderSizePixel = 0
rewardFrame.Parent = rightPanel

local rewardCorner = Instance.new("UICorner"); rewardCorner.Parent = rewardFrame; rewardCorner.CornerRadius = UDim.new(0, 6)

local rewardIcon = Instance.new("TextLabel")
rewardIcon.Size = UDim2.new(0, 25, 1, 0)
rewardIcon.BackgroundTransparency = 1
rewardIcon.Text = "🟡"
rewardIcon.TextSize = 14
rewardIcon.Parent = rewardFrame

local rewardText = Instance.new("TextLabel")
rewardText.Size = UDim2.new(1, -30, 1, 0)
rewardText.Position = UDim2.new(0, 30, 0, 0)
rewardText.BackgroundTransparency = 1
rewardText.Text = "5 Coins"
rewardText.TextColor3 = Color3.fromRGB(255, 255, 255)
rewardText.Font = Enum.Font.GothamBold
rewardText.TextSize = 12
rewardText.TextXAlignment = Enum.TextXAlignment.Left
rewardText.Parent = rewardFrame

-- 2. Stats Rows (Power / HP)
-- Helper for Stat Bar
local function createStatRow(parent, label, color, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 18)
	row.Position = UDim2.new(0, 0, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 50, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -55, 0, 6)
	barBg.Position = UDim2.new(0, 55, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	barBg.BorderSizePixel = 0
	barBg.Parent = row

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0.5, 0, 1, 0) -- Dynamic
	barFill.BackgroundColor3 = color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = barBg
	local corner2 = Instance.new("UICorner"); corner2.CornerRadius = UDim.new(1, 0); corner2.Parent = barFill

	return barFill
end

local powerBar = createStatRow(rightPanel, "Power", Color3.fromRGB(255, 80, 80), 35)
local hpBar = createStatRow(rightPanel, "HP", Color3.fromRGB(80, 180, 255), 60)

-- === ACTION BUTTONS (Floating Top Right or Integrated?) ===
-- Let's float them to the right of the main frame or overlay on right side
-- Actually, let's put them on the top-right corner of the whole screen to keep the banner clean?
-- Or integrated on the Far Rght of the panel.
-- Let's squeeze them into the RightPanel below stats.
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(1, 0, 0, 30)
buttonsFrame.Position = UDim2.new(0, 0, 1, -30)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = rightPanel

local catchBtn = Instance.new("TextButton")
catchBtn.Name = "CatchButton"
catchBtn.Size = UDim2.new(0, 60, 1, 0)
catchBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
catchBtn.Text = "CATCH"
catchBtn.Font = Enum.Font.GothamBold; catchBtn.TextSize = 10; catchBtn.TextColor3 = Color3.new(1,1,1)
catchBtn.Parent = buttonsFrame; Instance.new("UICorner", catchBtn).CornerRadius = UDim.new(0, 4)

local runBtn = Instance.new("TextButton")
runBtn.Name = "RunButton"
runBtn.Size = UDim2.new(0, 40, 1, 0)
runBtn.Position = UDim2.new(1, -40, 0, 0)
runBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
runBtn.Text = "RUN"
runBtn.Font = Enum.Font.GothamBold; runBtn.TextSize = 10; runBtn.TextColor3 = Color3.new(1,1,1)
runBtn.Parent = buttonsFrame; Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 4)

-- Hidden Rarity Label for logic reuse
local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name = "RarityLabel"
rarityLabel.Visible = false
rarityLabel.Parent = mainFrame

local ballsLabel = Instance.new("TextLabel"); ballsLabel.Name = "BallsLabel"; ballsLabel.Visible = false; ballsLabel.Parent = mainFrame


-- [[ Unused Elements Cleanup ]] --
-- Removing separate TitleLabel since we integrated it or simplified it
-- We can reuse nameLabel or add a small status tag if needed. I'll omit TitleLabel for cleaner look.



-- [[ 2. LOGIC ]] --

local encounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent")
local catchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local runEvent = ReplicatedStorage:WaitForChild("RunEvent")
local updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")
local catchAnimDoneEvent = ReplicatedStorage:WaitForChild("CatchAnimationDoneEvent")
local sentCatchDone = false

local currentPokeData = nil 
local DIFFICULTY_TEXT = { ["Common"]="2+", ["Rare"]="4+", ["Legendary"]="6!" }
local ROTATION_OFFSETS = {
	[1] = CFrame.Angles(0, 0, 0),
	[2] = CFrame.Angles(math.rad(-90), 0, 0),
	[3] = CFrame.Angles(0, math.rad(90), 0),
	[4] = CFrame.Angles(0, math.rad(-90), 0),
	[5] = CFrame.Angles(math.rad(90), 0, 0),
	[6] = CFrame.Angles(0, math.rad(180), 0)
}
local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
local camera = workspace.CurrentCamera

-- 1. Handle Encounter Start

encounterEvent.OnClientEvent:Connect(function(activePlayer, pokeData)
	sentCatchDone = false
	currentPokeData = pokeData 

	gui.Enabled = true
	mainFrame.Visible = false

	if activePlayer == player then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local t = 0
			while t < 1 and hum.MoveDirection.Magnitude > 0.01 do
				t += RunService.Heartbeat:Wait()
			end
		end
	end

	mainFrame.Visible = true

	-- Spectator check
	local isMe = (activePlayer == player)

	if isMe then
		nameLabel.Text = pokeData.Name
		catchBtn.Visible = true
		runBtn.Visible = true

		-- Reset button state
		catchBtn.Text = "CATCH"
		catchBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	else
		nameLabel.Text = "SPECTATING: " .. activePlayer.Name
		rarityLabel.Text = "Found " .. pokeData.Name
		catchBtn.Visible = false
		runBtn.Visible = false
	end

	-- Image
	print("🖼️ Encounter UI: Loading image for " .. pokeData.Name)
	print("   Icon Field: " .. tostring(pokeData.Icon))
	print("   Image Field: " .. tostring(pokeData.Image))

	if pokeData.Image and pokeData.Image ~= "" and pokeData.Image ~= "rbxassetid://0" then
		imgLabel.Visible = true 
		imgLabel.Image = pokeData.Image
		print("   ✅ Set Image to: " .. pokeData.Image)
	else
		imgLabel.Visible = false 
		warn("   ⚠️ No valid Image ID found (Check PokemonDB.Image)")
	end

	-- Update Type Badge (Random Simulation / Future Proof)
	-- In real DB, you'd pull this from pokeData.Type
	local simTypes = {
		["Common"] = {Color3.fromRGB(168, 168, 120)}, -- Normal
		["Rare"] = {Color3.fromRGB(240, 128, 48)},   -- Fire
		["Legendary"] = {Color3.fromRGB(160, 64, 160)}, -- Ghost/Dragon
	}
	typeBadge.BackgroundColor3 = simTypes[pokeData.Rarity] and simTypes[pokeData.Rarity][1] or Color3.fromRGB(120, 200, 100)

	-- Update Stats Bars (Simulation based on Rarity)
	local fillAmt = 0.3
	if pokeData.Rarity == "Rare" then fillAmt = 0.6 end
	if pokeData.Rarity == "Legendary" then fillAmt = 0.9 end

	powerBar.Size = UDim2.new(fillAmt, 0, 1, 0)
	hpBar.Size = UDim2.new(fillAmt + 0.1, 0, 1, 0) -- HP slightly higher

	-- Update Reward & Ability
	if pokeData.Rarity == "Legendary" then
		abilityLabel.Text = "Pressure"
		rewardText.Text = "100 Coins"
	else
		abilityLabel.Text = "No Ability"
		if pokeData.Rarity == "Rare" then rewardText.Text = "20 Coins" else rewardText.Text = "5 Coins" end
	end

	-- Keep Ball Logic for logic, but maybe show in name label?
	-- Or just rely on separate HUD. But Encounter UI should probably show it too?
	-- In reference image, ball count isn't explicitly in the banner, it's in the corner HUD.
	-- But let's keep it safe.
	local playerBalls = 0
	if player.leaderstats and player.leaderstats:FindFirstChild("Pokeballs") then
		playerBalls = player.leaderstats.Pokeballs.Value
	end
	ballsLabel.Text = "Balls: " .. playerBalls

	if isMe and playerBalls <= 0 then
		catchBtn.Text = "NO BALLS!"
		catchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

-- 2. Catch Button Logic
catchBtn.MouseButton1Click:Connect(function()
	if not currentPokeData then return end
	if catchBtn.Text == "NO BALLS!" then return end -- Prevent clicking if no balls

	catchBtn.Visible = false
	nameLabel.Text = "Throwing..."
	catchEvent:FireServer(currentPokeData)
end)

-- 3. Catch Result (Server feedback)
catchEvent.OnClientEvent:Connect(function(activePlayer, success, diceRoll, target, isFinished)
	-- Determine if we are the active player
	local isMe = (activePlayer == player)

	-- Animation Text
	local rollText = "Throwing..."
	if not isMe then
		rollText = activePlayer.Name .. " is throwing..."
		gui.Enabled = true -- Ensure spectators see it
	end
	nameLabel.Text = rollText

	-- Create Dice Animation
	local dice
	if diceTemplate then dice = diceTemplate:Clone() else dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) end
	dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not dice.Parent then connection:Disconnect() return end
		local cf = camera.CFrame; local pos = cf + (cf.LookVector * 6)
		dice.CFrame = CFrame.new(pos.Position) * CFrame.Angles(math.rad(os.clock()*700), math.rad(os.clock()*500), math.rad(os.clock()*600))
	end)

	task.wait(2) -- Rolling time
	connection:Disconnect()

	-- Show Result Face
	local finalCF = camera.CFrame
	local dicePos = (finalCF + finalCF.LookVector * 5).Position
	local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[diceRoll]
	})
	tw:Play()

	task.wait(1.5) 
	dice:Destroy()

	-- Show Text Result
	local who = (activePlayer and activePlayer.Name) or "Someone"
	if success then
		nameLabel.Text = who .. " CAUGHT IT!"
		nameLabel.TextColor3 = Color3.new(0, 1, 0)
	else
		nameLabel.Text = who .. " FAILED!"
		nameLabel.TextColor3 = Color3.new(1, 0, 0)
	end

	-- Update remaining balls (active player only)
	if isMe and player.leaderstats and player.leaderstats:FindFirstChild("Pokeballs") then
		local remainingBalls = player.leaderstats.Pokeballs.Value
		ballsLabel.Text = "Balls: " .. remainingBalls
		if remainingBalls <= 0 and not success then
			isFinished = true
			nameLabel.Text = "OUT OF BALLS!"
		end
	end

	task.wait(2) -- Wait for text read

	if isFinished then
		-- ✅ send only once, only from the active player
		if isMe and not sentCatchDone then
			sentCatchDone = true
			catchAnimDoneEvent:FireServer()
		end

		gui.Enabled = false
		nameLabel.Text = ""
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
	else
		-- Try again
		if isMe then
			nameLabel.Text = currentPokeData.Name 
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			catchBtn.Visible = true 
			catchBtn.Text = "TRY AGAIN"
		else
			nameLabel.Text = activePlayer.Name .. " is trying again..."
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
		end
	end
end)

-- 4. Escape Button Logic
runBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false
	runEvent:FireServer() 
end)

-- 5. Handle Run Event (Spectators too)
runEvent.OnClientEvent:Connect(function(activePlayer)
	nameLabel.Text = activePlayer.Name .. " ran away!"
	task.wait(2)
	gui.Enabled = false
	nameLabel.Text = "" 
end)

-- 6. Cleanup on New Turn
updateTurnEvent.OnClientEvent:Connect(function()
	if gui.Enabled then
		gui.Enabled = false
		print("[UI] Force closed Encounter due to turn change")
	end
end)
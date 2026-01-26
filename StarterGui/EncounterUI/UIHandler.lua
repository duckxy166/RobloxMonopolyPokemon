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

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.5, 0, 0.2, 0) -- Banner style: Wide and short
mainFrame.Position = UDim2.new(0.5, 0, 0.95, 0) -- Bottom Center
mainFrame.AnchorPoint = Vector2.new(0.5, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40) -- Dark sleek slate
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Stroke
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(0, 200, 255) -- Cyan glow
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- Gradient
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
}
gradient.Rotation = 90
gradient.Parent = mainFrame

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 16)
uiCorner.Parent = mainFrame

-- Layout Container: Left (Image), Middle (Info), Right (Actions)

-- 1. POKEMON IMAGE (Left sticking out)
local imgLabel = Instance.new("ImageLabel")
imgLabel.Name = "PokemonImage"
imgLabel.Size = UDim2.new(0, 150, 0, 150)
imgLabel.Position = UDim2.new(0.05, 0, 0.5, 0) -- Overhanging slightly
imgLabel.AnchorPoint = Vector2.new(0, 0.5) 
imgLabel.BackgroundTransparency = 1
imgLabel.Image = "" -- Set dynamically
imgLabel.Visible = false -- Default hidden
imgLabel.ZIndex = 5 -- On top
imgLabel.Parent = mainFrame

-- 2. INFO SECTION (Middle)
local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoSection"
infoFrame.Size = UDim2.new(0.5, 0, 1, 0)
infoFrame.Position = UDim2.new(0.25, 0, 0, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = mainFrame

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
nameLabel.Position = UDim2.new(0, 0, 0.1, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Pikachu"
nameLabel.TextColor3 = Color3.fromRGB(0, 230, 255) -- Cyan highlight
nameLabel.Font = Enum.Font.FredokaOne
nameLabel.TextSize = 28
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = infoFrame

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name = "RarityLabel"
rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
rarityLabel.Position = UDim2.new(0, 0, 0.5, 0)
rarityLabel.BackgroundTransparency = 1
rarityLabel.Text = "Rare - Need 4+"
rarityLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
rarityLabel.Font = Enum.Font.GothamMedium
rarityLabel.TextSize = 16
rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
rarityLabel.Parent = infoFrame

local ballsLabel = Instance.new("TextLabel")
ballsLabel.Name = "BallsLabel"
ballsLabel.Size = UDim2.new(1, 0, 0.2, 0)
ballsLabel.Position = UDim2.new(0, 0, 0.75, 0)
ballsLabel.BackgroundTransparency = 1
ballsLabel.Text = "Balls: 5"
ballsLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Red for balls
ballsLabel.Font = Enum.Font.GothamBold
ballsLabel.TextSize = 14
ballsLabel.TextXAlignment = Enum.TextXAlignment.Left
ballsLabel.Parent = infoFrame

-- 3. ACTIONS SECTION (Right)
local actionFrame = Instance.new("Frame")
actionFrame.Name = "ActionSection"
actionFrame.Size = UDim2.new(0.2, 0, 1, 0)
actionFrame.Position = UDim2.new(0.78, 0, 0, 0)
actionFrame.BackgroundTransparency = 1
actionFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = actionFrame

local catchBtn = Instance.new("TextButton")
catchBtn.Name = "CatchButton"
catchBtn.Size = UDim2.new(1, 0, 0, 45)
catchBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94) -- Green
catchBtn.Text = "CATCH"
catchBtn.Font = Enum.Font.GothamBlack
catchBtn.TextSize = 18
catchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
catchBtn.Parent = actionFrame

local catchCorner = Instance.new("UICorner")
catchCorner.CornerRadius = UDim.new(0, 6)
catchCorner.Parent = catchBtn

local runBtn = Instance.new("TextButton")
runBtn.Name = "RunButton"
runBtn.Size = UDim2.new(1, 0, 0, 35)
runBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68) -- Red
runBtn.Text = "RUN"
runBtn.Font = Enum.Font.GothamBold
runBtn.TextSize = 14
runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runBtn.Parent = actionFrame

local runCorner = Instance.new("UICorner")
runCorner.CornerRadius = UDim.new(0, 6)
runCorner.Parent = runBtn


-- [[ Unused Elements Cleanup ]] --
-- Removing separate TitleLabel since we integrated it or simplified it
-- We can reuse nameLabel or add a small status tag if needed. I'll omit TitleLabel for cleaner look.



-- [[ 2. LOGIC ]] --

local encounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent")
local catchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local runEvent = ReplicatedStorage:WaitForChild("RunEvent")
local updateTurnEvent = ReplicatedStorage:WaitForChild("UpdateTurnEvent")

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
	currentPokeData = pokeData 
	
	gui.Enabled = true
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
	if pokeData.Image and pokeData.Image ~= "" then
		imgLabel.Visible = true 
		imgLabel.Image = pokeData.Image
	else
		imgLabel.Visible = false 
	end

	-- Rarity
	local diffText = DIFFICULTY_TEXT[pokeData.Rarity] or "2+"
	if isMe then
		rarityLabel.Text = pokeData.Rarity .. " (Need " .. diffText .. ")"
	end

	-- Update Ball count
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
	if success then
		if isMe then
			nameLabel.Text = "CAUGHT! (Rolled " .. tostring(diceRoll) .. ")"
		else
			nameLabel.Text = activePlayer.Name .. " CAUGHT IT! (" .. diceRoll .. ")"
		end
		nameLabel.TextColor3 = Color3.new(0, 1, 0)
	else
		if isMe then
			nameLabel.Text = "FAILED! (Rolled " .. tostring(diceRoll) .. ")"
		else
			nameLabel.Text = activePlayer.Name .. " FAILED! (" .. diceRoll .. ")"
		end
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
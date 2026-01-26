local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")

local nameLabel = mainFrame:WaitForChild("NameLabel")
local rarityLabel = mainFrame:WaitForChild("RarityLabel")
local catchBtn = mainFrame:WaitForChild("CatchButton")
local runBtn = mainFrame:WaitForChild("RunButton")
local imgLabel = mainFrame:FindFirstChild("PokemonImage")
local ballsLabel = mainFrame:FindFirstChild("BallsLabel")

local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
local camera = workspace.CurrentCamera
local ROTATION_OFFSETS = {
	[1] = CFrame.Angles(0, 0, 0),
	[2] = CFrame.Angles(math.rad(-90), 0, 0),
	[3] = CFrame.Angles(0, math.rad(90), 0),
	[4] = CFrame.Angles(0, math.rad(-90), 0),
	[5] = CFrame.Angles(math.rad(90), 0, 0),
	[6] = CFrame.Angles(0, math.rad(180), 0)
}

-- Event
local encounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent")
local catchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local runEvent = ReplicatedStorage:WaitForChild("RunEvent") -- RunEvent for escaping

local currentPokeData = nil 
local DIFFICULTY_TEXT = { ["Common"]="2+", ["Rare"]="4+", ["Legendary"]="6!" }

-- 1. Handle Encounter Start
encounterEvent.OnClientEvent:Connect(function(pokeData)
	currentPokeData = pokeData 

	gui.Enabled = true
	mainFrame.Visible = true
	nameLabel.Text = pokeData.Name

	-- Display Pokemon Image if available
	if imgLabel then
		if pokeData.Image and pokeData.Image ~= "" then
			imgLabel.Visible = true -- Show image
			imgLabel.Image = pokeData.Image
		else
			imgLabel.Visible = false -- Hide if no image (using 3D model instead)
		end
	end

	local diffText = DIFFICULTY_TEXT[pokeData.Rarity] or "2+"
	if rarityLabel then rarityLabel.Text = pokeData.Rarity .. " (" .. diffText .. ")" end

	-- Update Ball count
	local playerBalls = 0
	if player.leaderstats and player.leaderstats:FindFirstChild("Pokeballs") then
		playerBalls = player.leaderstats.Pokeballs.Value
	end
	if ballsLabel then ballsLabel.Text = "Balls: " .. playerBalls end

	catchBtn.Visible = true
	if playerBalls <= 0 then
		catchBtn.Text = "NO BALLS!"
		catchBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	else
		catchBtn.Text = "CATCH"
		catchBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	end
end)

-- 2. Catch Button Logic
catchBtn.MouseButton1Click:Connect(function()
	if not currentPokeData then return end
	catchBtn.Visible = false
	nameLabel.Text = "Throwing..."
	catchEvent:FireServer(currentPokeData)
end)

-- 3. Catch Result (Server feedback)
catchEvent.OnClientEvent:Connect(function(success, diceRoll, target, isFinished)
	-- 1. Start Animation: Rolling...
	nameLabel.Text = "Throwing..."
	
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

	-- 2. Stop and Show Result
	local finalCF = camera.CFrame
	local dicePos = (finalCF + finalCF.LookVector * 5).Position
	local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[diceRoll]
	})
	tw:Play()

	task.wait(1.5) -- Wait for user to see dice face
	dice:Destroy()

	-- 3. Show Text Result
	if success then
		nameLabel.Text = "CAUGHT! (Rolled " .. tostring(diceRoll) .. ")"
		nameLabel.TextColor3 = Color3.new(0, 1, 0)
	else
		-- Catch failed
		nameLabel.Text = "FAILED! (Rolled " .. tostring(diceRoll) .. ")"
		nameLabel.TextColor3 = Color3.new(1, 0, 0)
	end

	-- Update remaining balls
	if player.leaderstats and player.leaderstats:FindFirstChild("Pokeballs") then
		local remainingBalls = player.leaderstats.Pokeballs.Value
		if ballsLabel then ballsLabel.Text = "Balls: " .. remainingBalls end

		-- Check if balls ran out
		if remainingBalls <= 0 and not success then
			nameLabel.Text = "OUT OF BALLS!"
			isFinished = true
		end
	end

	task.wait(2) -- Display result for 2s

	if isFinished then
		-- Encounter ended
		gui.Enabled = false
		nameLabel.Text = "" -- Clear text
	else
		-- Try again
		nameLabel.Text = currentPokeData.Name 
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		catchBtn.Visible = true 
		catchBtn.Text = "TRY AGAIN"
	end
end)

-- 4. Escape Button Logic
runBtn.MouseButton1Click:Connect(function()
	gui.Enabled = false

	-- Notify server to end encounter
	runEvent:FireServer() 
	print("Encounter escape sent to server")
end)
--[[
================================================================================
                      🌿 ENCOUNTER UI HANDLER (BOTTOM STYLE)
================================================================================
    📌 Location: StarterGui/EncounterUI/UIHandler
    📌 Responsibilities:
        - Handle Wild Pokemon Encounter UI
        - Display as a bottom panel (Classic RPG style)
        - Catch / Run functionality
================================================================================
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService") -- Added RunService
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [[ 🎨 UI CONSTRUCTION ]] --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EncounterGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10 -- Above HUD
screenGui.Parent = playerGui
screenGui.Enabled = false

-- HUD is likely filling the bottom corners, so we fit in the bottom center
local container = Instance.new("Frame")
container.Name = "BottomPanel"
container.Size = UDim2.new(0.6, 0, 0, 150) -- Wide bottom bar
container.Position = UDim2.new(0.5, 0, 1, 160) -- Start off-screen (bottom)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
container.BorderSizePixel = 0
container.Parent = screenGui

-- Styling
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", container)
stroke.Color = Color3.fromRGB(100, 255, 150)
stroke.Thickness = 2

-- 1. Pokemon Icon (Left)
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.new(0, 120, 0, 120)
iconFrame.Position = UDim2.new(0, 15, 0.5, 0)
iconFrame.AnchorPoint = Vector2.new(0, 0.5)
iconFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
iconFrame.Parent = container
Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 12)

local pokeImage = Instance.new("ImageLabel")
pokeImage.Name = "PokeImage"
pokeImage.Size = UDim2.new(0.8, 0, 0.8, 0)
pokeImage.Position = UDim2.new(0.5, 0, 0.5, 0)
pokeImage.AnchorPoint = Vector2.new(0.5, 0.5)
pokeImage.BackgroundTransparency = 1
pokeImage.ScaleType = Enum.ScaleType.Fit
pokeImage.Image = "rbxassetid://0"
pokeImage.Parent = iconFrame

-- 2. Info Text (Center)
local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoFrame"
infoFrame.Size = UDim2.new(0.4, 0, 0.8, 0)
infoFrame.Position = UDim2.new(0, 150, 0.1, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = container

local titleLbl = Instance.new("TextLabel")
titleLbl.Name = "Title"
titleLbl.Text = "WILD ENCOUNTER!"
titleLbl.Font = Enum.Font.FredokaOne
titleLbl.TextSize = 18
titleLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
titleLbl.Size = UDim2.new(1, 0, 0, 20)
titleLbl.BackgroundTransparency = 1
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = infoFrame

local nameLbl = Instance.new("TextLabel")
nameLbl.Name = "PokeName"
nameLbl.Text = "Bulbasaur"
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 28
nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLbl.Size = UDim2.new(1, 0, 0, 35)
nameLbl.Position = UDim2.new(0, 0, 0, 25)
nameLbl.BackgroundTransparency = 1
nameLbl.TextXAlignment = Enum.TextXAlignment.Left
nameLbl.Parent = infoFrame

local statsLbl = Instance.new("TextLabel")
statsLbl.Name = "Stats"
statsLbl.Text = "Common | HP: 100/100 | ATK: 15"
statsLbl.Font = Enum.Font.GothamMedium
statsLbl.TextSize = 14
statsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statsLbl.Size = UDim2.new(1, 0, 0, 20)
statsLbl.Position = UDim2.new(0, 0, 0, 65)
statsLbl.BackgroundTransparency = 1
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.Parent = infoFrame

-- 3. Actions (Right)
local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "ActionsFrame"
actionsFrame.Size = UDim2.new(0.3, 0, 0.8, 0)
actionsFrame.Position = UDim2.new(1, -15, 0.5, 0)
actionsFrame.AnchorPoint = Vector2.new(1, 0.5)
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = container

local layout = Instance.new("UIListLayout", actionsFrame)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Padding = UDim.new(0, 10)

-- BUTTON CREATOR
local function createButton(name, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.45, 0, 1, 0) -- 50% width each
	btn.BackgroundColor3 = color
	btn.Text = ""
	btn.Parent = actionsFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	
	-- Inner Text
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Parent = btn

	-- Hover Effect
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
	end)

	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Events
local EncounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent")
local CatchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local RunEvent = ReplicatedStorage:WaitForChild("RunEvent")

-- Action Buttons
local catchBtn = createButton("CatchBtn", "CATCH", Color3.fromRGB(46, 204, 113), function()
	-- Check balls locally just for UI feedback
	if player.leaderstats.Pokeballs.Value <= 0 then return end

	local e = ReplicatedStorage:FindFirstChild("CatchPokemonEvent")
	if e then e:FireServer() end
	statsLbl.Text = "Throwing Pokeball..."
	statsLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
end)

local runBtn = createButton("RunBtn", "RUN", Color3.fromRGB(231, 76, 60), function()
	local e = ReplicatedStorage:FindFirstChild("RunEvent")
	if e then e:FireServer() end
	screenGui.Enabled = false
end)

-- [[ 🔌 LOGIC CONNECTIONS ]] --

-- 1. SHOW ENCOUNTER
EncounterEvent.OnClientEvent:Connect(function(otherPlayer, data)
	-- Filter: Only show if it's OUR encounter
	if otherPlayer ~= player then return end

	-- Update UI
	if data then
		nameLbl.Text = data.Name or "Unknown"
		statsLbl.Text = (data.Rarity or "?") .. " | HP: " .. (data.HP or "?")
		
		if data.Image and data.Image ~= "" then
			pokeImage.Image = data.Image
		else
			pokeImage.Image = "rbxassetid://0"
		end
	end
	
	-- Show & Animate Up
	screenGui.Enabled = true
	catchBtn.Visible = true
	runBtn.Visible = true
	statsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	container.Position = UDim2.new(0.5, 0, 1, 160) -- Reset low
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -20)
	}):Play()
end)

-- 2. CATCH RESULT
CatchEvent.OnClientEvent:Connect(function(catcher, success, roll, target, isFinished)
	-- [[ DICE ANIMATION START ]] --
	local dice
	local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
	local camera = workspace.CurrentCamera

	if diceTemplate then 
		dice = diceTemplate:Clone() 
	else 
		dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) 
	end
	dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false
    
    -- Check if valid roll for animation
    local safeRoll = roll
    if type(safeRoll) ~= "number" then safeRoll = 1 end

	-- Sound
	local LAND_SOUND_ID = "rbxassetid://90144356226455"
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
		local cf = camera.CFrame
		local pos = cf + (cf.LookVector * 10)
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
	if not ROTATION_OFFSETS[safeRoll] then safeRoll = 1 end

	local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[safeRoll]
	})
	tw:Play()
    playSound(LAND_SOUND_ID)

	task.wait(0.5) -- Spam fix: Reduced from 1.5 to 0.5
	dice:Destroy()
	-- [[ DICE ANIMATION END ]] --

    -- Only update UI text if we are the catcher
    if catcher ~= player then return end

	-- Show dice roll result or just success/fail messsage
	if success then
		statsLbl.Text = "GOTCHA! (Rolled " .. tostring(roll) .. " >= " .. tostring(target) .. ")"
		statsLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
		
		-- Notify Server that animation is done so we can get our Pokemon!
		local animDoneEvent = ReplicatedStorage:FindFirstChild("CatchAnimationDoneEvent")
		if animDoneEvent then
			animDoneEvent:FireServer()
		end
	else
		statsLbl.Text = "ESCAPED... (Rolled " .. tostring(roll) .. " < " .. tostring(target) .. ")"
		statsLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
	
	if isFinished then
		task.wait(1.5)
		-- Animate Down
		TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, 160)
		}):Play()
		task.wait(0.5)
		screenGui.Enabled = false
	else
		-- Retry allowed? (Yes, until user runs or catches)
		task.wait(0.1) -- Spam fix: Reduced from 1 to 0.1
		if screenGui.Enabled then
			local ballsLeft = player.leaderstats.Pokeballs.Value
			
			if ballsLeft > 0 then
				statsLbl.Text = "Try again?"
				statsLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
				
				-- Re-enable button visual if we disabled it (optional optimization)
				catchBtn.Visible = true 
				catchBtn.Text = "CATCH"
				catchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			else
				statsLbl.Text = "Out of Pokeballs!"
				statsLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
				
				catchBtn.Visible = true
				catchBtn.Text = "NO BALLS"
				catchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
	end
end)

-- 3. RUN / HIDE
RunEvent.OnClientEvent:Connect(function()
	-- Animate Down
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1, 160)
	}):Play()
	task.wait(0.5)
	screenGui.Enabled = false
end)
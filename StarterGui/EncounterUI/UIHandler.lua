--[[
================================================================================
                      🐾 ENCOUNTER UI HANDLER (BOTTOM STYLE)
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
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- [NEW] ตัวแปร Debounce ป้องกันการกดรัว
local isThrowing = false 

-- [[ 🎧 UI CONSTRUCTION ]] --
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EncounterGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10 
screenGui.Parent = playerGui
screenGui.Enabled = false

local container = Instance.new("Frame")
container.Name = "BottomPanel"
container.Size = UDim2.new(0.6, 0, 0, 150)
container.Position = UDim2.new(0.5, 0, 1, 160)
container.AnchorPoint = Vector2.new(0.5, 1)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
container.BorderSizePixel = 0
container.Parent = screenGui

Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", container)
stroke.Color = Color3.fromRGB(100, 255, 150)
stroke.Thickness = 2

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

-- Rarity Label (color-coded)
local rarityLbl = Instance.new("TextLabel")
rarityLbl.Name = "Rarity"
rarityLbl.Text = "★ Common"
rarityLbl.Font = Enum.Font.GothamBold
rarityLbl.TextSize = 16
rarityLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
rarityLbl.Size = UDim2.new(1, 0, 0, 20)
rarityLbl.Position = UDim2.new(0, 0, 0, 60)
rarityLbl.BackgroundTransparency = 1
rarityLbl.TextXAlignment = Enum.TextXAlignment.Left
rarityLbl.Parent = infoFrame

-- Stats Label (HP/ATK)
local statsLbl = Instance.new("TextLabel")
statsLbl.Name = "Stats"
statsLbl.Text = "HP: 100 | ATK: 15"
statsLbl.Font = Enum.Font.GothamMedium
statsLbl.TextSize = 14
statsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
statsLbl.Size = UDim2.new(1, 0, 0, 20)
statsLbl.Position = UDim2.new(0, 0, 0, 82)
statsLbl.BackgroundTransparency = 1
statsLbl.TextXAlignment = Enum.TextXAlignment.Left
statsLbl.Parent = infoFrame

-- Catch Info Label
local catchInfoLbl = Instance.new("TextLabel")
catchInfoLbl.Name = "CatchInfo"
catchInfoLbl.Text = "🎯 Roll 3+ to Catch"
catchInfoLbl.Font = Enum.Font.GothamBold
catchInfoLbl.TextSize = 14
catchInfoLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
catchInfoLbl.Size = UDim2.new(1, 0, 0, 20)
catchInfoLbl.Position = UDim2.new(0, 0, 0, 102)
catchInfoLbl.BackgroundTransparency = 1
catchInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
catchInfoLbl.Parent = infoFrame

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

local function createButton(name, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0.45, 0, 1, 0)
	btn.BackgroundColor3 = color
	btn.Text = ""
	btn.Parent = actionsFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TextLabel" -- ตั้งชื่อเพื่อให้เรียกใช้ได้ง่าย
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 20
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
	end)

	btn.MouseButton1Click:Connect(callback)
	return btn
end

local EncounterEvent = ReplicatedStorage:WaitForChild("EncounterEvent")
local CatchEvent = ReplicatedStorage:WaitForChild("CatchPokemonEvent")
local RunEvent = ReplicatedStorage:WaitForChild("RunEvent")

-- Action Buttons
-- [FIX] ประกาศตัวแปรล่วงหน้าเพื่อให้ Function ภายในมองเห็นตัวแปร catchBtn
local catchBtn 
local runBtn 

catchBtn = createButton("CatchBtn", "CATCH", Color3.fromRGB(46, 204, 113), function()
	-- Anti-spam check
	if isThrowing then return end
	if player.leaderstats.Pokeballs.Value <= 0 then return end

	isThrowing = true -- Lock button

	-- Visual Feedback
	catchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	local lbl = catchBtn:FindFirstChild("TextLabel")
	if lbl then lbl.Text = "..." end

	local e = ReplicatedStorage:FindFirstChild("CatchPokemonEvent")
	if e then e:FireServer() end
	statsLbl.Text = "Throwing Pokeball..."
	statsLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
end)

runBtn = createButton("RunBtn", "RUN", Color3.fromRGB(231, 76, 60), function()
	if isThrowing then return end -- ห้ามหนีตอนกำลังปา
	local e = ReplicatedStorage:FindFirstChild("RunEvent")
	if e then e:FireServer() end
	screenGui.Enabled = false
end)

-- [[ 🔌 LOGIC CONNECTIONS ]] --

-- Rarity Colors
local RARITY_COLORS = {
	["None"] = Color3.fromRGB(150, 150, 150),
	["Common"] = Color3.fromRGB(100, 200, 100),
	["Uncommon"] = Color3.fromRGB(80, 180, 255),
	["Rare"] = Color3.fromRGB(200, 100, 255),
	["Legend"] = Color3.fromRGB(255, 215, 0)
}


EncounterEvent.OnClientEvent:Connect(function(otherPlayer, data)
	-- Safety check
	if not data then return end
	
	-- Check if spectator mode (otherPlayer is the encountering player)
	local isSpectator = (otherPlayer ~= player)
	
	isThrowing = false -- Reset state on new encounter

	if data then
		nameLbl.Text = data.Name or "Unknown"
		pokeImage.Image = (data.Image and data.Image ~= "") and data.Image or "rbxassetid://0"

		-- Rarity with color
		local rarity = data.Rarity or "?"
		rarityLbl.Text = "★ " .. rarity
		rarityLbl.TextColor3 = RARITY_COLORS[rarity] or Color3.fromRGB(150, 150, 150)

		-- Stats
		statsLbl.Text = "HP: " .. (data.HP or "?") .. " | ATK: " .. (data.Attack or "?")
		statsLbl.TextColor3 = Color3.fromRGB(200, 200, 200)

		-- Catch Requirement
		local catchTarget = data.CatchDifficulty or "?"
		catchInfoLbl.Text = "🎯 Roll " .. tostring(catchTarget) .. "+ to Catch"
	end

	screenGui.Enabled = true
	
	if isSpectator then
		-- Spectator mode: hide buttons, show spectator label
		catchBtn.Visible = false
		runBtn.Visible = false
		
		-- Add spectator label if not exists
		local spectatorLabel = screenGui:FindFirstChild("SpectatorLabel")
		if not spectatorLabel then
			spectatorLabel = Instance.new("TextLabel")
			spectatorLabel.Name = "SpectatorLabel"
			spectatorLabel.Text = "👁️ Spectating " .. (data.ActivePlayer and data.ActivePlayer.Name or "Encounter")
			spectatorLabel.Size = UDim2.new(0, 300, 0, 40)
			spectatorLabel.Position = UDim2.new(0.5, -150, 0, 10)
			spectatorLabel.AnchorPoint = Vector2.new(0.5, 0)
			spectatorLabel.BackgroundTransparency = 0.3
			spectatorLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			spectatorLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			spectatorLabel.Font = Enum.Font.GothamBold
			spectatorLabel.TextScaled = true
			spectatorLabel.Parent = screenGui
		end
	else
		-- Active player mode
		catchBtn.Visible = true
		runBtn.Visible = true
		
		-- Remove spectator label if exists
		local spectatorLabel = screenGui:FindFirstChild("SpectatorLabel")
		if spectatorLabel then spectatorLabel:Destroy() end
	end

	-- Reset button visual
	catchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	local lbl = catchBtn:FindFirstChild("TextLabel")
	if lbl then lbl.Text = "CATCH" end

	container.Position = UDim2.new(0.5, 0, 1, 160)
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, -20)
	}):Play()
end)


CatchEvent.OnClientEvent:Connect(function(catcher, success, roll, target, isFinished)
	local diceTemplate = ReplicatedStorage:FindFirstChild("DiceModel")
	local camera = workspace.CurrentCamera
	local dice

	if diceTemplate then dice = diceTemplate:Clone() else dice = Instance.new("Part"); dice.Size = Vector3.new(3,3,3) end
	dice.Parent = workspace; dice.Anchored = true; dice.CanCollide = false

	local safeRoll = (type(roll) == "number") and roll or 1

	local LAND_SOUND_ID = "rbxassetid://90144356226455"
	local function playSound(id) 
		local s = Instance.new("Sound", workspace)
		s.SoundId = id
		s.PlayOnRemove = true
		s:Destroy()
	end

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not dice.Parent then connection:Disconnect() return end
		local cf = camera.CFrame
		local pos = cf + (cf.LookVector * 10)
		dice.CFrame = CFrame.new(pos.Position) * CFrame.Angles(math.rad(os.clock()*700), math.rad(os.clock()*500), math.rad(os.clock()*600))
	end)

	task.wait(0.25)
	connection:Disconnect()

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

	TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(dicePos, finalCF.Position) * ROTATION_OFFSETS[safeRoll]
	}):Play()
	playSound(LAND_SOUND_ID)

	task.wait(0.5)
	dice:Destroy()

	if catcher ~= player then return end

	if success then
		statsLbl.Text = "GOTCHA! (Rolled " .. tostring(roll) .. " >= " .. tostring(target) .. ")"
		statsLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
		local animDoneEvent = ReplicatedStorage:FindFirstChild("CatchAnimationDoneEvent")
		if animDoneEvent then animDoneEvent:FireServer() end
	else
		statsLbl.Text = "ESCAPED... (Rolled " .. tostring(roll) .. " < " .. tostring(target) .. ")"
		statsLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	if isFinished then
		task.wait(1.5)
		isThrowing = false
		TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, 160)
		}):Play()
		task.wait(0.5)
		screenGui.Enabled = false
	else
		task.wait(1.0) -- [COOLDOWN] เพิ่มเวลาหน่วงห้ามกดรัว
		isThrowing = false -- ปลดล็อกปุ่ม

		if screenGui.Enabled then
			local ballsLeft = player.leaderstats.Pokeballs.Value
			local lbl = catchBtn:FindFirstChild("TextLabel")

			if ballsLeft > 0 then
				statsLbl.Text = "Try again?"
				statsLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
				catchBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				if lbl then lbl.Text = "CATCH" end
			else
				statsLbl.Text = "Out of Pokeballs!"
				statsLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
				catchBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
				if lbl then lbl.Text = "NO BALLS" end
			end
		end
	end
end)

RunEvent.OnClientEvent:Connect(function()
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1, 160)
	}):Play()
	task.wait(0.5)
	screenGui.Enabled = false
	isThrowing = false
end)
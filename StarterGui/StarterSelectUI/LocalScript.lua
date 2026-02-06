--[[
================================================================================
                      🎮 JOB/CLASS SELECTION UI
================================================================================
    📌 Location: StarterGui/StarterSelectUI/LocalScript
    📌 Responsibilities:
        - Show job/class selection (Gambler, Esper, Shaman, Biker)
        - Send selection to server
        - Display job abilities info
================================================================================
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================================
-- JOB DATABASE
-- ============================================================================
local JobDB = {
	Gambler = {
		Name = "Gambler",
		Icon = "🎰",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(255, 200, 50), -- Gold
		Description = "นักพนัน - เสี่ยงดวงเพื่อรางวัลใหญ่",
		Ability = "Lucky Guess",
		AbilityDesc = "ทายเลข 1-6 ถ้าถูกได้ 6 เหรียญ!",
		PassiveDesc = "ความโชคดีอยู่ข้างคุณเสมอ",
		Starter = "Meowth"
	},
	Esper = {
		Name = "Esper",
		Icon = "🔮",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(200, 100, 255), -- Purple
		Description = "จิตสัมผัส - ควบคุมโชคชะตา",
		Ability = "Mind Move",
		AbilityDesc = "กำหนดช่องเดินได้ 1 หรือ 2 ช่อง (แทนทอยเต๋า)",
		PassiveDesc = "เลือกเส้นทางได้ตามใจ",
		Starter = "Drowzee"
	},
	Shaman = {
		Name = "Shaman",
		Icon = "🌿",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(100, 200, 100), -- Green
		Description = "หมอผี - สาปแช่งศัตรู",
		Ability = "Curse",
		AbilityDesc = "สาปผู้เล่นคนอื่น: ทิ้งการ์ด 1 ใบ + เสียเงิน 1 เหรียญ",
		PassiveDesc = "พลังแห่งความมืดคือเพื่อนของคุณ",
		Starter = "Gastly"
	},
	Biker = {
		Name = "Biker",
		Icon = "🏍️",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(255, 100, 100), -- Red
		Description = "นักบิด - เร็วแรงทะลุนรก",
		Ability = "Turbo Boost",
		AbilityDesc = "เดินเพิ่ม +2 ช่อง ในเทิร์นนี้",
		PassiveDesc = "ความเร็วคือพลัง",
		Starter = "Cyclizar"
	},
	Trainer = {
		Name = "Trainer",
		Icon = "🎒",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(100, 150, 255), -- Blue
		Description = "เทรนเนอร์ - ผู้เชี่ยวชาญการ์ด",
		Ability = "Extra Hand",
		AbilityDesc = "ถือการ์ดได้ 6 ใบ (ปกติ 5)",
		PassiveDesc = "มาพร้อม Pikachu",
		Starter = "Pikachu"
	},
	Fisherman = {
		Name = "Fisherman",
		Icon = "🎣",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(50, 150, 200), -- Cyan
		Description = "นักตกปลา - ขโมยของคนอื่น",
		Ability = "Steal Card",
		AbilityDesc = "ขโมยการ์ด 1 ใบจากผู้เล่นคนอื่น",
		PassiveDesc = "มาพร้อม Magikarp",
		Starter = "Magikarp"
	},
	Rocket = {
		Name = "Rocket",
		Icon = "💀",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(80, 80, 80), -- Dark Gray
		Description = "แก๊งร็อคเก็ต - ขโมยโปเกม่อน!",
		Ability = "Steal Pokemon",
		AbilityDesc = "เมื่อชนะ PvP ขโมยโปเกม่อน 1 ตัว",
		PassiveDesc = "มาพร้อม Rattata",
		Starter = "Rattata"
	},
	NurseJoy = {
		Name = "NurseJoy",
		Icon = "💖",
		ImageId = "rbxassetid://0", -- 🖼️ ใส่รูปที่นี่
		Color = Color3.fromRGB(255, 150, 200), -- Pink
		Description = "คุณจอย - รักษาโปเกม่อน",
		Ability = "Revive",
		AbilityDesc = "ฟื้นคืนชีพโปเกม่อนที่ตายได้ทุกเทิร์น",
		PassiveDesc = "มาพร้อม Chansey",
		Starter = "Chansey"
	}
}

local JobOrder = {"Gambler", "Esper", "Shaman", "Biker", "Trainer", "Fisherman", "Rocket", "NurseJoy"}

-- ============================================================================
-- UI CREATION
-- ============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StarterSelectGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Background with gradient
local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
bg.Parent = screenGui

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
bgGradient.Rotation = 45
bgGradient.Parent = bg

-- Title
local title = Instance.new("TextLabel")
title.Text = "🎭 เลือกอาชีพของคุณ"
title.Size = UDim2.new(1, 0, 0, 60)
title.Position = UDim2.new(0, 0, 0.02, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.FredokaOne
title.TextSize = 36
title.Parent = bg

local subtitle = Instance.new("TextLabel")
subtitle.Text = "แต่ละอาชีพมี Ability พิเศษที่ใช้ได้ใน Ability Phase"
subtitle.Size = UDim2.new(1, 0, 0, 30)
subtitle.Position = UDim2.new(0, 0, 0.08, 0)
subtitle.BackgroundTransparency = 1
subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 16
subtitle.Parent = bg

-- Job Cards Container
local cardsContainer = Instance.new("Frame")
cardsContainer.Name = "CardsContainer"
cardsContainer.Size = UDim2.new(0.95, 0, 0.75, 0)
cardsContainer.Position = UDim2.new(0.025, 0, 0.15, 0)
cardsContainer.BackgroundTransparency = 1
cardsContainer.Parent = bg

local cardsLayout = Instance.new("UIListLayout")
cardsLayout.FillDirection = Enum.FillDirection.Horizontal
cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
cardsLayout.Padding = UDim.new(0.02, 0)
cardsLayout.Parent = cardsContainer

-- Waiting Screen
local waitFrame = Instance.new("Frame")
waitFrame.Size = UDim2.new(1, 0, 1, 0)
waitFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
waitFrame.Visible = false
waitFrame.Parent = screenGui

local waitText = Instance.new("TextLabel")
waitText.Text = "⏳ รอผู้เล่นคนอื่น..."
waitText.Size = UDim2.new(1, 0, 0.15, 0)
waitText.Position = UDim2.new(0, 0, 0.35, 0)
waitText.BackgroundTransparency = 1
waitText.TextColor3 = Color3.fromRGB(255, 255, 255)
waitText.Font = Enum.Font.FredokaOne
waitText.TextSize = 32
waitText.Parent = waitFrame

local selectedJobLabel = Instance.new("TextLabel")
selectedJobLabel.Name = "SelectedJob"
selectedJobLabel.Size = UDim2.new(1, 0, 0.1, 0)
selectedJobLabel.Position = UDim2.new(0, 0, 0.5, 0)
selectedJobLabel.BackgroundTransparency = 1
selectedJobLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
selectedJobLabel.Font = Enum.Font.FredokaOne
selectedJobLabel.TextSize = 24
selectedJobLabel.Text = ""
selectedJobLabel.Parent = waitFrame

-- ============================================================================
-- EVENTS
-- ============================================================================
local Events = {
	ShowStarterSelection = ReplicatedStorage:WaitForChild("ShowStarterSelectionEvent"),
	SelectStarter = ReplicatedStorage:WaitForChild("SelectStarterEvent"),
	UpdateTurn = ReplicatedStorage:WaitForChild("UpdateTurnEvent"),
	GameStarted = ReplicatedStorage:WaitForChild("GameStartedEvent", 5)
}

-- ============================================================================
-- CREATE JOB CARD
-- ============================================================================
local function createJobCard(jobName)
	local data = JobDB[jobName]
	if not data then return end

	local card = Instance.new("Frame")
	card.Name = jobName
	card.Size = UDim2.new(0.115, 0, 0.95, 0) -- Smaller for 8 cards
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	card.BorderSizePixel = 0
	card.Parent = cardsContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = data.Color
	cardStroke.Thickness = 3
	cardStroke.Transparency = 0.5
	cardStroke.Parent = card

	-- Icon / Image
	local hasImage = data.ImageId and data.ImageId ~= "" and data.ImageId ~= "rbxassetid://0"
	
	if hasImage then
		local iconImg = Instance.new("ImageLabel")
		iconImg.Name = "IconImage"
		iconImg.Image = data.ImageId
		iconImg.Size = UDim2.new(0.8, 0, 0, 80) -- Slightly narrower than full width
		iconImg.Position = UDim2.new(0.1, 0, 0.02, 0)
		iconImg.BackgroundTransparency = 1
		iconImg.ScaleType = Enum.ScaleType.Fit
		iconImg.Parent = card
	else
		-- Fallback to Emoji Text
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Text = data.Icon
		iconLabel.Size = UDim2.new(1, 0, 0, 80)
		iconLabel.Position = UDim2.new(0, 0, 0.02, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.TextSize = 60
		iconLabel.Parent = card
	end

	-- Job Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "JobName"
	nameLabel.Text = data.Name
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 90)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = data.Color
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 24
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Desc"
	descLabel.Text = data.Description
	descLabel.Size = UDim2.new(1, -20, 0, 25)
	descLabel.Position = UDim2.new(0, 10, 0, 120)
	descLabel.BackgroundTransparency = 1
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.Parent = card

	-- Ability Section
	local abilityTitle = Instance.new("TextLabel")
	abilityTitle.Text = "⚡ " .. data.Ability
	abilityTitle.Size = UDim2.new(1, -20, 0, 25)
	abilityTitle.Position = UDim2.new(0, 10, 0, 155)
	abilityTitle.BackgroundTransparency = 1
	abilityTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
	abilityTitle.Font = Enum.Font.GothamBold
	abilityTitle.TextSize = 14
	abilityTitle.TextXAlignment = Enum.TextXAlignment.Left
	abilityTitle.Parent = card

	local abilityDesc = Instance.new("TextLabel")
	abilityDesc.Text = data.AbilityDesc
	abilityDesc.Size = UDim2.new(1, -20, 0, 50)
	abilityDesc.Position = UDim2.new(0, 10, 0, 180)
	abilityDesc.BackgroundTransparency = 1
	abilityDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	abilityDesc.Font = Enum.Font.Gotham
	abilityDesc.TextSize = 11
	abilityDesc.TextWrapped = true
	abilityDesc.TextXAlignment = Enum.TextXAlignment.Left
	abilityDesc.TextYAlignment = Enum.TextYAlignment.Top
	abilityDesc.Parent = card

	-- Passive Section
	local passiveTitle = Instance.new("TextLabel")
	passiveTitle.Text = "🔹 Passive"
	passiveTitle.Size = UDim2.new(1, -20, 0, 20)
	passiveTitle.Position = UDim2.new(0, 10, 0, 235)
	passiveTitle.BackgroundTransparency = 1
	passiveTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	passiveTitle.Font = Enum.Font.GothamBold
	passiveTitle.TextSize = 12
	passiveTitle.TextXAlignment = Enum.TextXAlignment.Left
	passiveTitle.Parent = card

	local passiveDesc = Instance.new("TextLabel")
	passiveDesc.Text = data.PassiveDesc
	passiveDesc.Size = UDim2.new(1, -20, 0, 40)
	passiveDesc.Position = UDim2.new(0, 10, 0, 255)
	passiveDesc.BackgroundTransparency = 1
	passiveDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	passiveDesc.Font = Enum.Font.Gotham
	passiveDesc.TextSize = 10
	passiveDesc.TextWrapped = true
	passiveDesc.TextXAlignment = Enum.TextXAlignment.Left
	passiveDesc.TextYAlignment = Enum.TextYAlignment.Top
	passiveDesc.Parent = card

	-- Select Button
	local selectBtn = Instance.new("TextButton")
	selectBtn.Name = "SelectButton"
	selectBtn.Text = "เลือก " .. data.Name
	selectBtn.Size = UDim2.new(0.8, 0, 0, 45)
	selectBtn.Position = UDim2.new(0.1, 0, 1, -60)
	selectBtn.BackgroundColor3 = data.Color
	selectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	selectBtn.Font = Enum.Font.FredokaOne
	selectBtn.TextSize = 16
	selectBtn.Parent = card

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = selectBtn

	-- Hover Effects
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), {
			Transparency = 0,
			Thickness = 4
		}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		}):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), {
			Transparency = 0.5,
			Thickness = 3
		}):Play()
	end)

	-- Button Hover
	selectBtn.MouseEnter:Connect(function()
		TweenService:Create(selectBtn, TweenInfo.new(0.15), {
			Size = UDim2.new(0.85, 0, 0, 50)
		}):Play()
	end)

	selectBtn.MouseLeave:Connect(function()
		TweenService:Create(selectBtn, TweenInfo.new(0.15), {
			Size = UDim2.new(0.8, 0, 0, 45)
		}):Play()
	end)

	-- Select Action
	selectBtn.MouseButton1Click:Connect(function()
		print("✅ Selected Job:", jobName)
		Events.SelectStarter:FireServer(jobName)

		-- Show waiting screen
		bg.Visible = false
		waitFrame.Visible = true
		selectedJobLabel.Text = data.Icon .. " คุณเลือก: " .. data.Name
		selectedJobLabel.TextColor3 = data.Color
	end)
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================
task.spawn(function()
	for _, jobName in ipairs(JobOrder) do
		createJobCard(jobName)
	end
end)

-- ============================================================================
-- EVENT LISTENERS
-- ============================================================================

-- Show selection UI
Events.ShowStarterSelection.OnClientEvent:Connect(function()
	print("✨ Opening Job Selection")
	screenGui.Enabled = true
	bg.Visible = true
	waitFrame.Visible = false
end)

-- Hide UI when game starts
Events.UpdateTurn.OnClientEvent:Connect(function()
	if screenGui.Enabled then
		print("🚀 Game Started! Hiding Selection UI.")
		screenGui.Enabled = false
	end
end)

-- Explicit GameStarted event
if Events.GameStarted then
	Events.GameStarted.OnClientEvent:Connect(function()
		print("🎮 GameStarted event received! Hiding Selection UI.")
		screenGui.Enabled = false
	end)
end

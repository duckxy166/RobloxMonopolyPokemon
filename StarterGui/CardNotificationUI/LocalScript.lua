--[[
================================================================================
                      🃏 CARD NOTIFICATION UI
================================================================================
    📌 Location: StarterGui/CardNotificationUI/LocalScript
    📌 Responsibilities:
        - Display card usage notifications to ALL players
        - Show who used what card on whom
        - Play sound effects for attack/defense cards
================================================================================
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Events
local cardNotificationEvent = ReplicatedStorage:WaitForChild("CardNotificationEvent", 10)

-- Sound IDs (Distinct sounds for each card type)
local SOUNDS = {
	Attack = "rbxassetid://70560213897976",    -- Battle/Attack sound
	Defense = "rbxassetid://9125402735",       -- Shield block sound
	Buff = "rbxassetid://71879312538894",      -- Power up / evolve sound
	Warp = "rbxassetid://91585745295429",      -- Teleport swoosh
	Evolution = "rbxassetid://71879312538894", -- Evolution sound
}

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CardNotificationUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

-- Notification Container
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 400, 0, 100)
container.Position = UDim2.new(0.5, 0, 0.15, 0)
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
container.BackgroundTransparency = 0.1
container.BorderSizePixel = 0
container.Visible = false
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 200, 50)
stroke.Thickness = 3
stroke.Parent = container

-- Card Icon
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.new(0, 80, 0, 80)
iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
iconFrame.AnchorPoint = Vector2.new(0, 0.5)
iconFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
iconFrame.Parent = container
Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 12)

local cardIcon = Instance.new("TextLabel")
cardIcon.Name = "CardIcon"
cardIcon.Size = UDim2.new(1, 0, 1, 0)
cardIcon.BackgroundTransparency = 1
cardIcon.Text = "🃏"
cardIcon.Font = Enum.Font.GothamBold
cardIcon.TextSize = 40
cardIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
cardIcon.Parent = iconFrame

-- Text Container
local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Size = UDim2.new(1, -110, 1, -20)
textContainer.Position = UDim2.new(0, 100, 0, 10)
textContainer.BackgroundTransparency = 1
textContainer.Parent = container

-- Card Name Label
local cardNameLabel = Instance.new("TextLabel")
cardNameLabel.Name = "CardName"
cardNameLabel.Size = UDim2.new(1, 0, 0, 30)
cardNameLabel.BackgroundTransparency = 1
cardNameLabel.Text = "Card Name"
cardNameLabel.Font = Enum.Font.FredokaOne
cardNameLabel.TextSize = 24
cardNameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
cardNameLabel.TextXAlignment = Enum.TextXAlignment.Left
cardNameLabel.Parent = textContainer

-- Action Label
local actionLabel = Instance.new("TextLabel")
actionLabel.Name = "Action"
actionLabel.Size = UDim2.new(1, 0, 0, 50)
actionLabel.Position = UDim2.new(0, 0, 0, 30)
actionLabel.BackgroundTransparency = 1
actionLabel.Text = "Player used on Target"
actionLabel.Font = Enum.Font.GothamBold
actionLabel.TextSize = 18
actionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
actionLabel.TextXAlignment = Enum.TextXAlignment.Left
actionLabel.TextWrapped = true
actionLabel.Parent = textContainer

-- Card Type Icons (Updated to match CardDB names)
local CARD_ICONS = {
	["Grabber"] = "💰",
	["Air Balloon"] = "🎈",
	["Sleep Powder"] = "💤",
	["Twisted Spoon"] = "🔮",
	["Protective Goggles"] = "🛡️",
	["Lucky Energy"] = "⚡",
	["Rare Candy"] = "🍬",
	["Nugget"] = "💎",
	["Revive"] = "💖",
}

-- Card Type Colors
local CARD_COLORS = {
	Attack = Color3.fromRGB(255, 80, 80),
	Defense = Color3.fromRGB(80, 180, 255),
	Buff = Color3.fromRGB(100, 255, 100),
	Warp = Color3.fromRGB(200, 100, 255),
}

-- Play Sound
local function playSound(soundType)
	local soundId = SOUNDS[soundType] or SOUNDS.Buff
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- Show Notification
local function showNotification(data)
	-- data = {CardName, UserName, TargetName, CardType, Message}
	
	local cardName = data.CardName or "Card"
	local userName = data.UserName or "Player"
	local targetName = data.TargetName
	local cardType = data.CardType or "Buff"
	local message = data.Message or ""
	
	-- Set Icon
	cardIcon.Text = CARD_ICONS[cardName] or "🃏"
	
	-- Set Card Name
	cardNameLabel.Text = cardName
	
	-- Set border color based on card type
	stroke.Color = CARD_COLORS[cardType] or Color3.fromRGB(255, 200, 50)
	
	-- Set Action Text
	if targetName and targetName ~= "" then
		actionLabel.Text = userName .. " → " .. targetName .. "\n" .. message
	else
		actionLabel.Text = userName .. "\n" .. message
	end
	
	-- Play Sound
	playSound(cardType)
	
	-- Animate In
	container.Position = UDim2.new(0.5, 0, -0.2, 0)
	container.Visible = true
	
	TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.15, 0)
	}):Play()
	
	-- Wait and Animate Out
	task.delay(2.5, function()
		TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.2, 0)
		}):Play()
		task.delay(0.3, function()
			container.Visible = false
		end)
	end)
end

-- Listen for Card Notifications
if cardNotificationEvent then
	cardNotificationEvent.OnClientEvent:Connect(function(data)
		showNotification(data)
	end)
end

print("✅ CardNotificationUI loaded")

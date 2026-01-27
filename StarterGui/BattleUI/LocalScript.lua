--[[
================================================================================
                      ⚔️ BATTLE UI CONTROLLER
================================================================================
    📌 Location: StarterGui/BattleUI/LocalScript
    📌 Responsibilities:
        - Display Battle Interface (HP Bars, Pokemon Images)
        - Handle Battle Roll input
        - Show Damage Numbers & Animations
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BattleGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main Container
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0.6, 0, 0.6, 0)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BackgroundTransparency = 0.1
container.BorderSizePixel = 0
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", container).Color = Color3.fromRGB(255, 50, 50)
Instance.new("UIStroke", container).Thickness = 3

-- Title
local titleLbl = Instance.new("TextLabel")
titleLbl.Name = "Title"
titleLbl.Size = UDim2.new(1, 0, 0.15, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "⚔️ BATTLE START!"
titleLbl.Font = Enum.Font.FredokaOne
titleLbl.TextSize = 32
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Parent = container

-- [[ LEFT SIDE: PLAYER ]] --
local leftContainer = Instance.new("Frame")
leftContainer.Name = "LeftParams"
leftContainer.Size = UDim2.new(0.4, 0, 0.6, 0)
leftContainer.Position = UDim2.new(0.05, 0, 0.2, 0)
leftContainer.BackgroundTransparency = 1
leftContainer.Parent = container

local leftImage = Instance.new("ImageLabel")
leftImage.Name = "Image"
leftImage.Size = UDim2.new(0.8, 0, 0.6, 0)
leftImage.Position = UDim2.new(0.1, 0, 0, 0)
leftImage.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
leftImage.Parent = leftContainer
Instance.new("UICorner", leftImage).CornerRadius = UDim.new(0, 8)

local leftName = Instance.new("TextLabel")
leftName.Name = "Name"
leftName.Size = UDim2.new(1, 0, 0.15, 0)
leftName.Position = UDim2.new(0, 0, 0.65, 0)
leftName.BackgroundTransparency = 1
leftName.Text = "Bulbasaur"
leftName.TextColor3 = Color3.fromRGB(255, 255, 255)
leftName.Font = Enum.Font.FredokaOne
leftName.TextSize = 20
leftName.Parent = leftContainer

local leftHPBar = Instance.new("Frame")
leftHPBar.Name = "HPBar"
leftHPBar.Size = UDim2.new(1, 0, 0.1, 0)
leftHPBar.Position = UDim2.new(0, 0, 0.85, 0)
leftHPBar.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
leftHPBar.Parent = leftContainer
Instance.new("UICorner", leftHPBar).CornerRadius = UDim.new(1, 0)

local leftHPFill = Instance.new("Frame")
leftHPFill.Name = "Fill"
leftHPFill.Size = UDim2.new(1, 0, 1, 0)
leftHPFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
leftHPFill.Parent = leftHPBar
Instance.new("UICorner", leftHPFill).CornerRadius = UDim.new(1, 0)

local leftHitTxt = Instance.new("TextLabel")
leftHitTxt.Name = "HitTxt"
leftHitTxt.Size = UDim2.new(1, 0, 0.5, 0)
leftHitTxt.Position = UDim2.new(0, 0, 0.2, 0)
leftHitTxt.BackgroundTransparency = 1
leftHitTxt.Text = "-10"
leftHitTxt.TextColor3 = Color3.fromRGB(255, 50, 50)
leftHitTxt.TextSize = 40
leftHitTxt.Font = Enum.Font.FredokaOne
leftHitTxt.Visible = false
leftHitTxt.Parent = leftContainer

-- [[ RIGHT SIDE: ENEMY ]] --
local rightContainer = leftContainer:Clone()
rightContainer.Name = "RightParams"
rightContainer.Position = UDim2.new(0.55, 0, 0.2, 0)
rightContainer.Parent = container

-- Action Button
local rollBtn = Instance.new("TextButton")
rollBtn.Name = "RollButton"
rollBtn.Size = UDim2.new(0.3, 0, 0.15, 0)
rollBtn.Position = UDim2.new(0.35, 0, 0.8, 0)
rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
rollBtn.Text = "🎲 ROLL ATTACK"
rollBtn.Font = Enum.Font.FredokaOne
rollBtn.TextSize = 24
rollBtn.Parent = container
Instance.new("UICorner", rollBtn).CornerRadius = UDim.new(0, 8)

-- Variables
local currentBattleData = nil
local isRolling = false

-- Events
local Events = {
	BattleStart = ReplicatedStorage:WaitForChild("BattleStartEvent"),
	BattleAttack = ReplicatedStorage:WaitForChild("BattleAttackEvent"),
	BattleEnd = ReplicatedStorage:WaitForChild("BattleEndEvent"),
}

-- Functions
local function updateHP(isLeft, current, max)
	local fill = isLeft and leftHPFill or rightContainer.HPBar.Fill
	local pct = math.clamp(current / max, 0, 1)
	
	TweenService:Create(fill, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
	
	-- Color change logic
	if pct < 0.2 then fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	elseif pct < 0.5 then fill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	else fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100) end
end

local function showDamage(isLeft, amount)
	local txt = isLeft and leftHitTxt or rightContainer.HitTxt
	txt.Text = "-" .. amount
	txt.Visible = true
	txt.Position = UDim2.new(0, 0, 0.2, 0)
	txt.TextTransparency = 0
	
	local t1 = TweenService:Create(txt, TweenInfo.new(0.5), {Position = UDim2.new(0, 0, 0, 0)})
	local t2 = TweenService:Create(txt, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.5), {TextTransparency = 1})
	
	t1:Play()
	t2:Play()
end

-- Event Handlers
Events.BattleStart.OnClientEvent:Connect(function(type, data)
	if type == "SelectOpponent" then
		-- Create simple selection dialog for PvP
		-- (Will implement later or use basic dialog)
		return
	end
	
	currentBattleData = data
	screenGui.Enabled = true
	rollBtn.Visible = true
	rollBtn.Text = "🎲 ROLL ATTACK"
	rollBtn.Active = true
	isRolling = false
	
	-- Setup UI
	if type == "PvE" then
		titleLbl.Text = "WILD POKEMON APPEARED!"
		
		-- Left (Me)
		leftName.Text = data.MyStats.Name .. " (Lv." .. (data.MyStats.Level or 1) .. ")"
		updateHP(true, data.MyStats.CurrentHP, data.MyStats.MaxHP)
		
		-- Right (Enemy)
		rightContainer.Name.Text = data.EnemyStats.Name
		rightImage.Image = "rbxassetid://0" -- Placeholder
		updateHP(false, data.EnemyStats.CurrentHP, data.EnemyStats.MaxHP)
		
	elseif type == "PvP" then
		local isAttacker = (player == data.Attacker)
		titleLbl.Text = isAttacker and "VERSUS " .. data.Defender.Name or "DEFEND AGAINST " .. data.Attacker.Name
		
		-- Logic to display correct side
		-- We always show "Me" on Left
		local myStats = isAttacker and data.AttackerStats or data.DefenderStats
		local oppStats = isAttacker and data.DefenderStats or data.AttackerStats
		
		leftName.Text = myStats.Name
		rightContainer.Name.Text = oppStats.Name
		
		updateHP(true, myStats.CurrentHP, myStats.MaxHP)
		updateHP(false, oppStats.CurrentHP, oppStats.MaxHP)
	end
end)

-- Roll Button
rollBtn.MouseButton1Click:Connect(function()
	if isRolling or not currentBattleData then return end
	isRolling = true
	rollBtn.Text = "Waiting..."
	rollBtn.Active = false
	
	-- Ideally we reusing existing roll event or create new one?
	-- For now, reusing RollDiceEvent but with context? No, let's fire the generic Roll event 
	-- But wait, BattleSystem needs specific input.
	-- Let's assume there's a BattleAttackEvent we can fire server-side logic triggers
	
	-- Use a new remote function/event for Battle Action
	-- Since we don't have one explicitly created for INPUT yet, use BattleAttack to trigger?
	-- Wait, look at EventManager... we created BattleAttackEvent.
	
	-- Correction: We need a Client->Server event for Battle Roll.
	-- For now, let's use "RollDiceEvent" and handle context on server? No, dangerous.
	-- Let's use "BattleAttackEvent" as a remote EVENT from client to server to signal "I rolled".
	
	Events.BattleAttack:FireServer() 
end)

Events.BattleAttack.OnClientEvent:Connect(function(winner, damage, details)
	-- Show animations
	isRolling = false
	rollBtn.Text = "🎲 ROLL ATTACK"
	rollBtn.Active = true
	
	if currentBattleData.Type == "PvE" then
		if winner == "Player" then
			showDamage(false, damage) -- Enemy took damage
			updateHP(false, details.EnemyHP, currentBattleData.EnemyStats.MaxHP)
		else
			showDamage(true, damage) -- I took damage
			updateHP(true, details.PlayerHP, currentBattleData.MyStats.MaxHP)
		end
		
	elseif currentBattleData.Type == "PvP" then
		-- Determine based on "Winner" string (Attacker/Defender)
		local amIAttacker = (player == currentBattleData.Attacker)
		local myRole = amIAttacker and "Attacker" or "Defender"
		
		if winner == myRole then
			showDamage(false, damage) -- Enemy damaged
		elseif winner == "Draw" then
			-- Draw animation
		else
			showDamage(true, damage) -- I damaged
		end
		
		-- Update HPs
		local myHP = amIAttacker and details.AttackerHP or details.DefenderHP
		local oppHP = amIAttacker and details.DefenderHP or details.AttackerHP
		local myMax = amIAttacker and currentBattleData.AttackerStats.MaxHP or currentBattleData.DefenderStats.MaxHP
		local oppMax = amIAttacker and currentBattleData.DefenderStats.MaxHP or currentBattleData.AttackerStats.MaxHP
		
		updateHP(true, myHP, myMax)
		updateHP(false, oppHP, oppMax)
	end
end)

Events.BattleEnd.OnClientEvent:Connect(function(result)
	screenGui.Enabled = false
	currentBattleData = nil
	if result == "Win" or result == "AttackerWin" or result == "DefenderWin" then
		-- Check if I won
		-- Open Evolution UI if won (handled by server notification)
	end
end)

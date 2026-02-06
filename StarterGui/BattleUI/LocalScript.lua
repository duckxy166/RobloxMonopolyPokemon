--[[
================================================================================
                      ⚔️ BATTLE INPUT CONTROLLER (NO UI)
================================================================================
    📌 Location: StarterGui/BattleUI/LocalScript
    📌 Responsibilities:
        - Handle Battle Input (Spacebar / Touch) without GUI
        - Display Battle Feedback via Chat/Notify
        - Listen for BattleStart/End
================================================================================
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- Events
print("🔵 [Client] BattleUI Script Started...")
local Events = {
	BattleStart = ReplicatedStorage:WaitForChild("BattleStartEvent", 10),
	BattleAttack = ReplicatedStorage:WaitForChild("BattleAttackEvent", 10),
	BattleEnd = ReplicatedStorage:WaitForChild("BattleEndEvent", 10),
	BattleTrigger = ReplicatedStorage:WaitForChild("BattleTriggerEvent", 10),
	BattleTriggerResponse = ReplicatedStorage:WaitForChild("BattleTriggerResponseEvent", 10),
	Notify = ReplicatedStorage:WaitForChild("NotifyEvent", 10)
}
print("🔵 [Client] BattleUI Events Loaded:", Events.BattleTrigger and "Yes" or "No")

-- UI Creation (Minimal)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BattleGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- rollBtn will be created inside createVSFrame()
local rollBtn = nil

-- State
local isBattleActive = false
local isRolling = false
local battleResolved = false
local currentBattleData = nil
local vsFrame = nil
local lastRollTime = 0       -- Anti-spam: track last roll time
local ROLL_COOLDOWN = 1      -- 1 second cooldown between rolls

-- Active dice storage (must be declared before createVSFrame)
local activeDice = {} -- {Player=?, Enemy=?}

local function cleanupDice()
	if activeDice.Player then
		if activeDice.Player.Object then activeDice.Player.Object:Destroy() end
		activeDice.Player = nil
	end
	if activeDice.Enemy then
		if activeDice.Enemy.Object then activeDice.Enemy.Object:Destroy() end
		activeDice.Enemy = nil
	end
end

-- [[ 3D DICE LOGIC ]] -- (Moved here so spawn3NDice is available to createVSFrame)
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

local DICE_SIDE = 9
local DICE_DOWN = 2.2
local DICE_FORWARD = 12

local function getDiceCF(sideOffset)
	local cam = workspace.CurrentCamera
	if not cam then return CFrame.new() end

	local camCF = cam.CFrame
	local pos =
		camCF.Position
		+ camCF.LookVector * DICE_FORWARD
		+ camCF.RightVector * (sideOffset * DICE_SIDE)
	- camCF.UpVector * DICE_DOWN

	return CFrame.lookAt(pos, camCF.Position)
end

-- Spawn and Animate a single 3D Die
local function spawn3NDice(sideOffset)
	local dice

	-- Create / clone
	if diceTemplate then
		dice = diceTemplate:Clone()
	else
		dice = Instance.new("Part")
		dice.Size = Vector3.new(3,3,3)
		dice.Color = Color3.fromRGB(240, 240, 240)
	end

	dice.Parent = workspace

	-- Anchor + no collide (Part or Model)
	for _, d in ipairs(dice:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		end
	end
	if dice:IsA("BasePart") then
		dice.Anchored = true
		dice.CanCollide = false
	end

	-- Part/Model set CFrame
	local function setCF(cf)
		if dice:IsA("Model") then
			dice:PivotTo(cf)
		else
			dice.CFrame = cf
		end
	end

	-- Start at correct spot
	setCF(getDiceCF(sideOffset))

	-- Spin while staying in front of camera
	local connection
	local ax, ay, az = 0, 0, 0
	local spinSpeed = Vector3.new(
		math.rad(math.random(300,700)),
		math.rad(math.random(300,700)),
		math.rad(math.random(300,700))
	)

	connection = RunService.RenderStepped:Connect(function(dt)
		if not dice.Parent then
			if connection then connection:Disconnect() end
			return
		end

		ax += spinSpeed.X * dt
		ay += spinSpeed.Y * dt
		az += spinSpeed.Z * dt

		-- lock position to camera each frame
		setCF(getDiceCF(sideOffset) * CFrame.Angles(ax, ay, az))
	end)

	return {
		Object = dice,
		Stop = function(finalVal)
			if connection then connection:Disconnect() end

			local targetCF = getDiceCF(sideOffset) * ROTATION_OFFSETS[finalVal]

			-- Tween Part directly
			if not dice:IsA("Model") then
				TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					CFrame = targetCF
				}):Play()
			else
				-- Tween Model via CFrameValue
				local cfVal = Instance.new("CFrameValue")
				cfVal.Value = dice:GetPivot()

				local conn2
				conn2 = cfVal.Changed:Connect(function(v)
					if dice.Parent then
						dice:PivotTo(v)
					else
						if conn2 then conn2:Disconnect() end
					end
				end)

				TweenService:Create(cfVal, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Value = targetCF
				}):Play()

				task.delay(1, function()
					if conn2 then conn2:Disconnect() end
					cfVal:Destroy()
				end)
			end

			task.delay(3, function()
				if dice then dice:Destroy() end
			end)
		end
	}
end

-- Helper: Create VS UI
local function createVSFrame()
	if vsFrame then vsFrame:Destroy() end

	vsFrame = Instance.new("Frame")
	vsFrame.Name = "VSFrame"
	vsFrame.Size = UDim2.new(0.6, 0, 0.15, 0) -- Reduced width (was 0.8)
	vsFrame.Position = UDim2.new(0.2, 0, 0.82, 0) -- Centered (was 0.1)
	vsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	vsFrame.BackgroundTransparency = 0.2
	vsFrame.Parent = screenGui

	Instance.new("UICorner", vsFrame).CornerRadius = UDim.new(0, 10)

	-- Create Roll Button INSIDE vsFrame (recreated each time)
	rollBtn = Instance.new("TextButton")
	rollBtn.Name = "RollButton"
	rollBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
	rollBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
	rollBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	rollBtn.Text = "🎲 ROLL ATTACK"
	rollBtn.Font = Enum.Font.FredokaOne
	rollBtn.TextSize = 24
	rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	rollBtn.Visible = false -- Hidden until turn
	rollBtn.ZIndex = 10 -- Ensure it's on top
	rollBtn.Parent = vsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = rollBtn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(255, 100, 50)
	stroke.Parent = rollBtn

	-- Connect rollBtn click handler
	rollBtn.MouseButton1Click:Connect(function()
		if not isBattleActive or isRolling or battleResolved then return end

		-- Anti-spam cooldown check
		local now = tick()
		if (now - lastRollTime) < ROLL_COOLDOWN then return end

		isRolling = true
		lastRollTime = now
		rollBtn.Visible = false -- Hide button while rolling

		-- Cleanup previous dice before spawning new ones (for round 2+)
		cleanupDice()

		-- Spawn player dice spinning immediately
		local myDiceOffset = -1 -- Default left
		if currentBattleData and currentBattleData.Type == "PvP" then
			if player == currentBattleData.Defender then
				myDiceOffset = 1 -- I am P2, dice on right
			end
		end
		activeDice.Player = spawn3NDice(myDiceOffset)

		-- Fire server to roll
		Events.BattleAttack:FireServer()
	end)

	-- Helper to create side
	local function createSide(parent, side, color)
		local container = Instance.new("Frame")
		container.Name = side
		container.Size = UDim2.new(0.35, 0, 1, 0) -- Reduced width to leave room for center button
		container.Position = side == "Left" and UDim2.new(0, 0, 0, 0) or UDim2.new(0.65, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.Parent = parent

		-- Pokemon Image
		local img = Instance.new("ImageLabel")
		img.Name = "PokeImage"
		img.Size = UDim2.new(0.3, 0, 0.9, 0)
		img.Position = side == "Left" and UDim2.new(0, 5, 0.05, 0) or UDim2.new(0.7, -5, 0.05, 0)
		img.BackgroundColor3 = color
		img.Parent = container
		Instance.new("UICorner", img).CornerRadius = UDim.new(0, 8)

		-- Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Text = "Pokemon"
		nameLbl.Size = UDim2.new(0.6, 0, 0.3, 0)
		nameLbl.Position = side == "Left" and UDim2.new(0.35, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
		nameLbl.Font = Enum.Font.FredokaOne
		nameLbl.TextSize = 18
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Parent = container
		if side == "Right" then nameLbl.TextXAlignment = Enum.TextXAlignment.Right end
		if side == "Left" then nameLbl.TextXAlignment = Enum.TextXAlignment.Left end

		-- Attack Power Label
		local atkLbl = Instance.new("TextLabel")
		atkLbl.Name = "AttackLabel"
		atkLbl.Text = "⚔️ 0"
		atkLbl.Size = UDim2.new(0.6, 0, 0.2, 0)
		atkLbl.Position = side == "Left" and UDim2.new(0.35, 0, 0.35, 0) or UDim2.new(0.05, 0, 0.35, 0)
		atkLbl.Font = Enum.Font.GothamBold
		atkLbl.TextSize = 14
		atkLbl.TextColor3 = Color3.fromRGB(255, 200, 50) -- Gold/Orange
		atkLbl.BackgroundTransparency = 1
		atkLbl.Parent = container
		if side == "Right" then atkLbl.TextXAlignment = Enum.TextXAlignment.Right end
		if side == "Left" then atkLbl.TextXAlignment = Enum.TextXAlignment.Left end

		-- HP Bar
		local hpBg = Instance.new("Frame")
		hpBg.Name = "HP_BG"
		hpBg.Size = UDim2.new(0.6, 0, 0.2, 0)
		hpBg.Position = side == "Left" and UDim2.new(0.35, 0, 0.6, 0) or UDim2.new(0.05, 0, 0.6, 0)
		hpBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		hpBg.Parent = container
		Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

		local hpFill = Instance.new("Frame")
		hpFill.Name = "HP_Fill"
		hpFill.Size = UDim2.new(1, 0, 1, 0)
		hpFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
		hpFill.Parent = hpBg
		Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

		local hpText = Instance.new("TextLabel")
		hpText.Name = "HP_Text"
		hpText.Text = "100/100"
		hpText.Size = UDim2.new(1, 0, 1, 0)
		hpText.BackgroundTransparency = 1
		hpText.Font = Enum.Font.Code
		hpText.TextSize = 12
		hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
		hpText.Parent = hpBg

		return container
	end

	createSide(vsFrame, "Left", Color3.fromRGB(100, 100, 255))
	createSide(vsFrame, "Right", Color3.fromRGB(255, 100, 100))
end

-- Helper: Send System Message
local function sendMsg(text, color)
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = "[⚔️ BATTLE] " .. text;
			Color = color or Color3.fromRGB(255, 255, 255);
			Font = Enum.Font.SourceSansBold;
			FontSize = Enum.FontSize.Size18;
		})
	end)
end

-- Input Handler
UserInputService.InputBegan:Connect(function(input, gamProcessed)
	if gamProcessed then return end
	if not isBattleActive then return end

	-- Anti-spam cooldown check
	local now = tick()
	if (now - lastRollTime) < ROLL_COOLDOWN then return end

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		-- Attack
		if not isRolling and not battleResolved then
			isRolling = true
			lastRollTime = now
			sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))
			Events.BattleAttack:FireServer()
		end
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- Touch Attack
		if not isRolling and not battleResolved then
			isRolling = true
			lastRollTime = now
			sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))
			Events.BattleAttack:FireServer()
		end
	end
end)

-- Button Handler is now inside createVSFrame() function

-- Battle Update (Damage)
Events.BattleAttack.OnClientEvent:Connect(function(winner, damage, details)
	isRolling = false

	-- Check if battle is over (someone's HP reached 0)
	local battleOver = false
	if details then
		if details.PlayerHP and details.PlayerHP <= 0 then battleOver = true end
		if details.EnemyHP and details.EnemyHP <= 0 then battleOver = true end
		if details.AttackerHP and details.AttackerHP <= 0 then battleOver = true end
		if details.DefenderHP and details.DefenderHP <= 0 then battleOver = true end
	end

	if winner ~= "Draw" and battleOver then
		battleResolved = true
	end

	local myName, enemyName, myRoll, enemyRoll

	if currentBattleData then
		if currentBattleData.Type == "PvP" then
			-- Attacker is always Player 1 (Left), Defender is always Player 2 (Right)
			myName = currentBattleData.Attacker.Name
			enemyName = currentBattleData.Defender.Name

			if player == currentBattleData.Attacker then
				myRoll = details.AttackerRoll
				enemyRoll = details.DefenderRoll
			else
				myRoll = details.DefenderRoll
				enemyRoll = details.AttackerRoll
			end
		else
			myName = "You"
			enemyName = currentBattleData.EnemyStats.Name
			myRoll = details.PlayerRoll
			enemyRoll = details.EnemyRoll
		end
	end

	-- Cleanup previous spinning dice if any
	-- (Wait, we want to KEEP the player dice spinning and just stop it)

	-- Step A: Position determination
	local myDiceOffset = -1 -- Default left
	local enemyDiceOffset = 1 -- Default right

	if currentBattleData.Type == "PvP" then
		if player == currentBattleData.Defender then
			-- I am P2, so my dice should be on the right
			myDiceOffset = 1
			enemyDiceOffset = -1
		end
	end

	-- Step B: Rolling sequence (Visuals)

	-- Stop My Dice (it was already spinning from button click or spacebar)
	if activeDice.Player then
		activeDice.Player.Stop(myRoll or 1)
	else
		-- Cleanup any leftover dice first
		cleanupDice()
		-- If triggered by spacebar or lag, spawn it now
		activeDice.Player = spawn3NDice(myDiceOffset)
		task.wait(0.5) -- Short spin time
		if activeDice.Player then activeDice.Player.Stop(myRoll or 1) end
	end

	task.wait(1.0)

	sendMsg("🎲 " .. (enemyName or "Enemy") .. " is rolling...", Color3.fromRGB(255, 100, 100))
	activeDice.Enemy = spawn3NDice(enemyDiceOffset)
	task.wait(1.2)
	if activeDice.Enemy then activeDice.Enemy.Stop(enemyRoll or 1) end

	task.wait(1.5)

	-- Show battle result banner ONLY when battle is actually over (HP = 0)
	if winner ~= "Draw" and battleOver and vsFrame then
		local iWon = false
		if currentBattleData then
			if currentBattleData.Type == "PvE" then
				iWon = (winner == "Player")
			elseif currentBattleData.Type == "PvP" then
				local myRole = (player == currentBattleData.Attacker) and "Attacker" or "Defender"
				iWon = (winner == myRole)
			end
		end

		local resultBanner = Instance.new("TextLabel")
		resultBanner.Name = "ResultBanner"
		resultBanner.Size = UDim2.new(0.5, 0, 0.12, 0)
		resultBanner.Position = UDim2.new(0.25, 0, 0.35, 0)
		resultBanner.BackgroundTransparency = 0.15
		resultBanner.Font = Enum.Font.FredokaOne
		resultBanner.TextSize = 48
		resultBanner.TextScaled = true
		resultBanner.TextStrokeTransparency = 0
		resultBanner.Parent = screenGui
		Instance.new("UICorner", resultBanner).CornerRadius = UDim.new(0, 16)

		if iWon then
			resultBanner.Text = "🏆 YOU WIN!"
			resultBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
			resultBanner.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
		else
			resultBanner.Text = "💀 YOU LOSE..."
			resultBanner.TextColor3 = Color3.fromRGB(255, 80, 80)
			resultBanner.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
		end

		-- Spectator sees winner name
		if currentBattleData and currentBattleData.IsSpectator then
			local winnerName = ""
			if currentBattleData.Type == "PvE" then
				winnerName = (winner == "Player") and currentBattleData.MyStats.Name or currentBattleData.EnemyStats.Name
			elseif currentBattleData.Type == "PvP" then
				winnerName = (winner == "Attacker") and currentBattleData.Attacker.Name or currentBattleData.Defender.Name
			end
			resultBanner.Text = "🏆 " .. winnerName .. " WINS!"
			resultBanner.TextColor3 = Color3.fromRGB(255, 215, 0)
			resultBanner.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
		end

		Debris:AddItem(resultBanner, 3)
	end

	-- Always show roll button if battle is active and NOT resolved (for next round)
	if isBattleActive and not battleResolved and rollBtn then
		rollBtn.Visible = true
		rollBtn.Text = "🎲 ROLL AGAIN"
		rollBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	end

	if winner == "Draw" then
		sendMsg("It's a Draw! Roll again!", Color3.fromRGB(200, 200, 200))
	else
		-- Show Damage
		local iWon = false
		if currentBattleData.Type == "PvE" then iWon = (winner == "Player")
		elseif currentBattleData.Type == "PvP" then
			local myRole = (player == currentBattleData.Attacker) and "Attacker" or "Defender"
			iWon = (winner == myRole)
		end

		if iWon then
			sendMsg("You hit for " .. damage .. " damage! 💥", Color3.fromRGB(100, 255, 100))
		else
			sendMsg("You took " .. damage .. " damage! 🛡️", Color3.fromRGB(255, 100, 100))
		end

		-- Update HP Bar
		if vsFrame and details and currentBattleData then
			local function updateSide(sideName, currentHP, maxHP)
				local container = vsFrame:FindFirstChild(sideName)
				if container then
					local hpBg = container:FindFirstChild("HP_BG")
					local hpFill = hpBg and hpBg:FindFirstChild("HP_Fill")
					local hpText = hpBg and hpBg:FindFirstChild("HP_Text")

					if hpFill and hpText then
						local pct = math.clamp(currentHP / maxHP, 0, 1)
						-- Animate
						hpFill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)

						if currentHP <= 0 then currentHP = 0 end
						hpText.Text = currentHP .. "/" .. maxHP

						if pct > 0.5 then hpFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
						elseif pct > 0.2 then hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
						else hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) end
					end
				end
			end

			local myNewHP, enemyNewHP, myMaxHP, enemyMaxHP
			if currentBattleData.Type == "PvE" then
				myNewHP = details.PlayerHP
				enemyNewHP = details.EnemyHP
				myMaxHP = details.PlayerMaxHP or currentBattleData.MyStats.MaxHP
				enemyMaxHP = details.EnemyMaxHP or currentBattleData.EnemyStats.MaxHP
			elseif currentBattleData.Type == "PvP" then
				if player == currentBattleData.Attacker then
					myNewHP = details.AttackerHP
					enemyNewHP = details.DefenderHP
					myMaxHP = details.AttackerMaxHP or currentBattleData.MyStats.MaxHP
					enemyMaxHP = details.DefenderMaxHP or currentBattleData.EnemyStats.MaxHP
				else
					myNewHP = details.DefenderHP
					enemyNewHP = details.AttackerHP
					myMaxHP = details.DefenderMaxHP or currentBattleData.MyStats.MaxHP
					enemyMaxHP = details.AttackerMaxHP or currentBattleData.EnemyStats.MaxHP
				end
			end

			if myNewHP then updateSide("Left", myNewHP, myMaxHP) end
			if enemyNewHP then updateSide("Right", enemyNewHP, enemyMaxHP) end
		end
	end
end)

-- Battle End
Events.BattleEnd.OnClientEvent:Connect(function(result)
	isBattleActive = false
	isRolling = false -- Reset rolling state
	battleResolved = false
	currentBattleData = nil

	-- Safe cleanup of UI
	if rollBtn then 
		rollBtn.Visible = false 
	end
	if vsFrame then 
		vsFrame:Destroy() 
		vsFrame = nil 
	end

	-- Cleanup any remaining dice
	cleanupDice()

	local msgText = result
	local msgColor = Color3.fromRGB(255, 255, 255)

	if string.find(result, "Win") or string.find(result, "defeated") then
		msgColor = Color3.fromRGB(255, 215, 0) -- Gold
	elseif string.find(result, "knocked out") then
		msgColor = Color3.fromRGB(255, 100, 100) -- Red
	end

	sendMsg(msgText, msgColor)

	-- NOTE: Result banner is already shown in BattleAttack handler (lines 455-490)
	-- Removed duplicate result label to prevent showing win/lose message twice
end)

-- Battle Start
Events.BattleStart.OnClientEvent:Connect(function(type, data)
	-- Safety check
	if not data then 
		warn("⚠️ [BattleUI] Received nil battle data")
		return 
	end

	print("⚔️ [Client] Battle Started!", type)
	isBattleActive = true
	isRolling = false
	battleResolved = false
	currentBattleData = data

	createVSFrame()

	-- Populate Data
	if vsFrame and data then
		-- Player Side (Left)
		local mySide = vsFrame:FindFirstChild("Left")
		if mySide and data.MyStats then
			local nameLbl = mySide:FindFirstChild("NameLabel")
			local atkLbl = mySide:FindFirstChild("AttackLabel")
			local hpText = mySide:FindFirstChild("HP_BG"):FindFirstChild("HP_Text")
			local img = mySide:FindFirstChild("PokeImage")
			if nameLbl then nameLbl.Text = data.MyStats.Name end
			if atkLbl then atkLbl.Text = "⚔️ " .. (data.MyStats.Attack or 0) end
			if hpText then hpText.Text = data.MyStats.CurrentHP .. "/" .. data.MyStats.MaxHP end

			if img then
				local db = PokemonDB.GetPokemon(data.MyStats.Name)
				if db and db.Icon then img.Image = db.Icon end
			end
		end

		-- Enemy Side (Right)
		local enemySide = vsFrame:FindFirstChild("Right")
		if enemySide and data.EnemyStats then
			local nameLbl = enemySide:FindFirstChild("NameLabel")
			local atkLbl = enemySide:FindFirstChild("AttackLabel")
			local hpText = enemySide:FindFirstChild("HP_BG"):FindFirstChild("HP_Text")
			local img = enemySide:FindFirstChild("PokeImage")
			if nameLbl then nameLbl.Text = data.EnemyStats.Name end
			if atkLbl then atkLbl.Text = "⚔️ " .. (data.EnemyStats.Attack or 0) end
			if hpText then hpText.Text = data.EnemyStats.CurrentHP .. "/" .. data.EnemyStats.MaxHP end

			if img then
				local db = PokemonDB.GetPokemon(data.EnemyStats.Name)
				if db and db.Icon then img.Image = db.Icon end
			end
		end
	end

	-- Check if spectator mode
	local isSpectator = data.IsSpectator or false

	if isSpectator then
		-- Add spectator label
		local spectatorLabel = Instance.new("TextLabel")
		spectatorLabel.Name = "SpectatorLabel"
		spectatorLabel.Text = "👁️ Spectating Battle"
		spectatorLabel.Size = UDim2.new(0, 300, 0, 40)
		spectatorLabel.Position = UDim2.new(0.5, -150, 0, 10)
		spectatorLabel.AnchorPoint = Vector2.new(0.5, 0)
		spectatorLabel.BackgroundTransparency = 0.3
		spectatorLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		spectatorLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		spectatorLabel.Font = Enum.Font.GothamBold
		spectatorLabel.TextScaled = true
		spectatorLabel.Parent = screenGui

		-- Hide roll button for spectators
		rollBtn.Visible = false
		sendMsg("Spectating battle...", Color3.fromRGB(200, 200, 200))
	else
		-- Active player
		rollBtn.Visible = true
		sendMsg("Battle Start! Roll needed: " .. (data.Target or "?"), Color3.fromRGB(255, 255, 100))
	end
end)

-- Battle Trigger (Selection UI)
Events.BattleTrigger.OnClientEvent:Connect(function(type, data)
	print("⚔️ [Client] BattleTrigger Received! Type:", type)

	local choiceFrame = Instance.new("Frame")
	choiceFrame.Size = UDim2.new(0, 300, 0, 150)
	choiceFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	choiceFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	choiceFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	choiceFrame.BorderSizePixel = 0
	choiceFrame.Parent = screenGui
	Instance.new("UICorner", choiceFrame).CornerRadius = UDim.new(0, 12)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 20
	title.Parent = choiceFrame

	if type == "PvE" then
		title.Text = "Gym Battle! Fight?"
	elseif type == "PvP" then
		title.Text = "Player Encounter! Battle?"
	end

	local fightBtn = Instance.new("TextButton")
	fightBtn.Size = UDim2.new(0, 120, 0, 50)
	fightBtn.Position = UDim2.new(0, 20, 1, -60)
	fightBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	fightBtn.Text = "⚔️ FIGHT"
	fightBtn.Font = Enum.Font.FredokaOne
	fightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	fightBtn.Parent = choiceFrame
	Instance.new("UICorner", fightBtn).CornerRadius = UDim.new(0, 8)

	local runBtn = Instance.new("TextButton")
	runBtn.Size = UDim2.new(0, 120, 0, 50)
	runBtn.Position = UDim2.new(1, -140, 1, -60)
	runBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	runBtn.Text = "🏃 RUN"
	runBtn.Font = Enum.Font.FredokaOne
	runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	runBtn.Parent = choiceFrame
	Instance.new("UICorner", runBtn).CornerRadius = UDim.new(0, 8)

	fightBtn.MouseButton1Click:Connect(function()
		choiceFrame.Visible = false

		-- OPEN SELECTION UI
		local inventory = player:FindFirstChild("PokemonInventory")
		local pokemons = inventory and inventory:GetChildren() or {}

		local alivePokemons = {}
		for _, poke in ipairs(pokemons) do
			if poke:GetAttribute("Status") == "Alive" then
				table.insert(alivePokemons, poke)
			end
		end

		if #alivePokemons == 0 then
			local warnFrame = Instance.new("Frame")
			warnFrame.Size = UDim2.new(0, 320, 0, 180)
			warnFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			warnFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			warnFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
			warnFrame.BorderSizePixel = 0
			warnFrame.Parent = screenGui
			Instance.new("UICorner", warnFrame).CornerRadius = UDim.new(0, 12)
			Instance.new("UIStroke", warnFrame).Color = Color3.fromRGB(255, 50, 50)
			Instance.new("UIStroke", warnFrame).Thickness = 2

			local warnText = Instance.new("TextLabel")
			warnText.Text = "🚫 NO POKEMON AVAILABLE!\n\nAll your Pokemon are fainted.\nYou cannot fight right now!"
			warnText.Size = UDim2.new(0.9, 0, 0.6, 0)
			warnText.Position = UDim2.new(0.05, 0, 0.1, 0)
			warnText.BackgroundTransparency = 1
			warnText.TextColor3 = Color3.fromRGB(255, 100, 100)
			warnText.Font = Enum.Font.FredokaOne
			warnText.TextSize = 20
			warnText.TextWrapped = true
			warnText.Parent = warnFrame

			local forceRunBtn = Instance.new("TextButton")
			forceRunBtn.Size = UDim2.new(0, 140, 0, 45)
			forceRunBtn.Position = UDim2.new(0.5, -70, 0.75, 0)
			forceRunBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
			forceRunBtn.Text = "🏃 RUN AWAY"
			forceRunBtn.Font = Enum.Font.FredokaOne
			forceRunBtn.TextSize = 18
			forceRunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			forceRunBtn.Parent = warnFrame
			Instance.new("UICorner", forceRunBtn).CornerRadius = UDim.new(0, 8)

			forceRunBtn.MouseButton1Click:Connect(function()
				warnFrame:Destroy()
				Events.BattleTriggerResponse:FireServer("Run", nil)
			end)
			return
		end

		local selFrame = Instance.new("Frame")
		selFrame.Size = UDim2.new(0, 400, 0, 300)
		selFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		selFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		selFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		selFrame.BorderSizePixel = 0
		selFrame.Parent = screenGui
		Instance.new("UICorner", selFrame).CornerRadius = UDim.new(0, 12)

		local selTitle = Instance.new("TextLabel")
		selTitle.Size = UDim2.new(1, 0, 0, 50)
		selTitle.BackgroundTransparency = 1
		selTitle.Text = "Choose your Pokemon!"
		selTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		selTitle.Font = Enum.Font.FredokaOne
		selTitle.TextSize = 24
		selTitle.Parent = selFrame

		local scroll = Instance.new("ScrollingFrame")
		scroll.Size = UDim2.new(0.9, 0, 0.7, 0)
		scroll.Position = UDim2.new(0.05, 0, 0.2, 0)
		scroll.BackgroundTransparency = 1
		scroll.Parent = selFrame

		local layout = Instance.new("UIListLayout")
		layout.Parent = scroll
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		for _, poke in ipairs(alivePokemons) do
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0.9, 0, 0, 50)
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.Text = "  " .. poke.Name .. " (HP: " .. (poke:GetAttribute("CurrentHP") or "?") .. ")"
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.FredokaOne
			btn.TextSize = 18
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Parent = scroll
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

			btn.MouseButton1Click:Connect(function()
				selFrame:Destroy()
				choiceFrame:Destroy()

				local responseData = { Type = type, SelectedPokemonName = poke.Name }
				if type == "PvP" and data and data.Opponents then
					responseData.Target = data.Opponents[1]
				end
				Events.BattleTriggerResponse:FireServer("Fight", responseData)
			end)
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, #alivePokemons * 60)
	end)

	runBtn.MouseButton1Click:Connect(function()
		choiceFrame:Destroy()
		Events.BattleTriggerResponse:FireServer("Run", nil)
	end)
end)
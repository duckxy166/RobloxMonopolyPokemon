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

local player = Players.LocalPlayer
-- local EventManager = require(game.ReplicatedStorage:WaitForChild("EventManager")) -- REMOVED: Server module not available to client

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

local rollBtn = Instance.new("TextButton")
rollBtn.Name = "RollButton"
rollBtn.Size = UDim2.new(0.3, 0, 0.1, 0)
rollBtn.Position = UDim2.new(0.35, 0, 0.65, 0) -- Moved UP (above VS Bar)
rollBtn.Text = "🎲 ROLL ATTACK"
rollBtn.Font = Enum.Font.FredokaOne
rollBtn.TextSize = 24
rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rollBtn.Visible = false
rollBtn.ZIndex = 10 -- Ensure it's on top
rollBtn.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = rollBtn

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 100, 50)
stroke.Parent = rollBtn

-- State
local isBattleActive = false
local isRolling = false
local currentBattleData = nil
local vsFrame = nil

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

	-- VS Text
	local vsLabel = Instance.new("TextLabel")
	vsLabel.Text = "VS"
	vsLabel.Size = UDim2.new(0.1, 0, 1, 0)
	vsLabel.Position = UDim2.new(0.45, 0, 0, 0)
	vsLabel.BackgroundTransparency = 1
	vsLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	vsLabel.Font = Enum.Font.FredokaOne
	vsLabel.TextSize = 32
	vsLabel.Parent = vsFrame

	-- Helper to create side
	local function createSide(parent, side, color)
		local container = Instance.new("Frame")
		container.Name = side
		container.Size = UDim2.new(0.45, 0, 1, 0)
		container.Position = side == "Left" and UDim2.new(0, 0, 0, 0) or UDim2.new(0.55, 0, 0, 0)
		container.BackgroundTransparency = 1
		container.Parent = parent

		-- Pokemon Image (Placeholder rect)
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

		-- HP Bar
		local hpBg = Instance.new("Frame")
		hpBg.Name = "HP_BG"
		hpBg.Size = UDim2.new(0.6, 0, 0.2, 0)
		hpBg.Position = side == "Left" and UDim2.new(0.35, 0, 0.5, 0) or UDim2.new(0.05, 0, 0.5, 0)
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

-- [[ 3D DICE LOGIC ]] --
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

-- Spawn and Animate a single 3D Die
local function spawn3NDice(sideOffset)
	local dice
	if diceTemplate then 
		dice = diceTemplate:Clone() 
	else 
		dice = Instance.new("Part")
		dice.Size = Vector3.new(3,3,3) 
		dice.Color = Color3.fromRGB(240, 240, 240)
		-- Add text faces if generic part
		for _, face in pairs(Enum.NormalId:GetEnumItems()) do
			local s = Instance.new("SurfaceGui", dice)
			s.Face = face
			local t = Instance.new("TextLabel", s)
			t.Size = UDim2.new(1,0,1,0)
			t.BackgroundTransparency = 1
			t.Text = math.random(1,6) 
			t.TextScaled = true
		end
	end

	dice.Parent = workspace
	dice.Anchored = true
	dice.CanCollide = false

	-- Position in front of camera
	-- sideOffset: -1 for left (Player), 1 for right (Enemy)
	local startCF = camera.CFrame * CFrame.new(sideOffset * 4, -2, -8) -- 4 studs left/right, 2 down, 8 forward
	dice.CFrame = startCF

	-- Spin Animation
	local connection
	local spinSpeed = Vector3.new(math.random(300,700), math.random(300,700), math.random(300,700))
	connection = RunService.RenderStepped:Connect(function(dt)
		if not dice.Parent then connection:Disconnect() return end
		dice.CFrame = dice.CFrame * CFrame.Angles(math.rad(spinSpeed.X*dt), math.rad(spinSpeed.Y*dt), math.rad(spinSpeed.Z*dt))
	end)

	-- Return object to control externally or handle lifecycle here
	return {
		Object = dice,
		Stop = function(finalVal)
			if connection then connection:Disconnect() end

			-- Tween to result
			local finalCF = camera.CFrame * CFrame.new(sideOffset * 4, -2, -8) -- End at same spot roughly
			-- Look at camera
			-- Apply face rotation
			local targetOri = CFrame.lookAt(finalCF.Position, camera.CFrame.Position) * ROTATION_OFFSETS[finalVal]

			local tw = TweenService:Create(dice, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = targetOri
			})
			tw:Play()

			-- Cleanup after show
			task.delay(3, function()
				dice:Destroy()
			end)
		end
	}
end

-- Replaces createDiceUI (No setup needed for 3D)
local function createDiceUI() 
	-- No-op or cleanup 2D
	if leftDice then leftDice:Destroy() leftDice = nil end
	if rightDice then rightDice:Destroy() rightDice = nil end
end

-- Helper: Animate Dice (Now triggers 3D)
-- We don't need persistent loop, we launch per attack.
local function startRollingAnim()
	-- Does nothing now, animation starts on result or we simulate here?
	-- Current flow: 1. Click Roll -> 2. startRollingAnim -> 3. FireServer -> 4. Receive Result -> 5. stopRollingAnim
	-- For 3D:
	-- 1. Click Roll -> show spinning 3D dice indefinitely?
	-- 2. Receive Result -> Tween and stop.

	-- Actually, let's start the 3D spin on click, and just hold the reference.
	-- We need module-level refs to stop them.
end

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

	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
		-- Attack
		if not isRolling then
			isRolling = true
			sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))
			Events.BattleAttack:FireServer()
		end
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- Touch Attack
		if not isRolling then
			isRolling = true
			sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))
			Events.BattleAttack:FireServer()
		end
	end
end)

-- Button Handler
rollBtn.MouseButton1Click:Connect(function()
	if not isBattleActive or isRolling then return end
	isRolling = true
	rollBtn.Visible = false -- Hide button while rolling (like HUD)
	-- rollBtn.Text = "Rolling..."
	-- rollBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)

	sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))

	-- Start 3D Spin
	cleanupDice() -- Clear old
	activeDice.Player = spawn3NDice(-1) -- -1 Left
	-- activeDice.Enemy = spawn3NDice(1)   -- 1 Right (Moved to Event for Sequential)

	Events.BattleAttack:FireServer()
end)

-- Battle Start
-- Battle Update (Damage)
Events.BattleAttack.OnClientEvent:Connect(function(winner, damage, details)
	isRolling = false

	-- ... (ส่วน Logic การทอยลูกเต๋า 3D Dice เหมือนเดิม) ...
	local myRoll = 0
	local enemyRoll = 0
	local myName = player.Name
	local enemyName = "Enemy"

	if details then
		if currentBattleData.Type == "PvP" then
			if player == currentBattleData.Attacker then
				myRoll = details.AttackerRoll; enemyRoll = details.DefenderRoll; enemyName = currentBattleData.Defender.Name
			else
				myRoll = details.DefenderRoll; enemyRoll = details.AttackerRoll; enemyName = currentBattleData.Attacker.Name
			end
		else
			myRoll = details.PlayerRoll; enemyRoll = details.EnemyRoll; enemyName = currentBattleData.EnemyStats.Name
		end
	end

	cleanupDice()

	-- Step A: Player Rolls
	sendMsg("🎲 " .. myName .. " is rolling...", Color3.fromRGB(100, 255, 255))
	activeDice.Player = spawn3NDice(-1)
	task.wait(1.2)
	if activeDice.Player then activeDice.Player.Stop(myRoll) end

	task.wait(1.0)

	-- Step B: Enemy Rolls
	sendMsg("🎲 " .. enemyName .. " is rolling...", Color3.fromRGB(255, 100, 100))
	activeDice.Enemy = spawn3NDice(1)
	task.wait(1.2)
	if activeDice.Enemy then activeDice.Enemy.Stop(enemyRoll) end

	task.wait(1.5)

	if isBattleActive then
		rollBtn.Visible = true
		rollBtn.Text = "🎲 ROLL ATTACK"
		rollBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	end

	-- === [แก้ไขจุดที่ 1: การแสดงผล] ===
	if winner == "Draw" then
		sendMsg("It's a Draw! Roll again!", Color3.fromRGB(200, 200, 200))
	else
		-- แสดง Damage
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

		-- Update HP Bar (Smooth Update, Don't show DEAD yet)
		if vsFrame and details and currentBattleData then
			local function updateSide(sideName, currentHP, maxHP)
				local container = vsFrame:FindFirstChild(sideName)
				if container then
					local hpBg = container:FindFirstChild("HP_BG")
					local hpFill = hpBg and hpBg:FindFirstChild("HP_Fill")
					local hpText = hpBg and hpBg:FindFirstChild("HP_Text")

					if hpFill and hpText then
						local pct = math.clamp(currentHP / maxHP, 0, 1)
						-- อนิเมชั่นลดเลือด
						hpFill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5, true)

						-- แสดงตัวเลข 0/100 ได้ แต่ห้ามขึ้น Text ว่า "DEAD"
						if currentHP <= 0 then currentHP = 0 end
						hpText.Text = currentHP .. "/" .. maxHP

						if pct > 0.5 then hpFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
						elseif pct > 0.2 then hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
						else hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) end
					end
				end
			end

			-- Logic ดึงค่า HP จาก details มาอัปเดต (เหมือนเดิมแต่ตัดส่วนแจ้งตายออก)
			local myNewHP, enemyNewHP
			if currentBattleData.Type == "PvE" then
				myNewHP = details.PlayerHP; enemyNewHP = details.EnemyHP
			elseif currentBattleData.Type == "PvP" then
				if player == currentBattleData.Attacker then
					myNewHP = details.AttackerHP; enemyNewHP = details.DefenderHP
				else
					myNewHP = details.DefenderHP; enemyNewHP = details.AttackerHP
				end
			end

			if myNewHP then updateSide("Left", myNewHP, currentBattleData.MyStats.MaxHP) end
			if enemyNewHP then updateSide("Right", enemyNewHP, currentBattleData.EnemyStats.MaxHP) end
		end
	end
end)

-- Battle End
Events.BattleEnd.OnClientEvent:Connect(function(result)
	isBattleActive = false
	currentBattleData = nil
	if vsFrame then vsFrame:Destroy() vsFrame = nil end
	rollBtn.Visible = false

	-- === [แก้ไขจุดที่ 2: แสดงผลแพ้ชนะง่ายๆ] ===
	local msgText = ""
	local msgColor = Color3.fromRGB(255, 255, 255)

	if result == "Win" or result == "AttackerWin" or result == "DefenderWin" then
		-- เช็คว่าเป็นเราชนะไหม (กรณี PvP ต้องเช็ค Role แต่ถ้า PvE คือ Win แน่นอน)
		-- เพื่อความง่าย: ถ้า Server ส่ง Win มาหาเรา แสดงว่าเราชนะ (ใน BattleSystem.lua ส่ง Win ให้ผู้ชนะ)
		if result == "Win" then
			msgText = "🏆 YOU WIN! 🏆"
			msgColor = Color3.fromRGB(50, 255, 100)
		elseif result == "Lose" then
			msgText = "💀 YOU LOSE... 💀"
			msgColor = Color3.fromRGB(255, 50, 50)
		else
			-- PvP (Server อาจส่ง string อื่นมา เช็คตามบริบท)
			msgText = "🏁 BATTLE ENDED: " .. result
		end
	else
		msgText = "🏁 BATTLE ENDED: " .. result
	end

	-- ส่งข้อความใหญ่กลางจอ หรือ Chat
	sendMsg(msgText, msgColor)

	-- (Optional) สร้าง TextLabel กลางจอชั่วคราว
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Size = UDim2.new(1, 0, 0.2, 0)
	resultLabel.Position = UDim2.new(0, 0, 0.4, 0)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Text = msgText
	resultLabel.Font = Enum.Font.FredokaOne
	resultLabel.TextSize = 48
	resultLabel.TextColor3 = msgColor
	resultLabel.TextStrokeTransparency = 0
	resultLabel.Parent = screenGui

	game:GetService("Debris"):AddItem(resultLabel, 3) -- ลบใน 3 วินาที
end)

-- Battle Start (Single Source of Truth)
Events.BattleStart.OnClientEvent:Connect(function(type, data)
	print("⚔️ [Client] Battle Started!", type)
	isBattleActive = true
	isRolling = false
	currentBattleData = data

	-- Create VS UI
	createVSFrame()
	createDiceUI() -- Create Dice Containers

	-- Populate Data
	if vsFrame and data then
		-- Player Side (Left)
		local mySide = vsFrame:FindFirstChild("Left")
		if mySide and data.MyStats then
			local nameLbl = mySide:FindFirstChild("NameLabel")
			local hpText = mySide:FindFirstChild("HP_BG"):FindFirstChild("HP_Text")
			local img = mySide:FindFirstChild("PokeImage")
			if nameLbl then nameLbl.Text = data.MyStats.Name end
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
			local hpText = enemySide:FindFirstChild("HP_BG"):FindFirstChild("HP_Text")
			local img = enemySide:FindFirstChild("PokeImage")
			if nameLbl then nameLbl.Text = data.EnemyStats.Name end
			if hpText then hpText.Text = data.EnemyStats.CurrentHP .. "/" .. data.EnemyStats.MaxHP end

			if img then
				local db = PokemonDB.GetPokemon(data.EnemyStats.Name)
				if db and db.Icon then img.Image = db.Icon end
			end
		end
	end



	rollBtn.Visible = true
	sendMsg("Battle Start! Roll needed: " .. (data.Target or "?"), Color3.fromRGB(255, 255, 100))
end)
Events.BattleTrigger.OnClientEvent:Connect(function(type, data)
	print("⚔️ [Client] BattleTrigger Received! Type:", type)

	-- Create a temporary Choice UI
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


	-- Logic
	-- Logic
	fightBtn.MouseButton1Click:Connect(function()
		-- Close Choice Frame
		choiceFrame.Visible = false 

		-- OPEN SELECTION UI
		local inventory = player:FindFirstChild("PokemonInventory")
		local pokemons = inventory and inventory:GetChildren() or {}

		-- Filter Alive Pokemon
		local alivePokemons = {}
		for _, poke in ipairs(pokemons) do
			if poke:GetAttribute("Status") == "Alive" then
				table.insert(alivePokemons, poke)
			end
		end

		-- Create Selection Frame
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

		-- Generate Buttons
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

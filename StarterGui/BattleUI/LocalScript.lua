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
local StarterGui = game:GetService("StarterGui")

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
rollBtn.Position = UDim2.new(0.35, 0, 0.85, 0) -- Bottom Center
rollBtn.Text = "🎲 ROLL ATTACK"
rollBtn.Font = Enum.Font.FredokaOne
rollBtn.TextSize = 24
rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
rollBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rollBtn.Visible = false
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
	vsFrame.Size = UDim2.new(0.8, 0, 0.15, 0)
	vsFrame.Position = UDim2.new(0.1, 0, 0.82, 0) -- Bottom center
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
	rollBtn.Text = "Rolling..."
	rollBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	sendMsg("Rolling dice... 🎲", Color3.fromRGB(255, 255, 100))
	Events.BattleAttack:FireServer()
end)

-- Battle Start
-- Battle Update (Damage)
Events.BattleAttack.OnClientEvent:Connect(function(winner, damage, details)
	isRolling = false
	rollBtn.Text = "🎲 ROLL ATTACK"
	rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)

	if winner == "Draw" then
		sendMsg("It's a Draw! Roll again!", Color3.fromRGB(200, 200, 200))
	else
		local iWon = false
		if currentBattleData.Type == "PvE" then
			iWon = (winner == "Player")
		elseif currentBattleData.Type == "PvP" then
			local myRole = (player == currentBattleData.Attacker) and "Attacker" or "Defender"
			iWon = (winner == myRole)
		end

		if iWon then
			sendMsg("You hit for " .. damage .. " damage! 💥", Color3.fromRGB(100, 255, 100))
		else
			sendMsg("You took " .. damage .. " damage! 🛡️", Color3.fromRGB(255, 100, 100))
		end
		
		-- UPDATE VS UI
		if vsFrame and details then
			local function updateSide(sideName, stats)
				local container = vsFrame:FindFirstChild(sideName)
				if container and stats then
					local hpBg = container:FindFirstChild("HP_BG")
					local hpFill = hpBg and hpBg:FindFirstChild("HP_Fill")
					local hpText = hpBg and hpBg:FindFirstChild("HP_Text")
					
					if hpFill and hpText then
						local pct = math.clamp(stats.CurrentHP / stats.MaxHP, 0, 1)
						hpFill:TweenSize(UDim2.new(pct, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
						hpText.Text = stats.CurrentHP .. "/" .. stats.MaxHP
						
						-- Color
						if pct > 0.5 then hpFill.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
						elseif pct > 0.2 then hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
						else hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) end
					end
				end
			end
			
			-- Update Stats from Server Details
			-- PvE Keys: PlayerHP, EnemyHP
			-- PvP Keys: AttackerHP, DefenderHP
			
			local myNewHP = nil
			local enemyNewHP = nil
			
			if currentBattleData.Type == "PvE" then
				myNewHP = details.PlayerHP
				enemyNewHP = details.EnemyHP
			elseif currentBattleData.Type == "PvP" then
				if player == currentBattleData.Attacker then
					myNewHP = details.AttackerHP
					enemyNewHP = details.DefenderHP
				else
					myNewHP = details.DefenderHP
					enemyNewHP = details.AttackerHP
				end
			end
			
			-- Update UI
			if myNewHP then
				local max = currentBattleData.MyStats.MaxHP
				local stats = { CurrentHP = myNewHP, MaxHP = max }
				updateSide("Left", stats)
				-- Update local data ref
				currentBattleData.MyStats.CurrentHP = myNewHP
			end
			
			if enemyNewHP then
				local max = currentBattleData.EnemyStats.MaxHP
				local stats = { CurrentHP = enemyNewHP, MaxHP = max }
				updateSide("Right", stats)
				-- Update local data ref
				currentBattleData.EnemyStats.CurrentHP = enemyNewHP
			end
		end
	end
end)

-- Battle End
Events.BattleEnd.OnClientEvent:Connect(function(result)
	isBattleActive = false
	currentBattleData = nil
	-- Clean up UI
	if vsFrame then vsFrame:Destroy() vsFrame = nil end
	
	rollBtn.Visible = false
	sendMsg("Battle Ended: " .. result, Color3.fromRGB(255, 255, 255))
end)

-- Battle Start (Single Source of Truth)
Events.BattleStart.OnClientEvent:Connect(function(type, data)
	print("⚔️ [Client] Battle Started!", type)
	isBattleActive = true
	isRolling = false
	currentBattleData = data
	
	-- Create VS UI
	createVSFrame()
	
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
end

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
local EventManager = require(game.ReplicatedStorage:WaitForChild("EventManager")) -- Or just get events directly

-- Events
local Events = {
	BattleStart = ReplicatedStorage:WaitForChild("BattleStartEvent"),
	BattleAttack = ReplicatedStorage:WaitForChild("BattleAttackEvent"),
	BattleEnd = ReplicatedStorage:WaitForChild("BattleEndEvent"),
	Notify = ReplicatedStorage:WaitForChild("NotifyEvent") -- If exists
}

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
Events.BattleStart.OnClientEvent:Connect(function(type, data)
	currentBattleData = data
	isBattleActive = true
	isRolling = false
	
	print("⚔️ Battle Mode Activated (No UI)")
	
	rollBtn.Visible = true
	rollBtn.Text = "🎲 ROLL ATTACK"
	rollBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	
	if type == "PvE" then
		sendMsg("Wild " .. data.EnemyStats.Name .. " appeared! Press SPACE to Battle!", Color3.fromRGB(255, 50, 50))
	elseif type == "PvP" then
		local opponent = (player == data.Attacker) and data.Defender or data.Attacker
		sendMsg("PvP Started against " .. opponent.Name .. "! Press SPACE to Battle!", Color3.fromRGB(255, 50, 50))
	elseif type == "SelectOpponent" then
		-- Auto-select or just prompt for now
		sendMsg("Opponent selection pending...", Color3.fromRGB(255, 200, 50))
	end
end)

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
	end
end)

-- Battle End
Events.BattleEnd.OnClientEvent:Connect(function(result)
	isBattleActive = false
	currentBattleData = nil
	rollBtn.Visible = false
	sendMsg("Battle Ended: " .. result, Color3.fromRGB(255, 255, 255))
end)

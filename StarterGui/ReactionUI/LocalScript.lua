--[[
================================================================================
                      🛡️ REACTION UI (COUNTER SYSTEM)
================================================================================
    📌 Location: StarterGui/ReactionUI/LocalScript
    📌 Responsibilities:
        - Handle RequestReactionFunction from Server
        - Show "Use Safety Goggles?" prompt
        - Return decision to server
================================================================================
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local requestFunction = ReplicatedStorage:WaitForChild("RequestReactionFunction")

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReactionGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.IgnoreGuiInset = true 
screenGui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.6
bg.Parent = screenGui

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 400, 0, 250)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
container.Parent = bg
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", container).Color = Color3.fromRGB(255, 100, 100)
Instance.new("UIStroke", container).Thickness = 3

local title = Instance.new("TextLabel")
title.Text = "⚠️ DEFENSE ALERT!"
title.Size = UDim2.new(1, 0, 0.25, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.Font = Enum.Font.FredokaOne
title.TextSize = 28
title.Parent = container

local desc = Instance.new("TextLabel")
desc.Name = "Description"
desc.Text = "You are being attacked!\nUse Safety Goggles to block?"
desc.Size = UDim2.new(0.9, 0, 0.3, 0)
desc.Position = UDim2.new(0.05, 0, 0.3, 0)
desc.BackgroundTransparency = 1
desc.TextColor3 = Color3.fromRGB(255, 255, 255)
desc.Font = Enum.Font.GothamMedium
desc.TextSize = 18
desc.TextWrapped = true
desc.Parent = container

local yesBtn = Instance.new("TextButton")
yesBtn.Text = "BLOCK (Safety Goggles)"
yesBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
yesBtn.Position = UDim2.new(0.05, 0, 0.7, 0)
yesBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
yesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
yesBtn.Font = Enum.Font.GothamBold
yesBtn.Parent = container
Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 8)

local noBtn = Instance.new("TextButton")
noBtn.Text = "TAKE HIT"
noBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
noBtn.Position = UDim2.new(0.55, 0, 0.7, 0)
noBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
noBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
noBtn.Font = Enum.Font.GothamBold
noBtn.Parent = container
Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 8)

-- Logic
local connectionYes, connectionNo
local decision = nil

requestFunction.OnClientInvoke = function(attackerName, cardName)
	-- Show UI
	desc.Text = attackerName .. " is using " .. cardName .. " on you!\nUse Safety Goggles?"
	screenGui.Enabled = true
	decision = nil
	
	-- Wait for input
	local waiting = true
	
	connectionYes = yesBtn.MouseButton1Click:Connect(function()
		decision = true
		waiting = false
	end)
	
	connectionNo = noBtn.MouseButton1Click:Connect(function()
		decision = false
		waiting = false
	end)
	
	-- Timeout mechanism (manual wait loop since we can't yield event easily otherwise)
	local timer = 10 -- 10 seconds to decide
	while waiting and timer > 0 do
		task.wait(0.1)
		timer -= 0.1
	end
	
	-- Cleanup
	if connectionYes then connectionYes:Disconnect() end
	if connectionNo then connectionNo:Disconnect() end
	screenGui.Enabled = false
	
	if decision == nil then decision = false end -- Default to False (No block) on timeout
	return decision
end

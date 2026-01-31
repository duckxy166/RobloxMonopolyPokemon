local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CardDB -- Lazy load

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local playCardEvent = ReplicatedStorage:WaitForChild("PlayCardEvent")
local discardCardEvent = ReplicatedStorage:WaitForChild("DiscardCardEvent")

-- [[ 🎨 CARD TEXTURE CONFIGURATION ]] --
-- Replace the IDs below with your uploaded asset IDs (rbxassetid://...)
local CARD_ASSETS = {
	["Potion"] = "rbxassetid://123456789", 
	["Super Potion"] = "rbxassetid://123456789",
	["Lucky Draw"] = "rbxassetid://123456789",
	["Nugget"] = "rbxassetid://123456789",
	["Robbery"] = "rbxassetid://123456789",
	["Push Back"] = "rbxassetid://123456789",
	["Sleep Powder"] = "rbxassetid://123456789",
	["Safety Shield"] = "rbxassetid://123456789",
	["Revive"] = "rbxassetid://123456789",
}
local DEFAULT_CARD_IMAGE = "rbxassetid://0" -- Placeholder if missing

-- 1. Create UI Elements Programmatically
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HandUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "CardHolder"
mainFrame.Size = UDim2.new(0.7, 0, 0.3, 0) -- Slightly larger for visibility
mainFrame.Position = UDim2.new(0.5, 0, 0.98, 0) -- Bottom Center
mainFrame.AnchorPoint = Vector2.new(0.5, 1) -- Anchored at bottom
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 1 -- Transparent container
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 100, 0, 140) -- Standard Card Size
gridLayout.CellPadding = UDim2.new(0, 15, 0, 0)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = mainFrame

-- Tooltip Label
local tooltip = Instance.new("TextLabel")
tooltip.Name = "Tooltip"
tooltip.Size = UDim2.new(0, 200, 0, 60)
tooltip.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tooltip.BackgroundTransparency = 0.2
tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
tooltip.Font = Enum.Font.GothamMedium
tooltip.TextSize = 14
tooltip.TextWrapped = true
tooltip.Visible = false
tooltip.ZIndex = 10
tooltip.Parent = screenGui

local tooltipCorner = Instance.new("UICorner")
tooltipCorner.CornerRadius = UDim.new(0, 8)
tooltipCorner.Parent = tooltip

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Thickness = 1
stroke.Parent = tooltip


-- 2. Function to Render Hand
local function renderHand()
	-- Clear existing
	for _, child in pairs(mainFrame:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end

	local hand = player:FindFirstChild("Hand")
	if not hand then return end

	-- List cards
	for i, cardVal in ipairs(hand:GetChildren()) do
		if cardVal:IsA("IntValue") then
			local count = cardVal.Value
			for j = 1, count do
				-- Card Container (Button)
				local cardBtn = Instance.new("ImageButton")
				cardBtn.Name = cardVal.Name
				cardBtn.LayoutOrder = i -- Keep order consistent

				-- Apply Texture
				local assetId = CARD_ASSETS[cardVal.Name] or DEFAULT_CARD_IMAGE
				cardBtn.Image = assetId
				cardBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				cardBtn.BorderSizePixel = 0

				-- Fallback style if no image
				if assetId == DEFAULT_CARD_IMAGE then
					cardBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				end

				cardBtn.Parent = mainFrame

				-- Round corners
				local uicorner = Instance.new("UICorner")
				uicorner.CornerRadius = UDim.new(0, 8)
				uicorner.Parent = cardBtn

				-- Stroke (Border)
				local stroke = Instance.new("UIStroke")
				stroke.Color = Color3.fromRGB(255, 255, 255)
				stroke.Thickness = 2
				stroke.Transparency = 0.5
				stroke.Parent = cardBtn

				-- Name Label (Overlay)
				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "Title"
				nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
				nameLabel.Position = UDim2.new(0, 0, 0.8, 0)
				nameLabel.BackgroundTransparency = 0.5
				nameLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.Text = cardVal.Name
				nameLabel.Font = Enum.Font.GothamBold
				nameLabel.TextScaled = true
				nameLabel.Parent = cardBtn

				-- Corner for label
				local labelCorner = Instance.new("UICorner")
				labelCorner.CornerRadius = UDim.new(0, 8)
				labelCorner.Parent = nameLabel

				-- Drop Button
				local dropBtn = Instance.new("TextButton")
				dropBtn.Name = "DropBtn"
				dropBtn.Size = UDim2.new(0, 20, 0, 20)
				dropBtn.Position = UDim2.new(1, -5, 0, 5)
				dropBtn.AnchorPoint = Vector2.new(1, 0)
				dropBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
				dropBtn.Text = "X"
				dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				dropBtn.Font = Enum.Font.GothamBold
				dropBtn.TextSize = 12
				dropBtn.ZIndex = 5
				dropBtn.Parent = cardBtn
				Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)

				dropBtn.MouseButton1Click:Connect(function()
					discardCardEvent:FireServer(cardVal.Name)
				end)

				-- Click Animation & Logic
				cardBtn.MouseButton1Click:Connect(function()
					print("Playing card: " .. cardVal.Name)

					-- Simple bounce animation
					local tween = TweenService:Create(cardBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 90, 0, 126)})
					tween:Play()
					tween.Completed:Wait()
					local tweenBack = TweenService:Create(cardBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 100, 0, 140)})
					tweenBack:Play()
					
					local cardData = CardDB.Cards[cardVal.Name]
					if cardData and cardData.NeedsTarget then
						-- Open Target Selection
						local targetBindable = ReplicatedStorage:FindFirstChild("Client_OpenCardTarget")
						if not targetBindable then
							targetBindable = Instance.new("BindableEvent")
							targetBindable.Name = "Client_OpenCardTarget"
							targetBindable.Parent = ReplicatedStorage
						end
						targetBindable:Fire(cardVal.Name)
					elseif cardData and cardData.NeedsSelfPokemon then
						-- Open Pokemon Selection
						local bindable = ReplicatedStorage:FindFirstChild("Client_OpenPokemonSelect")
						if not bindable then
							bindable = Instance.new("BindableEvent")
							bindable.Name = "Client_OpenPokemonSelect"
							bindable.Parent = ReplicatedStorage
						end
						bindable:Fire(cardVal.Name)
					else
						-- Play immediately
						playCardEvent:FireServer(cardVal.Name, nil) 
					end

					tooltip.Visible = false -- Hide tooltip on click
				end)

				-- Hover Animation & Tooltip
				cardBtn.MouseEnter:Connect(function()
					TweenService:Create(cardBtn, TweenInfo.new(0.2), {Position = UDim2.new(0, 0, -0.1, 0)}):Play() -- Move up slightly

					-- Show Tooltip
					local cardData = CardDB.Cards[cardVal.Name]
					if cardData then
						tooltip.Text = cardData.Name .. "\n\n" .. cardData.Description
						tooltip.Visible = true

						-- Follow mouse (rough position) or sticky
						-- Let's put it above the card for now
						local absPos = cardBtn.AbsolutePosition
						local absSize = cardBtn.AbsoluteSize
						tooltip.Position = UDim2.new(0, absPos.X + (absSize.X/2) - 100, 0, absPos.Y - 70)
					end
				end)

				cardBtn.MouseLeave:Connect(function()
					TweenService:Create(cardBtn, TweenInfo.new(0.2), {Position = UDim2.new(0, 0, 0, 0)}):Play() -- Return
					tooltip.Visible = false
				end)
			end
		end
	end
end

-- 3. Listen for Hand Changes
local function connectHandListener()
	-- Wait for Hand folder reliably (Server might create it slightly later)
	local hand = player:WaitForChild("Hand", 20) -- Wait up to 20 seconds
	
	if not hand then
		warn("⚠️ [HandUI] Hand folder not found after waiting. Retrying in 5 seconds...")
		task.delay(5, connectHandListener)
		return
	end

	print("✅ [HandUI] Hand folder connected.")
	hand.ChildAdded:Connect(renderHand)
	hand.ChildRemoved:Connect(renderHand)

	-- Also listen to value changes (if stack size changes)
	for _, child in pairs(hand:GetChildren()) do
		if child:IsA("IntValue") then
			child.Changed:Connect(renderHand)
		end
	end

	-- Initial render
	renderHand()
end


-- 4. Async Init
-- 4. Async Init
task.spawn(function()
	print("🃏 [HandUI] Waiting for CardDB...")
	local cardDBModule = ReplicatedStorage:WaitForChild("CardDB", 10)

	if cardDBModule then
		local success, result = pcall(function()
			return require(cardDBModule)
		end)

		if success then
			CardDB = result
			print("🃏 [HandUI] CardDB loaded successfully!")
		else
			warn("🃏 [HandUI] Failed to require CardDB: " .. tostring(result))
			-- Fallback dummy DB
			CardDB = { Cards = {} }
		end
	else
		warn("🃏 [HandUI] CardDB module not found in ReplicatedStorage!")
		CardDB = { Cards = {} }
	end

	connectHandListener()
	player.ChildAdded:Connect(function(child)
		if child.Name == "Hand" then
			connectHandListener()
		end
	end)

	-- Force check initially in case folder already exists
	if player:FindFirstChild("Hand") then
		renderHand()
	end
end)


-- 5. Auto-Hide Hand during Encounters
-- Prevents UI overlap when fighting Pokemon
local encounterEvent = ReplicatedStorage:FindFirstChild("EncounterEvent")
local updateTurnEvent = ReplicatedStorage:FindFirstChild("UpdateTurnEvent")
local runEvent = ReplicatedStorage:FindFirstChild("RunEvent")
local catchEvent = ReplicatedStorage:FindFirstChild("CatchPokemonEvent")

if encounterEvent then
	encounterEvent.OnClientEvent:Connect(function()
		screenGui.Enabled = false
	end)
end

if updateTurnEvent then
	updateTurnEvent.OnClientEvent:Connect(function()
		screenGui.Enabled = true
	end)
end

if runEvent then
	runEvent.OnClientEvent:Connect(function()
		task.wait(2)
		screenGui.Enabled = true
	end)
end

if catchEvent then
	catchEvent.OnClientEvent:Connect(function(_, success, _, _, isFinished)
		if isFinished then
			task.wait(2) 
			screenGui.Enabled = true
		end
	end)
end

-- 6. Hide on Roll
local rollDiceEvent = ReplicatedStorage:FindFirstChild("RollDiceEvent")
if rollDiceEvent then
	rollDiceEvent.OnClientEvent:Connect(function(rollingPlayer, roll)
		if rollingPlayer == player then
			screenGui.Enabled = false
		end
	end)
end

-- 6. Battle Hide/Show
local battleStart = ReplicatedStorage:FindFirstChild("BattleStartEvent")
local battleEnd = ReplicatedStorage:FindFirstChild("BattleEndEvent")

if battleStart then
	battleStart.OnClientEvent:Connect(function()
		screenGui.Enabled = false
	end)
end

if battleEnd then
	battleEnd.OnClientEvent:Connect(function()
		task.wait(1)
		screenGui.Enabled = true
	end)
end

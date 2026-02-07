--[[
================================================================================
                      💰 SELL UI CONTROLLER - Client Side
================================================================================
    📌 Location: StarterGui/SellUI/LocalScript
    📌 Responsibilities:
        - Display sellable Pokemon list
        - Show prices and Pokemon info
        - Handle sell button clicks
================================================================================
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load PokemonDB
local PokemonDB = require(ReplicatedStorage:WaitForChild("PokemonDB"))
local SoundManager = require(ReplicatedStorage:WaitForChild("SoundManager"))

-- Events
local sellUIEvent = ReplicatedStorage:WaitForChild("SellUIEvent", 10)
local sellPokemonEvent = ReplicatedStorage:WaitForChild("SellPokemonEvent", 10)
local sellUICloseEvent = ReplicatedStorage:WaitForChild("SellUICloseEvent", 10)

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SellUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Main Container
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 600, 0, 500)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
container.BorderSizePixel = 0
container.Parent = screenGui
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 20)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 200, 50)
stroke.Thickness = 3
stroke.Parent = container

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 60)
title.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
title.Text = "💰 SELL POKEMON"
title.Font = Enum.Font.FredokaOne
title.TextSize = 28
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = container
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 20)

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(200, 150, 0)
titleStroke.Thickness = 2
titleStroke.Parent = title

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 30)
subtitle.Position = UDim2.new(0, 20, 0, 70)
subtitle.BackgroundTransparency = 1
subtitle.Text = "⚠️ Only alive Pokemon can be sold!"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextColor3 = Color3.fromRGB(255, 200, 200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = container

-- Scroll Frame
local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Scroll"
scroll.Size = UDim2.new(0.9, 0, 0.65, 0)
scroll.Position = UDim2.new(0.05, 0, 0.22, 0)
scroll.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 8
scroll.Parent = container
Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 12)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = scroll

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0.4, 0, 0, 50)
closeBtn.Position = UDim2.new(0.5, 0, 0.92, 0)
closeBtn.AnchorPoint = Vector2.new(0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Text = "❌ CLOSE"
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = container
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

-- Function: Create Pokemon Slot
local function createPokemonSlot(pokeData)
	local slot = Instance.new("Frame")
	slot.Name = pokeData.Name
	slot.Size = UDim2.new(0.95, 0, 0, 90)
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	slot.BorderSizePixel = 0
	slot.Parent = scroll
	Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 12)
	
	-- Icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.new(0, 70, 0, 70)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	icon.Image = ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = slot
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)
	
	-- Load Icon from DB
	local dbData = PokemonDB.GetPokemon(pokeData.Name)
	if dbData and dbData.Icon then
		icon.Image = dbData.Icon
	end
	
	-- Info Panel
	local infoPanel = Instance.new("Frame")
	infoPanel.Size = UDim2.new(0, 280, 1, 0)
	infoPanel.Position = UDim2.new(0, 90, 0, 0)
	infoPanel.BackgroundTransparency = 1
	infoPanel.Parent = slot
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 0, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = pokeData.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoPanel
	
	-- Rarity Badge
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(0, 80, 0, 20)
	rarityLabel.Position = UDim2.new(0, 0, 0, 38)
	rarityLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	rarityLabel.Text = pokeData.Rarity
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextSize = 12
	rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityLabel.Parent = infoPanel
	Instance.new("UICorner", rarityLabel).CornerRadius = UDim.new(0, 6)
	
	-- Color by rarity
	if pokeData.Rarity == "None" then
		rarityLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	elseif pokeData.Rarity == "Common" then
		rarityLabel.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	elseif pokeData.Rarity == "Uncommon" then
		rarityLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	elseif pokeData.Rarity == "Rare" then
		rarityLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	elseif pokeData.Rarity == "Legend" then
		rarityLabel.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
	end
	
	-- HP Bar
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(1, 0, 0, 18)
	hpLabel.Position = UDim2.new(0, 0, 0, 62)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP: " .. (pokeData.HP or "?") .. "/" .. (pokeData.MaxHP or "?")
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextSize = 12
	hpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	hpLabel.TextXAlignment = Enum.TextXAlignment.Left
	hpLabel.Parent = infoPanel
	
	-- Price Label
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 80, 0, 40)
	priceLabel.Position = UDim2.new(1, -120, 0.5, 0) -- Shifted left
	priceLabel.AnchorPoint = Vector2.new(0, 0.5)
	priceLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	priceLabel.Text = "💰 " .. pokeData.Price
	priceLabel.Font = Enum.Font.FredokaOne
	priceLabel.TextSize = 20
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	priceLabel.Parent = slot
	Instance.new("UICorner", priceLabel).CornerRadius = UDim.new(0, 8)
	
	-- Sell Button
	local sellBtn = Instance.new("TextButton")
	sellBtn.Name = "SellButton"
	sellBtn.Size = UDim2.new(0, 100, 0, 40) -- Made wider
	sellBtn.Position = UDim2.new(1, -10, 0.5, 0)
	sellBtn.AnchorPoint = Vector2.new(1, 0.5)
	sellBtn.Font = Enum.Font.FredokaOne
	sellBtn.TextSize = 16
	sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sellBtn.Parent = slot
	Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 10)
	
	-- FIX: Check if this is the last Pokemon (cannot sell)
	local inventory = player:FindFirstChild("PokemonInventory")
	local totalAlive = 0
	if inventory then
		for _, poke in ipairs(inventory:GetChildren()) do
			if poke:GetAttribute("Status") == "Alive" then
				totalAlive = totalAlive + 1
			end
		end
	end
	
	local isLastPokemon = (totalAlive <= 1)
	
	if isLastPokemon then
		-- Cannot sell last Pokemon - disable button
		sellBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		sellBtn.Text = "🚫 LAST!"
		sellBtn.Active = false
	else
		-- Normal sellable state
		sellBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
		sellBtn.Text = "SELL ($" .. tostring(pokeData.Price) .. ")"
		
		-- Sell Click Handler (only for sellable Pokemon)
		sellBtn.MouseButton1Click:Connect(function()
			-- Animate
			local tween = TweenService:Create(sellBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 70, 0, 35)})
			tween:Play()
			tween.Completed:Wait()
			TweenService:Create(sellBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 80, 0, 40)}):Play()
			
			-- Disable button to prevent double-click
			sellBtn.Active = false
			sellBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			sellBtn.Text = "Selling..."
			
			-- Fire Server (server will send updated list which will refresh UI)
			if sellPokemonEvent then
				SoundManager.Play("Sell") -- 🔊 Sound effect
				sellPokemonEvent:FireServer(pokeData.Name)
			end
			-- Note: Slot removal now handled by server sending updated list via updateUI()
		end)
	end
end

-- Function: Update UI
local function updateUI(pokemonList)
	-- Clear existing
	for _, child in pairs(scroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- If list is nil, it means Close Command
	if pokemonList == nil then
		screenGui.Enabled = false
		return
	end
	
	-- If list is empty, just show empty UI
	screenGui.Enabled = true
	
	-- Create slots
	for _, pokeData in ipairs(pokemonList) do
		createPokemonSlot(pokeData)
	end
	
	-- Update scroll canvas
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end)
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

-- Close Button Handler
closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
	if sellUICloseEvent then
		sellUICloseEvent:FireServer()
	end
end)

-- Event: Server opens/updates UI
if sellUIEvent then
	sellUIEvent.OnClientEvent:Connect(function(pokemonList)
		updateUI(pokemonList)
	end)
end

print("✅ SellUI Client loaded")

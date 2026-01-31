--[[
================================================================================
                      🎨 UI HELPERS - Shared UI Utilities
================================================================================
    📌 Location: ReplicatedStorage/UIHelpers.lua
    📌 Features:
        - Rarity color mapping
        - BillboardGui creation for name labels
        - Player highlight effects
================================================================================
--]]

local UIHelpers = {}

-- Rarity -> Color mapping
UIHelpers.RarityColors = {
	["None"] = Color3.fromRGB(180, 180, 180),      -- Gray
	["Common"] = Color3.fromRGB(100, 255, 100),    -- Green
	["Uncommon"] = Color3.fromRGB(100, 200, 255),  -- Blue
	["Rare"] = Color3.fromRGB(255, 200, 50),       -- Gold/Orange
	["Legend"] = Color3.fromRGB(255, 100, 255),    -- Purple/Magenta
}

-- Create a BillboardGui label above a model
function UIHelpers.CreateNameLabel(parent, name, rarity)
	-- Remove existing label if any
	local existing = parent:FindFirstChild("NameLabel")
	if existing then existing:Destroy() end

	local color = UIHelpers.RarityColors[rarity] or UIHelpers.RarityColors["None"]

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameLabel"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0) -- Above model
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = parent

	-- Adornee is the parent (model's primary part or first BasePart)
	if parent:IsA("Model") then
		billboard.Adornee = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)
	elseif parent:IsA("BasePart") then
		billboard.Adornee = parent
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = name
	textLabel.TextColor3 = color
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	return billboard
end

-- Create a highlight effect on a player's character
function UIHelpers.CreatePlayerHighlight(character, isActive)
	-- Remove existing highlight
	local existing = character:FindFirstChild("TurnHighlight")
	if existing then existing:Destroy() end

	if not isActive then return nil end

	local highlight = Instance.new("Highlight")
	highlight.Name = "TurnHighlight"
	highlight.FillColor = Color3.fromRGB(255, 255, 100) -- Yellow glow
	highlight.FillTransparency = 0.7
	highlight.OutlineColor = Color3.fromRGB(255, 200, 50)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = character

	return highlight
end

-- Create a name label above player's head
function UIHelpers.CreatePlayerNameLabel(character, playerName, isCurrentTurn)
	local head = character:FindFirstChild("Head")
	if not head then return nil end

	-- Remove existing
	local existing = head:FindFirstChild("TurnNameLabel")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TurnNameLabel"
	billboard.Size = UDim2.new(0, 150, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0) -- Above head
	billboard.AlwaysOnTop = false
	billboard.LightInfluence = 0
	billboard.Parent = head
	billboard.Adornee = head

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = isCurrentTurn and ("🎲 " .. playerName) or playerName
	textLabel.TextColor3 = isCurrentTurn and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	return billboard
end

return UIHelpers

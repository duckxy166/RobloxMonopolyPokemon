local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local itemsFolder = player:WaitForChild("Items")
local useItemEvent = ReplicatedStorage:WaitForChild("UseItemEvent")

local ui = script.Parent
local mainFrame = ui:WaitForChild("MainFrame")
local bagButton = ui:WaitForChild("BagButton")

-- Refresh UI content
local function refreshUI()
	-- Clear previous items
	for _, child in pairs(mainFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Create buttons for each item in inventory
	for _, item in pairs(itemsFolder:GetChildren()) do
		local btn = Instance.new("TextButton")
		btn.Name = item.Name
		btn.Text = "📦 " .. item.Name
		btn.Size = UDim2.new(1, 0, 0, 40) -- Full width, 40 height
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.FredokaOne
		btn.Parent = mainFrame

		btn.MouseButton1Click:Connect(function()
			useItemEvent:FireServer(item.Name)
			mainFrame.Visible = false -- Hide inventory
		end)
	end
end

bagButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = not mainFrame.Visible
	if mainFrame.Visible then refreshUI() end
end)

-- Listen for item changes
itemsFolder.ChildAdded:Connect(refreshUI)
itemsFolder.ChildRemoved:Connect(refreshUI)
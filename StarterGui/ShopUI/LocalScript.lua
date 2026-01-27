local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shopEvent = ReplicatedStorage:WaitForChild("ShopEvent")

local shopUI = script.Parent -- ScreenGui
local shopFrame = shopUI:WaitForChild("ShopFrame")
local yesButton = shopFrame:WaitForChild("YesButton")
local noButton = shopFrame:WaitForChild("NoButton")

-- 1. Listen for Shop event from Server
shopEvent.OnClientEvent:Connect(function()
	shopFrame.Visible = true -- Show shop UI
end)

-- 2. Click Yes (Purchase) - can buy multiple times
yesButton.MouseButton1Click:Connect(function()
	-- Don't hide UI - allow multiple purchases
	shopEvent:FireServer("Buy") -- Tell server "Buy"
end)

-- 3. Click No (Cancel)
noButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = false -- Hide UI
	shopEvent:FireServer("Exit") -- Tell server "Cancel"
end)
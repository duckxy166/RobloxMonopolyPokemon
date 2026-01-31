local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shopEvent = ReplicatedStorage:WaitForChild("ShopEvent")

local shopUI = script.Parent -- ScreenGui
local shopFrame = shopUI:WaitForChild("ShopFrame")
local yesButton = shopFrame:WaitForChild("YesButton")
local noButton = shopFrame:WaitForChild("NoButton")

local SoundService = game:GetService("SoundService")

local purchaseSound = Instance.new("Sound")
purchaseSound.Name = "PurchaseSound"
purchaseSound.SoundId = "rbxassetid://1169755927"
purchaseSound.Volume = 0.8
purchaseSound.Parent = SoundService

-- 1. Listen for Shop event from Server
shopEvent.OnClientEvent:Connect(function(msg)
	-- Server might open the shop with no message
	if msg == nil or msg == "Open" then
		shopFrame.Visible = true
		return
	end

	if msg == "Purchased" then
		purchaseSound.TimePosition = 0
		purchaseSound:Play()
		return
	end

	if msg == "Close" then
		shopFrame.Visible = false
		return
	end
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
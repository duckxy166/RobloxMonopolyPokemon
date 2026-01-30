local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopEvent = ReplicatedStorage:WaitForChild("ShopEvent") -- Wait for event (no timeout)

-- Get ShopUI from PlayerGui (originally from StarterGui)
local shopUI = playerGui:WaitForChild("ShopUI") 
local shopFrame = shopUI:WaitForChild("ShopFrame")
local yesBtn = shopFrame:WaitForChild("YesButton") -- Buy button
local noBtn = shopFrame:WaitForChild("NoButton")   -- Exit button

shopEvent.OnClientEvent:Connect(function()
	print("?? Shop opened")
	shopFrame.Visible = true
end)

yesBtn.MouseButton1Click:Connect(function()
	print("? Buy clicked (sending to server)")
	shopEvent:FireServer("Buy") -- Send Buy action
end)

noBtn.MouseButton1Click:Connect(function()
	print("? Exit clicked (closing shop)")
	shopFrame.Visible = false -- Hide UI
	shopEvent:FireServer("Exit") -- Send Exit to Server for NextTurn
end)
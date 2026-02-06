--[[
================================================================================
                      🔊 SOUND MANAGER - Centralized Sound Effects
================================================================================
    📌 Location: ReplicatedStorage/SoundManager.lua
    📌 Responsibilities:
        - Play sounds by name
        - Centralized sound ID management
    
    📌 USAGE:
        local SoundManager = require(ReplicatedStorage.SoundManager)
        SoundManager.Play("DrawCard")
================================================================================
--]]

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- ============================================================================
-- 🔊 SOUND IDS - Replace "rbxassetid://0" with actual Sound IDs
-- ============================================================================
SoundManager.Sounds = {
	-- Card Actions
	DrawCard = "rbxassetid://128744772490411",         -- 🃏 จั่วการ์ด
	PlayCard = "rbxassetid://100682689874058",         -- 🃏 ใช้การ์ด

	-- Pokemon Actions
	Sell = "rbxassetid://1169755927",             -- 💰 ขาย Pokemon
	Catch = "rbxassetid://99790583010152",            -- 🎯 จับ Pokemon
	Revive = "rbxassetid://138123827",           -- 💖 ฟื้น Pokemon

	-- Skill/Ability
	Skill = "rbxassetid://99790583010152",            -- ⚡ ใช้สกิลตัวละคร

	-- UI Buttons
	PhaseClick = "rbxassetid://99790583010152",       -- 📍 กดปุ่ม Phase
	ResetClick = "rbxassetid://91583901492128",       -- 🔄 กดปุ่ม Reset
	ButtonClick = "rbxassetid://99790583010152",      -- 🔘 กดปุ่มทั่วไป

	-- Game Events
	DiceRoll = "rbxassetid://0",         -- 🎲 ทอยเต๋า
	DiceLand = "rbxassetid://90144356226455", -- 🎲 เต๋าตก (มีอยู่แล้ว)
	BattleStart = "rbxassetid://130746840262263",      -- ⚔️ เริ่มต่อสู้
	TurnStart = "rbxassetid://99790583010152",        -- 🔄 เริ่มเทิร์น
}

-- ============================================================================
-- 🔊 PLAY FUNCTION
-- ============================================================================
function SoundManager.Play(soundName, volume)
	local soundId = SoundManager.Sounds[soundName]
	if not soundId or soundId == "rbxassetid://0" then
		-- Skip if no valid sound ID configured
		print("🔇 [SoundManager] No sound for: " .. tostring(soundName))
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlayOnRemove = true
	sound.Parent = SoundService
	sound:Destroy() -- Triggers PlayOnRemove

	print("🔊 [SoundManager] Playing: " .. soundName)
end

-- Play sound at a specific position (3D sound)
function SoundManager.PlayAt(soundName, position, volume)
	local soundId = SoundManager.Sounds[soundName]
	if not soundId or soundId == "rbxassetid://0" then
		return
	end

	-- Create temporary part for 3D sound
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.RollOffMaxDistance = 100
	sound.Parent = part
	sound:Play()

	-- Cleanup after sound finishes
	sound.Ended:Connect(function()
		part:Destroy()
	end)

	-- Fallback cleanup
	game:GetService("Debris"):AddItem(part, 10)
end

return SoundManager

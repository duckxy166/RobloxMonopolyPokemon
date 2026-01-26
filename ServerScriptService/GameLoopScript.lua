--[[
================================================================================
                      🎮 GAME LOOP SCRIPT - เกมกระดาน Pokemon 🎮
================================================================================
    📌 SCRIPT นี้เป็น ServerScript หลัก ควบคุม:
        - ระบบเทิร์นของผู้เล่น (Turn-based)
        - การเดินบนช่องกระดาน (Tiles)
        - การต่อสู้/จับ Pokemon
        - ระบบการ์ด (Card System) - จั่ว/ใช้/ทิ้ง
        - ระบบร้านค้า (Shop)
        - การแจ้งเตือน (Notify UI)
    
    📁 ไฟล์ที่เกี่ยวข้อง:
        - CardDB (ModuleScript ใน ServerStorage) = ข้อมูลการ์ดทั้งหมด
        - PokemonModels (Folder ใน ServerStorage) = โมเดล Pokemon
        - Tiles (Folder ใน Workspace) = ช่องกระดาน
        
    🎯 VERSION: 1.0
    📅 LAST UPDATE: 2026-01-26
================================================================================
--]]
-- ============================================
-- 📦 SERVICES - ดึง Roblox Services ที่ใช้งาน
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")   -- เก็บ RemoteEvents สำหรับ Client-Server
local ServerStorage = game:GetService("ServerStorage")         -- เก็บ Module/Models (ฝั่ง Server เท่านั้น)
local Workspace = game:GetService("Workspace")                 -- World: เก็บ Tiles, CenterStage
local Players = game:GetService("Players")                     -- จัดการผู้เล่นทั้งหมด


-- ============================================
-- 🃏 CARD REMOTE EVENTS - สื่อสารระหว่าง Client/Server
-- ============================================
local drawCardEvent = ReplicatedStorage:FindFirstChild("DrawCardEvent")   -- Event จั่วการ์ด (ยังไม่ใช้)
local playCardEvent = ReplicatedStorage:FindFirstChild("PlayCardEvent")  -- Event ใช้การ์ด

-- 🔧 สร้าง Event ถ้ายังไม่มี
if not drawCardEvent then drawCardEvent = Instance.new("RemoteEvent", ReplicatedStorage); drawCardEvent.Name="DrawCardEvent" end
if not playCardEvent then playCardEvent = Instance.new("RemoteEvent", ReplicatedStorage); playCardEvent.Name="PlayCardEvent" end



-- ============================================
-- 📚 CARD DATABASE MODULE - ข้อมูลการ์ดทั้งหมด
-- ============================================
local CardDB = require(ServerStorage:WaitForChild("CardDB"))  -- โหลดข้อมูลการ์ดจาก ModuleScript


-- 🎴 ตัวแปรระบบการ์ด
local deck = {}         -- กองจั่ว (draw pile)
local discardPile = {}  -- กองทิ้ง (discard pile)

-- 🔀 สับการ์ด (Fisher-Yates Algorithm)
-- @param t : table ที่ต้องการสับ
local function shuffle(t)
	for i = #t, 2, -1 do
		local j = math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
end

-- 🔄 เติมกองจั่วถ้าหมด (ใช้กองทิ้ง หรือสร้างใหม่)
local function refillDeckIfEmpty()
	if #deck > 0 then return end
	if #discardPile == 0 then
		-- Build new deck if both piles are empty
		deck = CardDB:BuildDeck()
		shuffle(deck)
		return
	end
	deck = discardPile
	discardPile = {}
	shuffle(deck)
end

-- 💰 ดึง leaderstats (Money, Pokeballs) ของผู้เล่น
-- @return money, balls หรือ nil ถ้าไม่มี
local function getLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild("Money"), ls and ls:FindFirstChild("Pokeballs")
end

-- ==========================================
-- ?? 1. Events Setup
-- ==========================================
local rollEvent = ReplicatedStorage:FindFirstChild("RollDiceEvent") 
local encounterEvent = ReplicatedStorage:FindFirstChild("EncounterEvent")
local catchEvent = ReplicatedStorage:FindFirstChild("CatchPokemonEvent")
local runEvent = ReplicatedStorage:FindFirstChild("RunEvent")
local updateTurnEvent = ReplicatedStorage:FindFirstChild("UpdateTurnEvent")
local notifyEvent = ReplicatedStorage:FindFirstChild("NotifyEvent")
local shopEvent = ReplicatedStorage:FindFirstChild("ShopEvent")
local useItemEvent = ReplicatedStorage:FindFirstChild("UseItemEvent")
local playerInShop = {} -- [userId] = true/false (กำลังอยู่ในร้านค้าหรือไม่)

-- สร้าง Event ถ้ายังไม่มี (ต้องอยู่ก่อน HAND SYSTEM)
if not rollEvent then rollEvent = Instance.new("RemoteEvent", ReplicatedStorage); rollEvent.Name = "RollDiceEvent" end
if not encounterEvent then encounterEvent = Instance.new("RemoteEvent", ReplicatedStorage); encounterEvent.Name = "EncounterEvent" end
if not catchEvent then catchEvent = Instance.new("RemoteEvent", ReplicatedStorage); catchEvent.Name = "CatchPokemonEvent" end
if not runEvent then runEvent = Instance.new("RemoteEvent", ReplicatedStorage); runEvent.Name = "RunEvent" end
if not updateTurnEvent then updateTurnEvent = Instance.new("RemoteEvent", ReplicatedStorage); updateTurnEvent.Name = "UpdateTurnEvent" end
if not notifyEvent then notifyEvent = Instance.new("RemoteEvent", ReplicatedStorage); notifyEvent.Name = "NotifyEvent" end
if not shopEvent then shopEvent = Instance.new("RemoteEvent", ReplicatedStorage); shopEvent.Name = "ShopEvent" end
if not useItemEvent then useItemEvent = Instance.new("RemoteEvent", ReplicatedStorage); useItemEvent.Name = "UseItemEvent" end

-- ============================================
-- 🃏 2. CARD/HAND SYSTEM - ระบบมือการ์ด
-- ============================================
-- ผู้เล่นถือการ์ดได้สูงสุด 5 ใบ (HAND_LIMIT)
local HAND_LIMIT = 5

-- 📂 ดึง Folder 'Hand' ของผู้เล่น
local function getHandFolder(player)
	return player:FindFirstChild("Hand")
end

-- 🔢 นับจำนวนการ์ดในมือ (รวม quantity ของแต่ละ slot)
local function countHand(player)
	local hand = getHandFolder(player)
	if not hand then return 0 end
	local total = 0
	for _, v in ipairs(hand:GetChildren()) do
		if v:IsA("IntValue") then
			total += v.Value
		end
	end
	return total
end

-- ➕ เพิ่มการ์ด 1 ใบเข้ามือ
-- @param cardId : ชื่อการ์ด (string)
-- @return true ถ้าสำเร็จ, false + reason ถ้าไม่สำเร็จ
local function addCardToHand(player, cardId)
	local hand = getHandFolder(player)
	if not hand then return false, "no_hand" end
	if countHand(player) >= HAND_LIMIT then
		return false, "hand_full"
	end

	local slot = hand:FindFirstChild(cardId)
	if not slot then
		slot = Instance.new("IntValue")
		slot.Name = cardId
		slot.Value = 0
		slot.Parent = hand
	end

	slot.Value += 1
	return true
end

-- ➖ ลบการ์ดออกจากมือ
-- @param cardId : ชื่อการ์ด
-- @param amount : จำนวน (default = 1)
-- @return true ถ้าสำเร็จ
local function removeCardFromHand(player, cardId, amount)
	amount = amount or 1
	local hand = getHandFolder(player)
	if not hand then return false end

	local slot = hand:FindFirstChild(cardId)
	if not slot or not slot:IsA("IntValue") then return false end
	if slot.Value < amount then return false end

	slot.Value -= amount
	if slot.Value <= 0 then slot:Destroy() end
	return true
end

-- 🎴 จั่วการ์ด 1 ใบจากกอง
-- @return cardId ถ้าสำเร็จ, nil ถ้ามือเต็มหรือกองหมด
local function drawOneCard(player)
	refillDeckIfEmpty()

	if countHand(player) >= HAND_LIMIT then
		if notifyEvent then notifyEvent:FireClient(player, "Hand is full (5 cards)! Discard or use cards first!") end
		return nil
	end

	local cardId = table.remove(deck, 1)
	if not cardId then return nil end

	local ok = addCardToHand(player, cardId)
	if ok then
		if notifyEvent then
			local def = CardDB.Cards[cardId]
			notifyEvent:FireClient(player, ("Card drawn: %s"):format(def and def.Name or cardId))
		end
		return cardId
	end

	table.insert(deck, 1, cardId)
	return nil
end



-- Create PlayCardEvent if not exists
if not shopEvent then shopEvent = Instance.new("RemoteEvent", ReplicatedStorage); shopEvent.Name = "ShopEvent" end
if not useItemEvent then useItemEvent = Instance.new("RemoteEvent", ReplicatedStorage); useItemEvent.Name = "UseItemEvent" end
if not notifyEvent then notifyEvent = Instance.new("RemoteEvent", ReplicatedStorage); notifyEvent.Name = "NotifyEvent" end
if not rollEvent then rollEvent = Instance.new("RemoteEvent", ReplicatedStorage); rollEvent.Name = "RollDiceEvent" end
if not encounterEvent then encounterEvent = Instance.new("RemoteEvent", ReplicatedStorage); encounterEvent.Name = "EncounterEvent" end
if not catchEvent then catchEvent = Instance.new("RemoteEvent", ReplicatedStorage); catchEvent.Name = "CatchPokemonEvent" end
if not runEvent then runEvent = Instance.new("RemoteEvent", ReplicatedStorage); runEvent.Name = "RunEvent" end
if not updateTurnEvent then updateTurnEvent = Instance.new("RemoteEvent", ReplicatedStorage); updateTurnEvent.Name = "UpdateTurnEvent" end

-- ==========================================
-- ?? Variables & Config
-- ==========================================
local tilesFolder = Workspace:WaitForChild("Tiles")
local centerStage = Workspace:WaitForChild("CenterStage")
local pokemonModels = ServerStorage:WaitForChild("PokemonModels")

local playerPositions = {}
local playerRepelSteps = {} 
local currentSpawnedPokemon = nil 
local playersInGame = {} 
local currentTurnIndex = 1 
local isTurnActive = false 

local POKEMON_DB = {
	{ Name = "Bulbasaur", Rarity = "Common", ModelName = "Bulbasaur" }, 
	{ Name = "Charmander", Rarity = "Common", ModelName = "Charmander" },
	{ Name = "Squirtle", Rarity = "Common", ModelName = "Squirtle" },
	{ Name = "Pikachu", Rarity = "Rare", ModelName = "Pikachu" },
	{ Name = "Mewtwo", Rarity = "Legendary", ModelName = "Mewtwo" }
}
local DIFFICULTY = { ["Common"] = 2, ["Rare"] = 4, ["Legendary"] = 6 }

-- 🧹 ลบ Pokemon ที่ spawn อยู่บนเวที
local function clearCenterStage()
	if currentSpawnedPokemon then currentSpawnedPokemon:Destroy(); currentSpawnedPokemon = nil end
end

-- ==========================================
-- Walking Logic
-- ==========================================
-- 🎲 ประมวลผลการทอยลูกเต๋าของผู้เล่น
-- - เดินตามจำนวนที่ทอยได้
-- - เช็คสี Tile ที่หยุด: White=ร้านค้า, Green=พบ Pokemon, อื่นๆ=จั่วการ์ด
local function processPlayerRoll(player)
	print("🎲 [Server] processPlayerRoll called by:", player.Name)
	print("🎲 [Server] isTurnActive:", isTurnActive)
	print("🎲 [Server] currentTurnIndex:", currentTurnIndex)
	print("🎲 [Server] playersInGame count:", #playersInGame)
	
	if #playersInGame > 0 then
		local currentPlayer = playersInGame[currentTurnIndex]
		print("🎲 [Server] Current turn player:", currentPlayer and currentPlayer.Name or "nil")
	end
	
	if not isTurnActive then 
		print("❌ [Server] isTurnActive is false! Returning...")
		return 
	end
	if player ~= playersInGame[currentTurnIndex] then 
		print("❌ [Server] Not this player's turn! Returning...")
		return 
	end

	print("✅ [Server] Processing roll for:", player.Name)
	isTurnActive = false 
	clearCenterStage()

	-- local roll = math.random(1, 6)
	local roll = 5 -- เดิน

	print("🎲 [Server] Roll result:", roll, "- Firing to client")
	rollEvent:FireClient(player, roll) 
	task.wait(2.5) 

	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	local currentPos = playerPositions[player.UserId] or 0
	local repelLeft = playerRepelSteps[player.UserId] or 0

	for i = 1, roll do
		currentPos = currentPos + 1
		local nextTile = tilesFolder:FindFirstChild(tostring(currentPos))

		if nextTile and humanoid then
			humanoid:MoveTo(nextTile.Position)
			humanoid.MoveToFinished:Wait()

			if repelLeft > 0 then repelLeft = repelLeft - 1; playerRepelSteps[player.UserId] = repelLeft end

			if i == roll then
				local tileColor = string.lower(nextTile.BrickColor.Name)

				if string.find(tileColor, "white") then
					-- [[ SHOP TILE ]] --
					print("Landed on Shop! Opening shop...")

					-- Save position before 
					playerPositions[player.UserId] = currentPos

					-- ? Manages all players???
					playerInShop[player.UserId] = true

					shopEvent:FireClient(player)
					return


				elseif string.find(tileColor, "green") then
					-- [[ ?? ??? ]] --
					if repelLeft > 0 then nextTurn() else spawnPokemonEncounter(player) end
				else
					drawOneCard(player)
					nextTurn()
				end
			end
		else
			currentPos = 0
			if humanoid then 
				local startTile = tilesFolder:FindFirstChild("0")
				if startTile then character:SetPrimaryPartCFrame(startTile.CFrame + Vector3.new(0,5,0)) end
			end
			nextTurn()
			break
		end
	end
	playerPositions[player.UserId] = currentPos
end


-- ============================================
-- 🃏 5. CARD EVENT HANDLER - จัดการการใช้การ์ด
-- ============================================
-- 🛡️ เช็คว่าผู้เล่นมี Shield กันการโจมตีหรือไม่
-- @return true ถ้า block สำเร็จ (Shield จะหายไป)
local function tryBlockNegative(targetPlayer)
	local status = targetPlayer:FindFirstChild("Status")
	if not status then return false end

	local shield = status:FindFirstChild("Shield")
	if shield and shield.Value == true then
		shield.Value = false -- Shield used once
		return true
	end
	return false
end

-- 🔙 ย้ายผู้เล่นถอยหลัง X ช่อง
local function moveBackSteps(targetPlayer, steps)
	local uid = targetPlayer.UserId
	local currentPos = playerPositions[uid] or 0
	local newPos = math.max(0, currentPos - steps)
	playerPositions[uid] = newPos

	local char = targetPlayer.Character
	local startTile = tilesFolder:FindFirstChild(tostring(newPos))
	if char and startTile and char.PrimaryPart then
		char:SetPrimaryPartCFrame(startTile.CFrame + Vector3.new(0,5,0))
	end
end

playCardEvent.OnServerEvent:Connect(function(player, cardId, targetUserId)
	-- Check if player turn
	if player ~= playersInGame[currentTurnIndex] then return end

	local def = CardDB.Cards[cardId]
	if not def then return end

	-- Remove card from hand
	if not removeCardFromHand(player, cardId, 1) then
		if notifyEvent then notifyEvent:FireClient(player, "Card not in hand!") end
		return
	end

	-- Remove card from hand??
	local targetPlayer = nil
	if def.NeedsTarget then
		for _, p in ipairs(playersInGame) do
			if p.UserId == targetUserId then
				targetPlayer = p
				break
			end
		end
		if not targetPlayer then
			-- Return card if invalid target
			addCardToHand(player, cardId)
			if notifyEvent then notifyEvent:FireClient(player, "?? Manages all players") end
			return
		end
	end

	-- If negative card, check if target has Shield
	if targetPlayer and def.Negative then
		if tryBlockNegative(targetPlayer) then
			table.insert(discardPile, cardId)
			if notifyEvent then
				notifyEvent:FireClient(player, "Target blocked with Safety Shield!")
				notifyEvent:FireClient(targetPlayer, "Your Safety Shield blocked an attack!")
			end
			return
		end
	end

	-- Apply card effects
	local money, balls = getLeaderstats(player)

	if def.MoneyGain and money then
		money.Value += def.MoneyGain
	end

	if def.Steal and targetPlayer then
		local tMoney = getLeaderstats(targetPlayer)
		local stealAmt = def.Steal
		if tMoney then
			local stolen = math.min(stealAmt, tMoney.Value)
			tMoney.Value -= stolen
			if money then money.Value += stolen end
		end
	end

	if def.Discard and def.MoneyGain and money then
		-- 💰 Discard-to-Money: ทิ้งการ์ดแลกเงิน
		local need = def.Discard

		-- ✅ เช็คก่อนว่ามีการ์ดพอทิ้งไหม (หลังจากใช้ใบนี้ไปแล้ว)
		if countHand(player) < need then
			addCardToHand(player, cardId) -- คืนใบที่ใช้
			if notifyEvent then notifyEvent:FireClient(player, "⛔ การ์ดในมือไม่พอให้ทิ้ง "..need.." ใบ") end
			return
		end

		local hand = getHandFolder(player)
		local discarded = 0
		for _, slot in ipairs(hand:GetChildren()) do
			if discarded >= need then break end
			if slot:IsA("IntValue") and slot.Value > 0 then
				slot.Value -= 1
				if slot.Value <= 0 then slot:Destroy() end
				discarded += 1
			end
		end

		money.Value += def.MoneyGain
	end

	if def.BackSteps and targetPlayer then
		moveBackSteps(targetPlayer, def.BackSteps)
	end

	if def.Draw then
		for i = 1, def.Draw do
			drawOneCard(player)
		end
	end

	if def.Cleanse then
		local status = player:FindFirstChild("Status")
		if status then
			local sleep = status:FindFirstChild("SleepTurns")
			if sleep then sleep.Value = 0 end
		end
	end

	if def.Shield then
		local status = player:FindFirstChild("Status")
		if status then
			local shield = status:FindFirstChild("Shield")
			if shield then shield.Value = true end
		end
	end

	if def.SleepTurns and targetPlayer then
		local status = targetPlayer:FindFirstChild("Status")
		if status then
			local sleep = status:FindFirstChild("SleepTurns")
			if sleep then sleep.Value += def.SleepTurns end
		end
	end

	if def.AddBalls and balls then
		balls.Value += def.AddBalls
	end

	-- TODO: RareCandy / TradeTicket (needs extra logic) - add later

	-- Finally: add to discard pile
	table.insert(discardPile, cardId)

	if notifyEvent then notifyEvent:FireClient(player, "Card used successfully!") end
end)

-- ⏭️ เปลี่ยนเทิร์นไปผู้เล่นถัดไป
-- - ข้ามผู้เล่นที่ถูก Sleep
-- - ประกาศผู้เล่นปัจจุบันให้ทุกคน
function nextTurn()
	print("⏭️ [Server] nextTurn() called")
	task.wait(1)
	if #playersInGame == 0 then 
		print("⏭️ [Server] No players in game!")
		return 
	end

	for _ = 1, #playersInGame do
		currentTurnIndex += 1
		if currentTurnIndex > #playersInGame then currentTurnIndex = 1 end

		local p = playersInGame[currentTurnIndex]
		local status = p:FindFirstChild("Status")
		local sleep = status and status:FindFirstChild("SleepTurns")

		if sleep and sleep.Value > 0 then
			sleep.Value -= 1
			if notifyEvent then notifyEvent:FireClient(p, "You are asleep! Turn skipped!") end
		else
			isTurnActive = true
			playerInShop[p.UserId] = false
			print("✅ [Server] Turn started for:", p.Name, "| isTurnActive:", isTurnActive)
			updateTurnEvent:FireAllClients(p.Name)
			return
		end
	end
end


-- ===========================
-- Shop System (separate from main loop)
-- ===========================
local shopDebounce = {} -- [userId] = timestamp

shopEvent.OnServerEvent:Connect(function(player, action)
	-- Apply card effects
	if player ~= playersInGame[currentTurnIndex] then return end

	-- Check if player is in shop (prevent invalid events)
	if not playerInShop[player.UserId] then
		warn("? Player not in shop but tried:", player.Name, action)
		return
	end

	-- Debounce to prevent multiple clicks
	local now = os.clock()
	if shopDebounce[player.UserId] and (now - shopDebounce[player.UserId]) < 0.12 then
		return
	end
	shopDebounce[player.UserId] = now

	print("Shop Server: Action = " .. tostring(action))

	if action == "Buy" then
		local leaderstats = player:FindFirstChild("leaderstats")
		local money = leaderstats and leaderstats:FindFirstChild("Money")
		local balls = leaderstats and leaderstats:FindFirstChild("Pokeballs")

		if not (money and balls) then return end

		local price = 2
		if money.Value >= price then
			money.Value -= price
			balls.Value += 1

			-- Notify client of purchase result
			if notifyEvent then
				notifyEvent:FireClient(player, ("Bought Pokeball +1 (Money left: %d)"):format(money.Value))
			end
		else
			if notifyEvent then
				notifyEvent:FireClient(player, "Not enough money!")
			end
		end

		-- Dont call nextTurn here, only on Exit

	elseif action == "Exit" then
		print("Player exited shop -> next turn")

		-- Clear shop flag
		playerInShop[player.UserId] = false

		task.wait(0.2)
		nextTurn()
	end
end)
-- ==========================================
-- Pokemon Spawning (Physics)
-- ==========================================
-- 🎯 สุ่ม Pokemon และ spawn ลงบนเวทีกลาง
-- - ใช้ Physics (ตกลงมา + BodyGyro รักษาสมดุล)
function spawnPokemonEncounter(player)
	local randomPoke = POKEMON_DB[math.random(1, #POKEMON_DB)]
	local modelTemplate = pokemonModels:FindFirstChild(randomPoke.ModelName)

	if modelTemplate then
		local clonedModel = modelTemplate:Clone()

		-- 1. Position above center stage
		clonedModel:PivotTo(centerStage.CFrame + Vector3.new(0, 20, 0)) 
		clonedModel.Parent = Workspace
		currentSpawnedPokemon = clonedModel

		-- 2. Find MainPart
		local mainPart = clonedModel.PrimaryPart or clonedModel:FindFirstChild("HumanoidRootPart") or clonedModel:FindFirstChildWhichIsA("BasePart", true)
		local pokeHumanoid = clonedModel:FindFirstChild("Humanoid")

		if mainPart then
			-- 3. Weld all parts together
			for _, part in pairs(clonedModel:GetDescendants()) do
				if part:IsA("BasePart") and part ~= mainPart then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = mainPart
					weld.Part1 = part
					weld.Parent = mainPart

					part.Anchored = false
					part.CanCollide = false
					part.Massless = true
				end
			end

			-- 4. Set main part physics
			mainPart.Anchored = false 
			mainPart.CanCollide = true 
			mainPart.Massless = false

			-- 5. Add stabilizer (BodyGyro)
			local gyro = Instance.new("BodyGyro")
			gyro.Name = "Stabilizer"
			gyro.MaxTorque = Vector3.new(math.huge, 0, math.huge) 
			gyro.P = 5000 
			gyro.CFrame = CFrame.new() 
			gyro.Parent = mainPart

			-- 6. Humanoid settings
			if pokeHumanoid then
				pokeHumanoid.AutomaticScalingEnabled = false
				pokeHumanoid.HipHeight = 0 
			end
		end
	else
		warn("? ??Related files: " .. randomPoke.ModelName)
	end

	encounterEvent:FireClient(player, randomPoke)
end

-- ==========================================
-- Lucky Cards & Items
-- ==========================================
-- 🍀 สุ่มให้การ์ด Lucky แก่ผู้เล่น
function giveLuckyCard(player)
	local cards = {"Rare Candy", "Repel", "Revive"}
	local pickedCard = cards[math.random(1, #cards)]
	local itemsFolder = player:FindFirstChild("Items")

	if itemsFolder then
		local newCard = Instance.new("StringValue")
		newCard.Name = pickedCard
		newCard.Parent = itemsFolder
		print("Lucky card given: " .. pickedCard)
	end
end


-- ==========================================
-- ?? Player Setup
-- ==========================================
-- 🆕 เมื่อผู้เล่นเข้าเกม สร้างข้อมูลเริ่มต้น:
--    - leaderstats (Money=20, Pokeballs=5)
--    - Hand folder (เก็บการ์ดในมือ)
--    - Status folder (Shield, SleepTurns)
--    - เริ่มเกมถ้าเป็นผู้เล่นคนแรก
local function onPlayerAdded(player)
	print("👤 [Server] onPlayerAdded:", player.Name)
	for _, p in ipairs(playersInGame) do if p == player then return end end
	table.insert(playersInGame, player)
	print("👤 [Server] Player added to game! Total players:", #playersInGame)
	playerPositions[player.UserId] = 0 
	playerRepelSteps[player.UserId] = 0 

	local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player
	local money = Instance.new("IntValue"); money.Name = "Money"; money.Value = 20; money.Parent = leaderstats
	local balls = Instance.new("IntValue"); balls.Name = "Pokeballs"; balls.Value = 5; balls.Parent = leaderstats
	local inventory = Instance.new("Folder"); inventory.Name = "PokemonInventory" ;inventory.Parent = player
	-- Hand folder: max 5 cards
	local hand = Instance.new("Folder"); hand.Name = "Hand"; hand.Parent = player

	-- Status: shield / sleep
	local status = Instance.new("Folder"); status.Name = "Status"; status.Parent = player
	local shield = Instance.new("BoolValue"); shield.Name = "Shield"; shield.Value = false; shield.Parent = status
	local sleep = Instance.new("IntValue"); sleep.Name = "SleepTurns"; sleep.Value = 0; sleep.Parent = status


	if #playersInGame == 1 then 
		print("👤 [Server] First player! Starting game in 3 seconds...")
		task.wait(3)
		currentTurnIndex = 0
		nextTurn() 
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
print("🎮 [Server] GameLoopScript loaded! Checking for existing players...")
for _, player in ipairs(Players:GetPlayers()) do 
	print("🎮 [Server] Found existing player:", player.Name)
	onPlayerAdded(player) 
end

Players.PlayerRemoving:Connect(function(player)
	for i, p in ipairs(playersInGame) do
		if p == player then
			table.remove(playersInGame, i)
			if i == currentTurnIndex then currentTurnIndex = currentTurnIndex - 1; nextTurn()
			elseif i < currentTurnIndex then currentTurnIndex = currentTurnIndex - 1 end
			break
		end
	end
end)



rollEvent.OnServerEvent:Connect(function(player) processPlayerRoll(player) end)
runEvent.OnServerEvent:Connect(function(player) clearCenterStage(); nextTurn() end)
catchEvent.OnServerEvent:Connect(function(player, pokeData)
	local balls = player.leaderstats.Pokeballs
	balls.Value = balls.Value - 1

	-- Roll for catch
	local target = DIFFICULTY[pokeData.Rarity] or 2
	local success = math.random(1, 6) >= target

	if success then
		local newPoke = Instance.new("StringValue"); newPoke.Name = pokeData.Name; newPoke.Value = pokeData.Rarity; newPoke.Parent = player.PokemonInventory
		player.leaderstats.Money.Value = player.leaderstats.Money.Value + 5 -- Bonus money
		clearCenterStage()
	end

	local isFinished = success or (balls.Value <= 0)
	catchEvent:FireClient(player, success, 0, target, isFinished)

	if isFinished then 
		task.wait(2)
		clearCenterStage()
		nextTurn() 
	end
end)

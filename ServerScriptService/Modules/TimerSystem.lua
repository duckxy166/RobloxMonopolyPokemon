--[[
================================================================================
                      ⏱️ TIMER SYSTEM - Phase Timers & Countdown
================================================================================
    📌 Location: ServerScriptService/Modules
    📌 Responsibilities:
        - Phase timer management
        - Client countdown broadcasting
        - Auto-timeout callbacks
================================================================================
--]]

local TimerSystem = {}

-- Constants
TimerSystem.DRAW_TIMEOUT = 10
TimerSystem.ROLL_TIMEOUT = 30
TimerSystem.SHOP_TIMEOUT = 20
TimerSystem.ENCOUNTER_TIMEOUT = 10

-- State
local turnTimerTask = nil
local timerUpdateEvent = nil

-- Initialize with events
function TimerSystem.init(events)
	timerUpdateEvent = events.TimerUpdate
	print("✅ TimerSystem initialized")
end

-- Cancel any active timer
function TimerSystem.cancelTimer()
	if turnTimerTask then 
		pcall(function() task.cancel(turnTimerTask) end)
		turnTimerTask = nil 
	end
	if timerUpdateEvent then
		timerUpdateEvent:FireAllClients(0, "") -- Clear timer on clients
	end
end

-- Start a phase timer with countdown broadcast to clients
-- @param seconds: time in seconds
-- @param phaseName: name of phase for display ("Roll", "Shop", etc.)
-- @param timeoutCallback: function to call when timer expires
function TimerSystem.startPhaseTimer(seconds, phaseName, timeoutCallback)
	TimerSystem.cancelTimer()
	if timerUpdateEvent then
		timerUpdateEvent:FireAllClients(seconds, phaseName) -- Tell clients to start countdown
	end
	turnTimerTask = task.delay(seconds, function()
		if timerUpdateEvent then
			timerUpdateEvent:FireAllClients(0, "") -- Timer ended
		end
		if timeoutCallback then timeoutCallback() end
	end)
end

return TimerSystem

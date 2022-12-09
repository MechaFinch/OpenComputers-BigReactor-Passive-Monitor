
--
-- Reactor Control
--
-- This module handles reactor control via PID loop
--
-- Author: Mechafinch
--

local reactorcontrol = {}

local computer = require("computer")
local comp = require("component")
local reactor = comp.br_reactor

-- PID parameters
local target = 0
local overshootFactor = 1
local kp = 0
local ki = 0
local kd = 0

-- previous iteration info
local lastLoopTime = 0
local err1 = 0 -- error(t - 1)
local err2 = 0 -- error(t - 2)
local output = 1

-- reactor info
local numRods = reactor.getNumberOfControlRods()

-- setControlRods(float level)
-- Sets the reactor control rods as close to the given level [0, 1] as possible
local function setControlRods(level)
	local percent = level * 100
	
	local globalLevel = math.floor(percent)
	local partialNum = math.floor(((percent - globalLevel) * numRods) + 0.5)
	
	reactor.setAllControlRodLevels(globalLevel)
	
	for r = 0, partialNum, 1 do
		reactor.setControlRodLevel(r, globalLevel + 1)
	end
end

-- currentTime()
-- Returns the current computer time in ticks
local function currentTime()
	return math.floor(computer.uptime() * 20)
end

-- start()
-- Tells the control system to start
function reactorcontrol.start()
	lastLoopTime = currentTime()
end

-- setParameters(float target, float overshootFactor, float kp, float ki, float kd)
-- Sets the PID loop parameters
-- target is a percentage [0, 1]
-- The error is multiplied by the overshootFactor if buffer > target, so that high targets e.g. 0.9
-- won't overshoot all the way to full so easily
function reactorcontrol.setParameters(ntarget, over, nkp, nki, nkd)
	target = ntarget
	overshootFactor = over
	kp = nkp
	ki = nki
	kd = nkd
end

-- runPIDStep()
-- Runs a step of the PID loop
function reactorcontrol.runPIDStep()
	local t = currentTime()
	local dt = t - lastLoopTime
	lastLoopTime = t
	
	if dt == 0 then
		return nil
	end

	-- wikipedia algorithm
	local a2 = kd / dt;
	local a0 = kp + (ki * dt) + a2
	local a1 = -kp - (2 * a2)
	
	local err = target - (reactor.getEnergyStored() / 10000000)
	
	if err < 0 then
		err = err * overshootFactor
	end
	
	output = output - ((a0 * err) + (a1 * err1) + (a2 * err2))
	output = math.max(0, math.min(1, output))
	setControlRods(output)
	
	err2 = err1
	err1 = err
end

-- getError()
-- Returns the last err term
function reactorcontrol.getError()
	return err1
end

-- getOutput()
-- Returns the output
function reactorcontrol.getOutput()
	return output
end

return reactorcontrol
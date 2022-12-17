
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

local pg = require("pixelgraphics")
local term = require("term")

-- PID parameters
local target = 0
local overshootFactor = 1
local kp = 0
local ki = 0
local kd = 0
local integral = 0
local last_derivative = 0
local err_buffer_size = 0
local err_buffer = {}

-- previous iteration info
local lastLoopTime = 0
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
	
	local r = 0
	while r < partialNum do
		reactor.setControlRodLevel(r, globalLevel + 1)
		r = r + 1
	end
end

-- currentTime()
-- Returns the current computer time in ticks
local function currentTime()
	return math.floor(computer.uptime())
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
function reactorcontrol.setParameters(ntarget, over, isize, dsize, nkp, nki, nkd)
	target = math.min(1, math.max(0, ntarget))
	overshootFactor = over
	integral_size = math.max(1, isize)
	derivative_size = math.max(1, dsize)
	kp = nkp
	ki = nki
	kd = nkd
	
	err_buffer_size = math.max(0, math.max(integral_size, derivative_size))
	err_buffer = {}
	
	for i=0, err_buffer_size - 1, 1 do
		err_buffer[i] = 0
	end
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
	
	-- update
	local err = target - (reactor.getEnergyStored() / 10000000)
	
	if err < 0 then
		err = err * overshootFactor
	end
	
	-- derive
	local derivative = (err - err_buffer[derivative_size - 1]) / dt
	
	-- integrate with bounds
	integral = integral + (err * dt) - (err_buffer[integral_size - 1] * dt)
	
	-- apply pid
	output = output - ((kp * err) + (ki * integral) + (kd * derivative))
	
	output = math.max(0, math.min(1, output))
	setControlRods(output)
	
	-- march error buffer
	i = err_buffer_size - 1
	while i >= 0 do
		err_buffer[i] = err_buffer[i - 1]
		i = i - 1
	end
	
	err_buffer[0] = err
	last_derivative = derivative
end

-- getError()
-- Returns the last err term
function reactorcontrol.getError()
	return err_buffer[0]
end

-- getError()
-- Returns the last err term
function reactorcontrol.getIntegral()
	return integral
end

-- getError()
-- Returns the last err term
function reactorcontrol.getDerivative()
	return last_derivative
end

-- getOutput()
-- Returns the output
function reactorcontrol.getOutput()
	return output
end

return reactorcontrol
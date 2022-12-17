
--
-- Reactor Monitor
--
-- This script controls a BigReactos passive reactor
-- The program keeps the reactor energy buffer at a certain target
-- PID loop go brrrr
--
-- Author: Mechafinch
--

local rc = require("reactorcontrol")
local pg = require("pixelgraphics")
local ro = require("readout")

local event = require("event")
local comp = require("component")
local term = require("term")
local reac = comp.br_reactor
local gpu = comp.gpu


-- reactor status
local rEnergyStored = 0
local rFuelTemp = 0
local rCasingTemp = 0
local rFuelAmount = 0
local rWasteAmount = 0
local rFuelAmountMax = 0
local rControlRodLevel = 0
local rLastTickEnergy = 0
local rActive = 0

local rMaxTickEnergy = 1

-- graphics
local screenWidthPixels, screenHeightPixels = pg.getPixelResolution()
local screenWidthChars, screenHeightChars = pg.getCharResolution()

local barWidthChars = 9
local barWidthPixels = barWidthChars
local barHeightChars = screenHeightChars - 5
local barHeightPixels = barHeightChars * 2

local graphX = ((barWidthPixels + 2) * 5) + 3
local graphWidth = screenWidthPixels - graphX
local graphHeight = screenHeightChars - 2
local powerGraphY = 0
local rodGraphY = powerGraphY + graphHeight + 2

function main()
	-- init palette & screen
	gpu.setPaletteColor(0, 0x000000) -- 0 = black
	gpu.setPaletteColor(1, 0xFF0000) -- 1 = red
	gpu.setPaletteColor(2, 0x0000FF) -- 2 = blue
	gpu.setPaletteColor(3, 0xFFFFFF) -- 3 = white
	gpu.setPaletteColor(4, 0x00FF00) -- 4 = green

	gpu.setForeground(0, true)
	gpu.setBackground(0, true)
	
	gpu.fill(1, 1, screenWidthChars, screenHeightChars, '▀')
	
	-- make sure the reactor is on
	reac.setActive(true)
	reac.setAllControlRodLevels(100)
	rFuelAmountMax = reac.getFuelAmountMax()
	
	-- set the PID loop running
	-- These parameters are tuned for a 1.26 MRF/t reactor
	-- If tuning your own reactor, keep in mind that response time is very very slow
	-- err is positive when power is below the target
	-- positive output will increase power production
	-- (target, overshoot factor, integral size, derivative size, kp, ki, kd)
	pg.setTextColor(3)
	rc.setParameters(0.8, 4, 20, 5, 0.0003, 0.00005, 0.005)
	rc.start()
	event.timer(0.2, rc.runPIDStep, math.huge)
	
	initGraphics()
	
	-- graphics
	while true do
		getReactorStatus()
		
		updateGraphics()
		
		os.sleep(1)
	end
end

-- initGraphics()
-- Initializes graphics
function initGraphics()
	ro.initGraph(graphX, powerGraphY, graphWidth, graphHeight, 3)
	ro.initGraph(graphX, rodGraphY, graphWidth, graphHeight, 3)
end

-- updateGraphics()
-- Updates the graphics
function updateGraphics()
	-- update graphs
	ro.shiftGraph(graphX, powerGraphY, graphWidth, graphHeight, 0)
	ro.shiftGraph(graphX, rodGraphY, graphWidth, graphHeight, 0)
	
	ro.plotPoint(graphX, powerGraphY, graphWidth, graphHeight, rc.getOutput(), 2)
	ro.plotPoint(graphX, powerGraphY, graphWidth, graphHeight, rEnergyStored / 10000000, 1)
	
	ro.plotPoint(graphX, rodGraphY, graphWidth, graphHeight, 0.5, 3)
	ro.plotPoint(graphX, rodGraphY, graphWidth, graphHeight, -math.min(0.5, math.max(-0.5, rc.getError())) + 0.5, 1)
	ro.plotPoint(graphX, rodGraphY, graphWidth, graphHeight, -math.min(0.5, math.max(-0.5, rc.getIntegral() / 5)) + 0.5, 4)
	ro.plotPoint(graphX, rodGraphY, graphWidth, graphHeight, -math.min(0.5, math.max(-0.5, rc.getDerivative() * 1)) + 0.5, 2)
	
	
	-- status bars
	local productionPercent = rLastTickEnergy / rMaxTickEnergy
	local rodsPercent = rc.getOutput()
	local bufferPercent = rEnergyStored / 10000000
	local fuelPercent = rFuelAmount / rFuelAmountMax
	local deltaPercent = (-rc.getError() / 2) + 0.5
	
	ro.drawVBar((barWidthPixels + 2) * 0, 2, barWidthPixels, barHeightPixels, fuelPercent, false, 3, 2, 0)
	ro.drawVBar((barWidthPixels + 2) * 1, 2, barWidthPixels, barHeightPixels, productionPercent, false, 3, 1, 0)
	ro.drawVBar((barWidthPixels + 2) * 2, 2, barWidthPixels, barHeightPixels, rodsPercent, true, 3, 3, 0)
	ro.drawVBar((barWidthPixels + 2) * 3, 2, barWidthPixels, barHeightPixels, bufferPercent, false, 3, 1, 0)
	ro.drawVBarLine((barWidthPixels + 2) * 4, 2, barWidthPixels, barHeightPixels, deltaPercent, false, 3, 1, 0)
	
	-- labels
	pg.setTextColor(3)
	
	term.setCursor(1 + 0, 1 + 0)
	term.write("fuel")
	
	term.setCursor(1 + barWidthChars + 2, 1 + 0)
	term.write("prod.")
	
	term.setCursor(1 + (barWidthChars + 2) * 2, 1 + 0)
	term.write("rods")
	
	term.setCursor(1 + (barWidthChars + 2) * 3, 1 + 0)
	term.write("buff.")
	
	term.setCursor(1 + (barWidthChars + 2) * 4, 1 + 0)
	term.write("delta")
	
	-- values
	term.setCursor(1 + 0, 1 + barHeightChars + 1)
	term.write(string.format("%"..barWidthChars.."d", math.floor(rFuelAmount)))
	term.setCursor(1 + barWidthChars, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + barWidthChars + 2, 1 + barHeightChars + 1)
	term.write(string.format("%"..barWidthChars.."d", math.floor(rLastTickEnergy)))
	term.setCursor(1 + barWidthChars + barWidthChars + 2, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + (barWidthChars + 2) * 2, 1 + barHeightChars + 1)
	term.write(string.format("%"..barWidthChars.."d", math.floor(rc.getOutput() * 1000)))
	term.setCursor(1 + barWidthChars + (barWidthChars + 2) * 2, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + (barWidthChars + 2) * 3, 1 + barHeightChars + 1)
	term.write(string.format("%"..barWidthChars.."d", math.floor(rEnergyStored)))
	term.setCursor(1 + barWidthChars + (barWidthChars + 2) * 3, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + (barWidthChars + 2) * 4, 1 + barHeightChars + 1)
	term.write(string.format("%"..barWidthChars.."d", math.floor(-rc.getError() * 100)))
	term.setCursor(1 + barWidthChars + (barWidthChars + 2) * 4, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + (barWidthChars + 2) * 4, 1 + barHeightChars + 2)
	term.write(string.format("%"..barWidthChars.."d", math.floor(-rc.getIntegral() * 100)))
	term.setCursor(1 + barWidthChars + (barWidthChars + 2) * 4, 1 + barHeightChars + 1)
	term.write(' ')
	
	term.setCursor(1 + (barWidthChars + 2) * 4, 1 + barHeightChars + 3)
	term.write(string.format("%"..barWidthChars.."d", math.floor(-rc.getDerivative() * 100)))
	term.setCursor(1 + barWidthChars + (barWidthChars + 2) * 4, 1 + barHeightChars + 1)
	term.write(' ')
end

-- getReactorStatus()
-- updates the reactor status variables
function getReactorStatus()
	rEnergyStored = reac.getEnergyStored()
	rFuelTemp = reac.getFuelTemperature()
	rCasingTemp = reac.getCasingTemperature()
	rFuelAmount = reac.getFuelAmount()
	rWasteAmount = reac.getWasteAmount()
	rControlRodLevel = reac.getControlRodLevel(1)
	rLastTickEnergy = reac.getEnergyProducedLastTick()
	rActive = reac.getActive()
	
	if rLastTickEnergy > rMaxTickEnergy then
		rMaxTickEnergy = rLastTickEnergy
	end
end

main()
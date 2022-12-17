
--
-- Reactor Readout
-- 
-- This module contains the graphics routines for drawing cool graphs
--
-- Author: Mechafinch
--

local readout = {}

local pg = require("pixelgraphics")

-- plotPoint(int x, int y, int w, int h, float p, int bc)
-- Plots a point on a graph. 
function readout.plotPoint(x, y, w, h, p, bc)
	pg.plot(x + w - 1, y + h - 2 - math.floor(p * (h - 2)), bc)
end

-- initGraph(int x, int y, int w, int h, int oc)
-- Draws the axis lines for a graph
function readout.initGraph(x, y, w, h, oc)
	-- x axis
	pg.drawHLine(x, y + h - 1, w, oc)
	
	-- y axis
	pg.drawVLine(x, y, h, oc)
end

-- shiftGraph(int x, int y, int w, int h, int nc)
-- Shifts a graph over 1 pixel to the left
function readout.shiftGraph(x, y, w, h, nc)
	local charX = x + 1
	local charY = math.floor(y / 2) + 1
	local charH = math.floor(h / 2)

	-- shift
	pg.getGPU().copy(charX + 2, charY, w, charH, -1, 0)
	
	-- clear rightmost line
	pg.drawVLine(x + w - 1, y, h - 1, nc)
end

-- drawVBar(int x, int y, int w, int h, float p, boolean d. int oc, int bc, int nc)
-- Draws a vertical bar readout starting at (x, y) with width w and height h
-- The bar is filled to according to p [0, 1]. If d is true, the bar is filled top-to-bottom
-- The outline is filled with color oc, the bar with bc, and the background with nc
-- w must be at least 3 and h must be at least 4
function readout.drawVBar(x, y, w, h, p, d, oc, bc, nc)
	-- integerize
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	w = math.max(0, math.floor(w))
	h = math.max(0, math.floor(h))
	
	-- calculate end of the fill area
	local barLength = math.floor(((h - 2) * p) + 0.5)
	local emptyLength = (h - 2) - barLength

	-- outline
	pg.outlineRect(x, y, w, h, oc)
	
	-- upper bar
	if d then
		pg.fillRect(x + 1, y + 1, w - 2, barLength, bc)
	else
		pg.fillRect(x + 1, y + 1, w - 2, emptyLength, nc)
	end
	
	-- lower bar
	if d then
		pg.fillRect(x + 1, y + 1 + barLength, w - 2, emptyLength, nc)
	else
		pg.fillRect(x + 1, y + 1 + emptyLength, w - 2, barLength, bc)
	end
end

-- drawVBarLine(int x, int y, int w, int h, float p, boolean d. int oc, int bc, int nc)
-- Draws a vertical bar readout starting at (x, y) with width w and height h
-- The bar is placed to according to p [0, 1]. If d is true, the bar is set top-to-bottom.
-- This function draws a single line instead of filling a full bar
-- The outline is filled with color oc, the bar with bc, and the background with nc
-- w must be at least 3 and h must be at least 4
function readout.drawVBarLine(x, y, w, h, p, d, oc, bc, nc)
	-- integerize
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	w = math.max(0, math.floor(w))
	h = math.max(0, math.floor(h))
	
	-- calculate end of the fill area
	local barPos = math.floor(((h - 2) * p) + 0.5)

	-- outline
	pg.outlineRect(x, y, w, h, oc)
	
	-- clear previous bar
	pg.fillRect(x + 1, y + 1, w - 2, h - 2, nc)
	
	-- draw
	pg.drawHLine(x + 1, y + barPos + 1, w - 2, bc)
end

return readout
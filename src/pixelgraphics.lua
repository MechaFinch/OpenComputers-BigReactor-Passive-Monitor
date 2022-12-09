
--
-- Opencomputers Pixel Graphics
--
-- Uses unicode graphics character '▀' to split characters into square pixels
-- If you look closely at the screen (the block, not the UI) you can see faint lines from this which
-- give a nice retro feel
--
-- A Tier 3 GPU can draw 8-16 pixels / tick depending on the need to change background/foreground
-- colors
--
-- Author: Mechafinch
--

local pixelgraphics = {}

local comp = require("component")
local gpu = comp.gpu

-- plot(int x, int y, int c)
-- plots a single pixel
function pixelgraphics.plot(x, y, c)
	local charX = x + 1
	local charY = (y / 2) + 1
	
	local currentChar, currentTopColorRaw, currentBottomColorRaw, currentTopColorIndex, currentBottomColorIndex = gpu.get(charX, charY)
	local isCharDifferent = false
	
	-- determine if the pixel is different and needs updating
	if y % 2 == 0 then
		-- upper pixel
		isCharDifferent = currentTopColorIndex ~= c
		
		newTopColor = c
		newBottomColor = currentBottomColorIndex
	else
		-- lower pixel
		isCharDifferent = currentBottomColorIndex ~= c
		
		newTopColor = currentTopColorIndex
		newBottomColor = c
	end
	
	if isCharDifferent then
		-- set foreground and background
		local currentForeground, fb = gpu.getForeground()
		local currentBackground, bb = gpu.getBackground()
		
		-- determine if the foreground is different
		local differentForeground = false
		local differentBackground = false
		
		if fb then
			differentForeground = currentForeground ~= newTopColor
		else
			differentForeground = currentForeground ~= gpu.getPaletteColor(newTopColor)
		end
		
		if bb then
			differentBackground = currentBackground ~= newBottomColor
		else
			differentBackground = currentBackground ~= gpu.getPaletteColor(newBottomColor)
		end
		
		-- update colors as needed
		if differentForeground then
			gpu.setForeground(newTopColor, true)
		end
		
		if differentBackground then
			gpu.setBackground(newBottomColor, true)
		end
		
		-- set
		gpu.set(charX, charY, '▀')
	end
end

-- fillRect(int x, int y, int w, int h, int c)
-- fills a rectangle with the top left at (x, y) of size (w, h) in color c
function pixelgraphics.fillRect(x, y, w, h, c)
	-- correct inputs to integers
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	w = math.max(0, math.floor(w))
	h = math.max(0, math.floor(h))
	
	for gx = x, (x + w - 1), 1 do
		for gy = y, (y + h - 1), 1 do
			pixelgraphics.plot(gx, gy, c)
		end
	end
end

-- outlineRect(int x, int y, int w, int h, int c)
-- draws the outline of a rectangle with top left at (x, y) of size (w, h) in color c
function pixelgraphics.outlineRect(x, y, w, h, c)
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	w = math.max(0, math.floor(w))
	h = math.max(0, math.floor(h))
	
	pixelgraphics.drawHLine(x, y, w, c)
	pixelgraphics.drawHLine(x, y + h - 1, w, c)
	
	pixelgraphics.drawVLine(x, y, h, c)
	pixelgraphics.drawVLine(x + w - 1, y, h, c)
end

-- drawHLine(int x, int y, int w, int c)
-- draws a line starting at (x, y) of length w to the right in color c
function pixelgraphics.drawHLine(x, y, w, c)
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	w = math.max(0, math.floor(w))
	
	for gx = x, (x + w - 1), 1 do
		pixelgraphics.plot(gx, y, c)
	end
end

-- drawVLine(int x, int y, int h, int c)
-- draws a line starting at (x, y) of length h down in color c
function pixelgraphics.drawVLine(x, y, h, c)
	x = math.max(0, math.floor(x))
	y = math.max(0, math.floor(y))
	h = math.max(0, math.floor(h))
	
	for gy = y, (y + h - 1), 1 do
		pixelgraphics.plot(x, gy, c)
	end
end

-- getPixelResolution()
-- gets the resolution (x, y) in pixels
function pixelgraphics.getPixelResolution()
	rx, ry = gpu.getResolution()
	return rx, ry * 2
end

-- getCharResolution()
-- gets the resolution (x, y) in characters
function pixelgraphics.getCharResolution()
	return gpu.getResolution()
end

-- setTextColor(int c)
-- Sets the gpu palette for outputting text (via term)
function pixelgraphics.setTextColor(c)
	gpu.setForeground(c, true)
	gpu.setBackground(0, true)
end

-- getGPU()
-- returns the gpu used by pixelgraphics
function pixelgraphics.getGPU()
	return gpu
end

return pixelgraphics
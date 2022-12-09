local comp = require("component")
local rc = require("rc")

local term = require("term")
local shell = require("shell")
term.clear()

-- I think I wrote this because I couldn't get modules to work when making the first version of this
-- but why change what works (also I already closed the game lmao)
shell.execute("mount rc_hdd /rc")
shell.setWorkingDirectory("/rc/")
os.execute("monitor.lua")

-- Keep any errors on-screen for a while before OS shell takes over
os.sleep(30)
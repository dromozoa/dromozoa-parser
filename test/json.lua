local unix = require "dromozoa.unix"

local json_module = ...
local json = require(json_module)

local source = io.read("*a")

local timer = unix.timer()
timer:start()
local data = json.decode(source)
timer:stop()
print(timer:elapsed())
print(#data)

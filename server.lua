-- Lua application for reading measurements from a nrf24 device
--
-- (C) 2013-2014 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT

-- package.path doesn't seem to exist for luvit, furthermore luvit wants
-- modules to exists in a modules directory, so following fixes this when
-- running with luajit
if package.path ~= nil then
	package.path = './modules/?.lua;' .. package.path
end

local radio = require("radio")
local time = require("time")
local nrf24 = require("nrf24")

local myRadio = radio.Radio:open(0, 0, 25)

if myRadio ~= nil then
	print(myRadio:version())
	myRadio:power_up()
	local start
	local diff
	local more
	local success = false
	local device
	local measurement
	while true do
		start = time.useconds_now()
		repeat
			success, more, device, measurement = pcall(radio.Radio.query, myRadio)
			if success then
				nrf24.printf('%08llx, %.4f\n', device, measurement)
			else
				print(more)
				more = false
			end
		until more == false
		repeat
			diff = time.useconds_now() - start
			nrf24.msleep(100)
		until diff > 1000000
	end
	myRadio:power_down()
	myRadio:close()
else
	print('failed to open nrf24')
end

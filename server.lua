-- Lua application for reading measurements from a nrf24 device
--
-- (C) 2013-2014 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT

require("radio")
require("time")
require("nrf24")

local radio = Radio:open(0, 0, 25)

if radio ~= nil then
	print(radio:version())
	radio:power_up()
	local start
	local diff
	local more
	local success = false
	local device
	local measurement
	while true do
		start = useconds_now()
		repeat
			success, more, device, measurement = pcall(Radio.query, radio)
			if success then
				nrf24_print('%08llx, %.4f\n', device, measurement)
			else
				print(more)
				more = false
			end
		until more == false
		repeat
			diff = useconds_now() - start
			nrf24_msleep(100)
		until diff > 1000000
	end
	radio:power_down()
	radio:close()
else
	print('failed to open nrf24')
end

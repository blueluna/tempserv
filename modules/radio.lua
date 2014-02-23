-- Radio package handling
--
-- (C) 2014 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT

local nrf24 = require("nrf24")
local decode = require("decode")
local time = require("time")
local string = require("string")

local Radio = { nrf = nil }

function Radio:open(spi_master, spi_device, ce_pin)
	local nrf = nrf24.Nrf24:create(spi_master, spi_device, ce_pin)
	obj = nil
	if nrf ~= nil then
		obj = obj or {}
		setmetatable(obj, self)
		self.__index = self
		self.nrf = nrf
		self.nrf:setup(1, 250, 0, "serv1", "clie1", 32, 1, 5, 2000)
	else
		error("failed to create Nrf24 object")
	end
	return obj
end

function Radio:version()
	return string.format("libnrf24 %d.%d.%d (%s)", nrf24.version())
end

function Radio:close()
	self.nrf:destroy()
end

function Radio:power_up()
	self.nrf:power_up()
	nrf24.msleep(2) -- let the radio power up
end

function Radio:power_down()
	self.nrf:power_down()
end

function Radio:query()
	local result
	local tx_data = {0x01} -- 0x01 means query
	local ready
	local start
	local now
	local diff
	local rx_data
	local rx_data_len = 0
	ready = false
	count = 0
	-- send query, with retry
	start = time.useconds_now()
	repeat
		result = self.nrf:send(tx_data)
		if result < 0 then
			now = time.useconds_now()
			diff = now - start
			if (diff >= 20000) then
				break;
			else
				nrf24.usleep(1000) -- wait some
			end
		else
			break;
		end
	until true
	if result < 0 then
		error("Failed to send message")
	end
	-- we seem to be required to wait some here otherwise start_listen seems
	-- to fail
	nrf24.usleep(700)
	-- start listening for reply
	self.nrf:start_listen()
	-- wait some, the response seems to ready after ~6 ms at earliest
	nrf24.msleep(6)
	start = time.useconds_now()
	while ready == false do
		ready = self.nrf:data_ready()
		if not ready then
			now = time.useconds_now()
			diff = now - start
			if diff >= 200000 then
				break;
			else
				nrf24.msleep(5) -- wait some
			end
		end
	end
	rx_data_len = 0
	if ready then
		rx_data, rx_data_len = self.nrf:receive()
	end
	self.nrf:stop_listen()
	-- parse the response if any
	if rx_data_len > 0 then
		state, arg1, arg2 = Radio:handle_package(rx_data, rx_data_len)
		if state == 'device_data' then
			return true, arg1, arg2
		elseif state == 'device_error' then
			error(string.format('Device Error: %04x', arg1))
		elseif state == 'error_command' then
			error(string.format('Remote Unknown Command: %02x\n', arg1))
		elseif state == 'error' then
			error(string.format('Error: %02x\n', arg1))
		elseif state == 'error_unknown_command' then
			error(string.format('Unknown Command: %02x\n', arg1))
		else
			return false
		end
	else
		error("Failed to receive response")
	end
end

function Radio:handle_package(package_data, package_data_length)
	local data = package_data
	local len = package_data_length
	local offset = 0
	local command = decode.uint8(data, len)
	offset = offset + 1
	len = len - 1
	if command == 0x81 then
		local code = decode.int16(data+offset, len)
		offset = offset + 2
		len = len - 2
		if code == 0x0000 then
			local device = decode.uint64(data+offset, len)
			offset = offset + 8
			len = len - 8
			local value = decode.int32(data+offset, len)
			offset = offset + 4
			len = len - 4
			real_value = value / 1000000.0
			return 'device_data', device, real_value
		elseif code == 0x000f then
			return 'device_end'
		else
			error(string.format('Device Error: %04x', code))
		end
	elseif command == 0xff then
		local code = decode.int16(data+offset, len)
		offset = offset + 2
		len = len - 2
		if code == 12 then
			local received_command = decode.uint8(data+offset, len)
			return 'error_command', received_command
		else
			return 'error', code
		end
	else
		return 'error_unknown_command', command
	end
end

return { Radio = Radio }

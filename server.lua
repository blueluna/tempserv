require("nrf24")
require("decode")
require("time")

function handle_package(package_data, package_data_length)
	local data = package_data
	local len = package_data_length
	local offset = 0
	local command = decode_uint8(data, len)
	offset = offset + 1
	len = len - 1
	if command == 0x81 then
		local code = decode_int16(data+offset, len)
		offset = offset + 2
		len = len - 2
		if code == 0x0000 then
			local device = decode_uint64(data+offset, len)
			offset = offset + 8
			len = len - 8
			local value = decode_int32(data+offset, len)
			offset = offset + 4
			len = len - 4
			real_value = value / 1000000.0
			return 'device_data', device, real_value
		elseif code == 0x000f then
			return 'device_end'
		else
			return 'device_error', code
		end
	elseif command == 0xff then
		local code = decode_int16(data+offset, len)
		offset = offset + 2
		len = len - 2
		if code == 12 then
			local received_command = decode_uint8(data+offset, len)
			return 'error_command', received_command
		else
			return 'error', code
		end
	else
		return 'error_unknown_command', command
	end
end

print(string.format("loaded libnrf24 %d.%d.%d (%s)", nrf24_version()))

local nrf = Nrf24:create(0, 0, 25)
if nrf ~= nil then
	local result = nrf:setup(1, 250, 0, "serv1", "clie1", 32, 1, 5, 2000)
	if result == 0 then
		local tx_data = {0x01}
		local ready
		local start
		local rx_start
		local time
		local sec_time
		local diff
		local rx_data
		local rx_data_len = 0
		local more
		while true do
			nrf:power_up()
			nrf24_msleep(2)
			start = useconds_now()
			repeat
				time = useconds_now()
				sec_time = time / 1000000.0
				more = false
				ready = false
				repeat
					result = nrf:send(tx_data)
					nrf24_usleep(900)
				until result >= 0
				nrf:start_listen()
				rx_start = useconds_now()
				while ready == false do
					ready = nrf:data_ready()
					time = useconds_now()
					diff = time - rx_start
					if diff >= 200000 then
						break;
					end
				end
				sec_time = time / 1000000.0
				rx_data_len = 0
				if ready then
					rx_data, rx_data_len = nrf:receive()
				end
				nrf:stop_listen()
				nrf24_usleep(500)
				if rx_data_len > 0 then
					state, arg1, arg2 = handle_package(rx_data, rx_data_len)
					if state == 'device_data' then
						nrf24_print('%.3f %08llx, %.4f\n', sec_time, arg1, arg2)
						more = true
					elseif state == 'device_error' then
						nrf24_print('%.3f Device Error: %04x\n', sec_time, arg1)
					elseif state == 'error_command' then
						nrf24_print('%.3f Remote Unknown Command: %02x\n', sec_time, arg1)
					elseif state == 'error' then
						nrf24_print('%.3f Error: %02x\n', sec_time, arg1)
					elseif state == 'error_unknown_command' then
						nrf24_print('%.3f Unknown Command: %02x\n', sec_time, arg1)
					end
				else
					nrf24_print('%.3f Timeout\n', sec_time)
					nrf24_msleep(5)
				end
			until more == false
			nrf:power_down()
			repeat
				diff = useconds_now() - start
				nrf24_msleep(100)
			until diff > 1000000
		end
	else
		print('failed to setup nrf24 ' .. result)
	end
	nrf:destroy()
else
	print('failed to open nrf24')
end

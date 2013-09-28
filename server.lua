require("nrf24")
require("decode")
require("time")

local nrf = Nrf24:create(0, 0, 25)
if nrf ~= nil then
	local result = nrf:setup(1, 250, 0, "serv1", "clie1", 32, 1, 5, 2000)
	if result == 0 then
		local tx_data = {0x01}
		local ready
		local start
		local rx_start
		local time
		local diff
		local rx_data
		local rx_data_len = 0
		local more
		while true do
			nrf:power_up()
			nrf24_msleep(2)
			start = useconds_now()
			repeat
				more = false
				ready = false
				result = nrf:send(tx_data)
				nrf24_usleep(900)
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
				rx_data_len = 0
				if ready then
					rx_data, rx_data_len = nrf:receive()
				end
				nrf:stop_listen()
				nrf24_usleep(500)
				if rx_data_len > 0 then
					local len = rx_data_len
					local offset = 0
					local command = decode_uint8(rx_data, len)
					offset = offset + 1
					len = len - 1
					if command == 0x81 then
						local code = decode_int16(rx_data+offset, len)
						offset = offset + 2
						len = len - 2
						if code == 0x0000 then
							local device = decode_uint64(rx_data+offset, len)
							offset = offset + 8
							len = len - 8
							local value = decode_int32(rx_data+offset, len)
							offset = offset + 4
							len = len - 4
							real_value = value / 1000000.0
							nrf24_print('%.3f, %08llx, %.4f, ', time / 1000000.0, device, real_value)
							more = true
						elseif code == 0x000f then
							nrf24_print('\n')
						else
							print('unknown code: ' .. tostring(code))
						end
					elseif command == 0xff then
						local code = decode_int16(rx_data+offset, len)
						offset = offset + 2
						len = len - 2
						print('error: ' .. code)
						nrf24_msleep(100)
					end
				else
					print("Timeout")
					nrf24_msleep(5)
				end
			until more == false
			nrf:power_down()
			repeat
				diff = useconds_now() - start
				nrf24_msleep(100)
			until diff > 10000000
		end
	end

	nrf:destroy()
end

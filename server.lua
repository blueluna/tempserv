require("nrf24")
require("decode")
require("time")

local nrf = Nrf24:create(0, 0, 25)
if nrf ~= nil then
	nrf:power_down()
	nrf24_msleep(1000)
	nrf:power_up()
	local result = nrf:setup(1, 250, 0, "clie1", "serv1", 32, 1, 5, 2000)
	if result == 0 then
		local tx_data = {0x01}
		local ready
		local tx_start
		local rx_start
		local time
		local diff
		local rx_data
		local rx_data_len
		while true do
			tx_start = useconds_now()
			ready = false
			result = nrf:send(tx_data)
			print('Send: ' .. result)
			nrf24_msleep(1)
			nrf:start_listen()
			rx_start = useconds_now()
			while ready == false do
				ready = nrf:data_ready()
				time = useconds_now()
				diff = time - rx_start
				if diff >= 2000000 then
					break;
				end
			end
			if ready then
				rx_data, rx_data_len = nrf:receive()
				nrf:stop_listen()
				nrf24_msleep(10)
				
				local len = rx_data_len
				local offset = 0
				local command = decode_uint8(rx_data, len)
				offset = offset + 1
				len = len - 1
				if (command == 0x81) then
					local code = decode_int16(rx_data+offset, len)
					offset = offset + 2
					len = len - 2
					if (code == 0x0000) then
						local device = decode_uint64(rx_data+offset, len)
						offset = offset + 8
						len = len - 8
						local value = decode_int32(rx_data+offset, len)
						offset = offset + 4
						len = len - 4
						real_value = value / 1000000.0
						print(real_value)
					elseif (code == 0x000f) then
						print('no more sensors')
						nrf24_msleep(1000)
					else
						print('unknown code: ' .. tostring(code))
					end
				elseif (command == 0xff) then
					local code = decode_int16(rx_data+offset, len)
					offset = offset + 2
					len = len - 2
					print('error: ' .. code)
					nrf24_msleep(1000)
				end
			else
				print("Timeout")
			end
		end
	end

	nrf:destroy()
end

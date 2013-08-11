local nrf24 = require("nrf24")

local nrf = Nrf24:create(0, 0, 25)
print("Setup")
local result = nrf:setup(1, 250, 0, "clie1", "serv1", 32, 1)
print(result)
local tx_data = {0x01}
print("Send")
local bfmt = "%02x"
result = nrf:send(tx_data)
print(result)
print("Listen")
nrf:start_listen()
local ready = false
while (ready == false) do
	ready = nrf:data_ready()
end
print("Receive")
local rx_data = nrf:receive()
for n = 1,#rx_data do
	io.write(bfmt:format(rx_data[n]))
end
print("")
print("End")
nrf:stop_listen()
nrf:destroy()

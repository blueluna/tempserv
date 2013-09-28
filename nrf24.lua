-- Interface against nRF24L01 through libnrf24
-- (C) 2013 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT
--
-- Requirements
-- * LuaJIT, http://luajit.org/
-- * libnrf24, https://github.com/blueluna/libnrf24

local ffi = require("ffi")

ffi.cdef[[
int printf(const char *fmt, ...);

void nrf24_usleep(const uint32_t microseconds);
void nrf24_msleep(const uint32_t milliseconds);

int32_t nrf24_spi_open(const uint32_t controller, const uint32_t device, const uint32_t speed, const uint8_t bits, const uint8_t mode);
int32_t nrf24_spi_close(const int32_t handle);

typedef struct nrf24_ctx_s {
  int32_t spi_handle;
  uint16_t ce_pin;
  uint8_t *rx_buf;
  uint8_t *tx_buf;
} nrf24_ctx_t;

typedef nrf24_ctx_t* nrf24_handle;

nrf24_handle nrf24_open(const int32_t spi_handle, const uint16_t ce_pin);
int32_t nrf24_close(nrf24_handle handle);

int32_t nrf24_get_register(nrf24_handle handle, const uint8_t address, uint8_t *value);
int32_t nrf24_set_register(nrf24_handle handle, const uint8_t address, const uint8_t value);

int32_t nrf24_powerup(nrf24_handle handle);
int32_t nrf24_powerdown(nrf24_handle handle);

int32_t nrf24_get_crc(nrf24_handle handle, uint8_t *bytes);
int32_t nrf24_set_crc(nrf24_handle handle, const uint8_t bytes);

int32_t nrf24_get_channel(nrf24_handle handle, uint8_t *channel);
int32_t nrf24_set_channel(nrf24_handle handle, const uint8_t channel);

int32_t nrf24_get_data_rate(nrf24_handle handle, uint8_t *data_rate);
int32_t nrf24_set_data_rate(nrf24_handle handle, const uint8_t data_rate);

int32_t nrf24_get_power(nrf24_handle handle, uint8_t *power);
int32_t nrf24_set_power(nrf24_handle handle, const uint8_t power);

int32_t nrf24_get_rx_payload_length(nrf24_handle handle, const uint8_t pipe, uint8_t *length);
int32_t nrf24_set_rx_payload_length(nrf24_handle handle, const uint8_t pipe, const uint8_t length);

int32_t nrf24_get_auto_retransmit(nrf24_handle handle, uint8_t *retries, uint16_t *delay);
int32_t nrf24_set_auto_retransmit(nrf24_handle handle, const uint8_t retries, const uint16_t delay);

int32_t nrf24_clear_status(nrf24_handle handle);

int32_t nrf24_get_rx_address(nrf24_handle handle, const uint8_t pipe, uint8_t *address, const uint32_t address_len);
int32_t nrf24_set_rx_address(nrf24_handle handle, const uint8_t pipe, const uint8_t *address, const uint32_t address_len);
int32_t nrf24_set_rx_address_byte(nrf24_handle handle, const uint8_t pipe, const uint8_t address);

int32_t nrf24_get_tx_address(nrf24_handle handle, uint8_t *address, const uint32_t address_len);
int32_t nrf24_set_tx_address(nrf24_handle handle, const uint8_t *address, const uint32_t address_len);

int32_t nrf24_flush_rx(nrf24_handle handle);
int32_t nrf24_flush_tx(nrf24_handle handle);

int32_t nrf24_start_listen(nrf24_handle handle);
int32_t nrf24_stop_listen(nrf24_handle handle);

int32_t nrf24_get_status(nrf24_handle handle, uint8_t *data_ready, uint8_t *data_sent, uint8_t *max_retry);

int32_t nrf24_send(nrf24_handle handle, const uint8_t *data, const uint8_t len);
int32_t nrf24_receive(nrf24_handle handle, uint8_t *data, const uint8_t len);
]]

local lib = ffi.load("nrf24")

function nrf24_print(fmt, ...)
	return lib.printf(fmt, ...)
end

function nrf24_msleep(milliseconds)
	 return lib.nrf24_msleep(milliseconds)
end

function nrf24_usleep(microseconds)
	 return lib.nrf24_usleep(microseconds)
end

Nrf24 = { handle = ffi.new("nrf24_ctx_t[1]"), spi_handle = -1 }

function Nrf24:create(spi_master, spi_device, ce_pin)
	local spi_handle = lib.nrf24_spi_open(spi_master, spi_device, 2000000, 8, 0)
	obj = nil
	if spi_handle >= 0 then
		obj = obj or {}
		setmetatable(obj, self)
		self.__index = self
		self.payload_length = 0
		self.spi_handle = spi_handle
		self.handle = lib.nrf24_open(spi_handle, ce_pin)
		self.payload_buffer = ffi.new("uint8_t[32]");
	else
		print(string.format("SPI open failed with %d", spi_handle))
		self.spi_handle = -1
	end
	return obj
end

function Nrf24:destroy()
	lib.nrf24_close(self.handle)
	lib.nrf24_spi_close(self.spi_handle)
end

function Nrf24:get_register(address)
	local value = ffi.new("uint8_t[1]");
	local result = lib.nrf24_get_register(self.handle, address, value)
	if result >= 0 then
		return value[0]
	else
		return result
	end
end

function Nrf24:setup(channel, rate, power, tx_address, rx_address, payload_len, crc_bytes, retries, retry_delay)
	if #tx_address < 5 then
		return -1;
	end
	if #rx_address < 5 then
		return -1;
	end
	if payload_len <= 32 then
		self.payload_length = payload_len
	else
		return -1;
	end
	local result = lib.nrf24_set_channel(self.handle, channel)
	if result < 0 then
		return result
	end
	if rate == 2000 then
		result = lib.nrf24_set_data_rate(self.handle, 0)
	elseif rate == 1000 then
		result = lib.nrf24_set_data_rate(self.handle, 1)
	else
		result = lib.nrf24_set_data_rate(self.handle, 2)
	end
	if result < 0 then
		return result
	end
	if power == 0 then
		result = lib.nrf24_set_power(self.handle, 6)
	elseif rate == -6 then
		result = lib.nrf24_set_power(self.handle, 4)
	elseif rate == -12 then
		result = lib.nrf24_set_power(self.handle, 2)
	else
		result = lib.nrf24_set_power(self.handle, 0) -- -18 dBm
	end
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_tx_address(self.handle, tx_address, 5)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_rx_address(self.handle, 0, tx_address, 5)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_rx_address(self.handle, 1, rx_address, 5)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_rx_payload_length(self.handle, 0, self.payload_length)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_rx_payload_length(self.handle, 1, self.payload_length)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_crc(self.handle, crc_bytes)
	if result < 0 then
		return result
	end
	result = lib.nrf24_set_auto_retransmit(self.handle, retries, retry_delay)
	if result < 0 then
		return result
	end

	lib.nrf24_clear_status(self.handle)
	lib.nrf24_flush_rx(self.handle)
	lib.nrf24_flush_tx(self.handle)
	return 0;
end

function Nrf24:start_listen()
	lib.nrf24_start_listen(self.handle)
end

function Nrf24:stop_listen()
	lib.nrf24_stop_listen(self.handle)
end

function Nrf24:data_ready()
	local dr = ffi.new("uint8_t[1]");
	local result = lib.nrf24_get_status(self.handle, dr, nil, nil);
	if result >= 0 then
		if dr[0] == 0 then
			return false
		else
			return true
		end
	end
	return false
end

function Nrf24:send(data)
	local len = 0
	if #data > self.payload_length then
		return -1
	end
	for n=0, (self.payload_length - 1) do
		self.payload_buffer[n] = 0
	end
	for n=1, #data do
		self.payload_buffer[n - 1] = data[n]
	end
	return lib.nrf24_send(self.handle, self.payload_buffer, self.payload_length)
end

function Nrf24:receive()
	bytes = {}
	local result = lib.nrf24_receive(self.handle, self.payload_buffer, self.payload_length)
	if result >= 0 then
		for n = 1,self.payload_length do
			bytes[n] = self.payload_buffer[n - 1]
		end
	end
	return bytes
end

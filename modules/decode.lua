-- Decoding C-types from byte stream
--
-- (C) 2013-2014 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT
--
-- Requirements
-- * LuaJIT, http://luajit.org/
-- * libnrf24, https://github.com/blueluna/libnrf24

local ffi = require("ffi")

ffi.cdef[[
int32_t nrf24_decode_int8(int8_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_uint8(uint8_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_int16(int16_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_uint16(uint16_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_int32(int32_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_uint32(uint32_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_int64(int64_t *value, const uint8_t *bytes, const int32_t len);
int32_t nrf24_decode_uint64(uint64_t *value, const uint8_t *bytes, const int32_t len);
]]

local lib = ffi.load("nrf24")

local function int8(buffer, len)
	local value = ffi.new("int8_t[1]");
	local result = lib.nrf24_decode_int8(value, buffer, len)
	if result == 1 then
		return value[0]
	end
	return nil
end

local function uint8(buffer, len)
	local value = ffi.new("uint8_t[1]");
	local result = lib.nrf24_decode_uint8(value, buffer, len)
	if result == 1 then
		return value[0]
	end
	return nil
end

local function int16(buffer, len)
	local value = ffi.new("int16_t[1]");
	local result = lib.nrf24_decode_int16(value, buffer, len)
	if result == 2 then
		return value[0]
	end
	return nil
end

local function uint16(buffer, len)
	local value = ffi.new("uint16_t[1]");
	local result = lib.nrf24_decode_uint16(value, buffer, len)
	if result == 2 then
		return value[0]
	end
	return nil
end

local function int32(buffer, len)
	local value = ffi.new("int32_t[1]");
	local result = lib.nrf24_decode_int32(value, buffer, len)
	if result == 4 then
		return value[0]
	end
	return nil
end

local function uint32(buffer, len)
	local value = ffi.new("uint32_t[1]");
	local result = lib.nrf24_decode_uint32(value, buffer, len)
	if result == 4 then
		return value[0]
	end
	return nil
end

local function int64(buffer, len)
	local value = ffi.new("int64_t[1]");
	local result = lib.nrf24_decode_int64(value, buffer, len)
	if result == 8 then
		return value[0]
	end
	return nil
end

local function uint64(buffer, len)
	local value = ffi.new("uint64_t[1]");
	local result = lib.nrf24_decode_uint64(value, buffer, len)
	if result == 8 then
		return value[0]
	end
	return nil
end

return {
	int8 = int8,
	uint8 = uint8,
	int16 = int16,
	uint16 = uint16,
	int32 = int32,
	uint32 = uint32,
	int64 = int64,
	uint64 = uint64
}

-- 
-- (C) 2013 Erik Svensson <erik.public@gmail.com>
-- Licensed under MIT
--
-- Requirements
-- * LuaJIT, http://luajit.org/

local ffi = require("ffi")

ffi.cdef[[
struct timeval {
    long 	tv_sec;
    long 	tv_usec;
};
int gettimeofday(struct timeval *tv, struct timezone *tz);
]]

function useconds_now()
	local tv = ffi.new("struct timeval [1]")
	local usec = 0
	local result = ffi.C.gettimeofday(tv, nil)
	if (result == 0) then
		usec = ffi.new("int64_t")
		local sec = ffi.new("int64_t")
		usec = tv[0].tv_usec;
		sec = tv[0].tv_sec
		usec = usec + (sec * 1000000)
	end
	return usec
end

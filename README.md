Tempserv
========

Service for retreiving temperatures from an Arduino board using nRF24L01 as transport.

Hardware requirements
---------------------

 * A nRF24L01 chip connected to a SPI bus and a GPIO pin (CE) available in user space (/dev/spidev, /sys/class/gpio).

Software requirements
---------------------

 * LuaJIT, http://luajit.org/
 * libnrf24, https://github.com/blueluna/libnrf24

Copyright
---------

Released under the MIT license.

(C) 2013 Erik Svensson, <erik.public@gmail.com>.

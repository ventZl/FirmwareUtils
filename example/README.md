FIRMWAREUTILS EXAMPLE
=====================

This is simple example of how FirmwareUtils can be used. This example defines
two subprojects:

* hello_cross - This subproject will be built using AVR GCC
* hello_native - This subproject will be built using native toolchain

In order to build this project as a whole, you need AVR GCC (preferably located
in /opt/avr/), native compiler and obviously CMake and any build driver of your
choice (such as Make or Ninja).

    mkdir build && cd build
	cmake ..
	make all

You will get two binaries, one inside `build/hello_cross/src/cross/hello.elf`
and another inside `build/hello_native/src/native/hello`. Note that except of
`hello_cross` and `hello_native`, the output path is completely within what you
could expect from bare CMake build. It is up to you where your binaries will end
up.

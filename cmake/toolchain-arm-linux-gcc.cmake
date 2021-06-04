# Copyright (C) 2021 Eduard Drusa
# SPDX-License-Identifier: MPL-2.0

if (NOT EXISTS CACHE{GCC_EXE})
	find_program(GCC_EXE arm-none-linux-gnueabihf-gcc
		PATHS
		/opt/arm/bin
		/opt/arm-none-linux-gnueabihf/bin
		ENV CROSS_GCC_PATH
		DOC "ARM cross-compiler toolchain location")
endif()

if (NOT EXISTS CACHE{LD_EXE})
	find_program(LD_EXE arm-none-linux-gnueabihf-ld
		PATHS
		/opt/arm/bin
		/opt/arm-none-linux-gnueabihf/bin
		ENV CROSS_GCC_PATH
		DOC "ARM cross-compiler linker location")
endif()

if (NOT EXISTS CACHE{OBJCOPY_EXE})
	find_program(OBJCOPY_EXE arm-none-linux-gnueabihf-objcopy
		PATHS
		/opt/arm/bin
		/opt/arm-none-linux-gnueabihf/bin
		ENV CROSS_GCC_PATH
		DOC "ARM objcopy location")
endif()

if (NOT EXISTS CACHE{AR_EXE})
	find_program(AR_EXE arm-none-linux-gnueabihf-gcc-ar
		PATHS
		/opt/arm/bin
		/opt/arm-none-linux-gnueabihf/bin
		ENV CROSS_GCC_PATH
		DOC "ARM archiver location")
endif()

if (NOT EXISTS CACHE{RANLIB_EXE})
	find_program(RANLIB_EXE arm-none-linux-gnueabihf-gcc-ranlib
		PATHS
		/opt/arm/bin
		/opt/arm-none-linux-gnueabihf/bin
		ENV CROSS_GCC_PATH
		DOC "ARM ranlib location")
endif()

if ("${GCC_EXE}" STREQUAL "GCC_EXE-NOTFOUND")
	message(FATAL_ERROR "Unable to find arm-none-linux-gnueabihf GCC toolchain! Either place it in one of following locations:\n/opt/arm/bin\n/usr/bin\n/usr/local/bin\nor provide its path in CROSS_GCC_PATH environment variable!")
endif()

add_definitions(-fuse-linker-plugin)

set(CMAKE_C_COMPILER "${GCC_EXE}")
set(CMAKE_ASM_COMPILER "${GCC_EXE}")
set(CMAKE_C_LINKER "${LD_EXE}")
set(CMAKE_AR "${AR_EXE}")
set(CMAKE_RANLIB "${RANLIB_EXE}")
set(CMAKE_SYSTEM_NAME "Linux")
set(CMAKE_SYSTEM_PROCESSOR "arm")
#set(CMAKE_SYSROOT /opt/arm-debian-rootfs)

set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_EXECUTABLE_SUFFIX_C "")
set(CMAKE_EXE_LINKER_FLAGS "-Wall -flto")# --plugin=/opt/arm-none-linux-gnueabihf/libexec/gcc/avr/4.9.3/liblto_plugin.so")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)


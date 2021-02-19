if (NOT EXISTS CACHE{GCC_EXE})
	find_program(GCC_EXE arm-none-eabi-gcc
		PATHS
		/opt/arm/bin
		/opt/arm-none-eabi/bin
		NO_DEFAULT_PATH
		ENV CROSS_GCC_PATH
		DOC "ARM cross-compiler toolchain location")
endif()

if (NOT EXISTS CACHE{LD_EXE})
	find_program(LD_EXE arm-none-eabi-ld
		PATHS
		/opt/arm/bin
		/opt/arm-none-eabi/bin
		NO_DEFAULT_PATH
		ENV CROSS_GCC_PATH
		DOC "ARM cross-compiler linker location")
endif()

if (NOT EXISTS CACHE{OBJCOPY_EXE})
	find_program(OBJCOPY_EXE arm-none-eabi-objcopy
		PATHS
		/opt/arm/bin
		/usr/bin
		/usr/local/bin
		ENV CROSS_GCC_PATH
		DOC "ARM objcopy location")
endif()

if ("${GCC_EXE}" STREQUAL "GCC_EXE-NOTFOUND")
	message(FATAL_ERROR "Unable to find arm-none-eabi GCC toolchain! Either place it in one of following locations:\n/opt/arm/bin\n/usr/bin\n/usr/local/bin\nor provide its path in CROSS_GCC_PATH environment variable!")
endif()

add_link_options(--specs=nosys.specs)
add_definitions(-fuse-linker-plugin)

set(CMAKE_C_COMPILER "${GCC_EXE}")
set(CMAKE_ASM_COMPILER "${GCC_EXE}")
set(CMAKE_C_LINKER "${LD_EXE}")
set(CMAKE_SYSTEM_NAME "Generic")
set(CMAKE_SYSTEM_PROCESSOR "arm")
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_EXECUTABLE_SUFFIX_C ".elf")

set(CMAKE_EXE_LINKER_FLAGS "-Wall -flto") # --plugin=/opt/avr/libexec/gcc/avr/4.9.3/liblto_plugin.so")

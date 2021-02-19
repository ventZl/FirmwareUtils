cmake_minimum_required(VERSION 3.3)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

include(FirmwareUtils)

# Automatically ignore this build dir in git status view
file(WRITE ${CMAKE_BINARY_DIR}/.gitignore "*")

project(HelloWorld LANGUAGES NONE)

if (NOT SUBPROJECT)
	add_firmware(hello_cross
		ARCH arm
		TARGET cortex-m0plus
		TOOLCHAIN gcc
		VARIANT cross
		)

	add_native_code(hello_native
		VARIANT native
		)
else()
	enable_language(C)
	enable_language(ASM)
	include(${SUBPROJECT}.cmake)
endif()

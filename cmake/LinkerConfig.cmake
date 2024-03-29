# Copyright (C) 2021 Eduard Drusa
# SPDX-License-Identifier: MPL-2.0

if (NOT DEVICE)
	message(FATAL_ERROR "No target device selected! Please define variable DEVICE to contain *full* name of your MCU!")
endif()

message(STATUS "Target: ${DEVICE}")

set(DATA_FILE ${CMAKE_SOURCE_DIR}/libopencm3/ld/devices.data)

if (NOT EXISTS ${DATA_FILE})
	message(FATAL_ERROR "Unable to find device data file ${DATA_FILE}!")
endif()

function(_genlink_obtain DEVICE PROPERTY OUTPUT)
	message(DEBUG "python ${CMAKE_SOURCE_DIR}/libopencm3/scripts/genlink.py ${DATA_FILE} ${DEVICE} ${PROPERTY}")
	execute_process(COMMAND python ${CMAKE_SOURCE_DIR}/libopencm3/scripts/genlink.py ${DATA_FILE} ${DEVICE} ${PROPERTY}
		OUTPUT_VARIABLE OUT_DATA
		RESULT_VARIABLE SUCCESS
		)
	if ("${SUCCESS}" EQUAL "0")
		message(DEBUG ">> ${OUT_DATA}")
		set("${OUTPUT}" "${OUT_DATA}" PARENT_SCOPE)
	else()
		message(FATAL_ERROR "Unable to obtain ${PROPERTY} for device ${DEVICE}!")
	endif()
endfunction()

set(TARGETGROUP stm32 sam gd32 lpc13xx lpc17xx lpc43xx lm3s lm4f msp432 efm32 sam vf6xx swm050 pac55xx)

_genlink_obtain(${DEVICE} FAMILY DEVICE_FAMILY)
_genlink_obtain(${DEVICE} SUBFAMILY DEVICE_SUBFAMILY)
_genlink_obtain(${DEVICE} CPU DEVICE_CPU)
_genlink_obtain(${DEVICE} FPU DEVICE_FPU)
_genlink_obtain(${DEVICE} CPPFLAGS DEVICE_CPPFLAGS)
_genlink_obtain(${DEVICE} DEFS DEVICE_DEFS)

# Build libopencm3 here. Otherwise library search process below will fail
foreach (TGT ${TARGETGROUP})
	string(REPLACE "${TGT}" "${TGT}/" TGTSPEC "${DEVICE_FAMILY}")
	if (NOT ("${TGTSPEC}" STREQUAL "${DEVICE_FAMILY}"))
		message("Target: ${TGTSPEC}")
		get_filename_component(GCC_PATH ${CMAKE_C_COMPILER} DIRECTORY)
		message("Toolchain path: ${GCC_PATH}")
		set($ENV{PATH} $ENV{PATH} ${GCC_PATH})
		execute_process(
			COMMAND ${CMAKE_COMMAND} -E env TARGETS=${TGTSPEC} PATH=${GCC_PATH}:$ENV{PATH} make -j all
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libopencm3
			)
		break()
	endif()
endforeach()

string(REPLACE " " ";" DEVICE_DEFS ${DEVICE_DEFS})

set(THUMB_DEVS 
	cortex-m0
	cortex-m0plus
	cortex-m3
	cortex-m4
	cortex-m7
	)

set(ARCH_FLAGS "")

add_definitions(${DEVICE_CPPFLAGS})
list(APPEND ARCH_FLAGS -mcpu=${DEVICE_CPU})

if ("${DEVICE_CPU}" IN_LIST THUMB_DEVS)
	list(APPEND ARCH_FLAGS -mthumb)
endif()

set(OPENCM3_LIBDIR
	${CMAKE_SOURCE_DIR}/libopencm3/lib
	)

set(OPENCM3_LIBNAME
	opencm3_${DEVICE_FAMILY}
	opencm3_${DEVICE_SUBFAMILY}
	)

foreach(CANDIDATE ${OPENCM3_LIBNAME})
	if (EXISTS ${OPENCM3_LIBDIR}/lib${CANDIDATE}.a)
		message(STATUS "Libopencm3 found: ${CANDIDATE}")
		set(LIBOPENCM3 ${CANDIDATE})
		break()
	endif()
endforeach()

if (NOT LIBOPENCM3)
	message(FATAL_ERROR "Library variant for the selected device does not exist!")
endif()


if ("${DEVICE_FPU}" STREQUAL "soft")
	list(APPEND ARCH_FLAGS -msoft-float)
elseif("${DEVICE_FPU}" STREQUAL "hard-fpv4-sp-d16")
	list(APPEND ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv4-sp-d16)
elseif("${DEVICE_FPU}" STREQUAL "hard-fpv5-sp-d16")
	list(APPEND ARCH_FLAGS -mfloat-abi=hard -mfpu=fpv5-sp-d16)
else()
	message(FATAL_ERROR "No match for the FPU flags")
endif()

if ("${DEVICE_FAMILY}" STREQUAL "")
	message(FATAL_ERROR "${DEVICE} not found in ${DATA_FILE}")
endif()

add_definitions(${ARCH_FLAGS})

link_directories(${CMAKE_SOURCE_DIR}/libopencm3/lib)
include_directories(${CMAKE_SOURCE_DIR}/libopencm3/include)

set(LDSCRIPT ${CMAKE_BINARY_DIR}/gen.${DEVICE}.ld)

execute_process(COMMAND ${CMAKE_C_COMPILER} ${ARCH_FLAGS} ${DEVICE_DEFS} -P -E ${CMAKE_SOURCE_DIR}/libopencm3/ld/linker.ld.S -o ${LDSCRIPT})
message(DEBUG ${CMAKE_C_COMPILER} ${ARCH_FLAGS} ${DEVICE_DEFS} -P -E ${CMAKE_SOURCE_DIR}/libopencm3/ld/linker.ld.S -o ${LDSCRIPT})

add_link_options(${ARCH_FLAGS})# -T${CMAKE_BINARY_DIR}/gen.${DEVICE}.ld)


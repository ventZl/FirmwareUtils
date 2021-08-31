# Copyright (C) 2021 Eduard Drusa
# SPDX-License-Identifier: MPL-2.0

## Add subproject being built using cross-compiler
# Usage:
# add_firmware(<firmware_name>
#          ARCH <arch_name>
#          TOOLCHAIN <toolchain_name>
#          [VARIANT <subproject_name>]
#          [HOST <host_system>]
#          )
#
# Call to this function will add subproject having it's own private
# definition of cross-compiling toolchain. This call will search for 
# toolchain file named `toolchain-<arch_name>-<toolchain_name>.cmake`
# in whole CMake module path in case there was no host system specified.
# In case of host system specification present, it will search for 
# toolchain file of name 
# `toolchain-<arch_name>-<host_system>-<toolchain_name>.cmake`.
# If you provide `VARIANT`, then subproject will be buildable using 
# `make <subproject_name>`. Otherwise it will be buildable using
# `make <firmware_name>`.
function(add_firmware NAME)
	message(STATUS "Adding subproject ${NAME}")
	cmake_parse_arguments(AF "OPTIONAL" "ARCH;TARGET;HOST;TOOLCHAIN;VARIANT" "" "${ARGN}")
	if ("${AF_ARCH}" STREQUAL "")
		message(FATAL_ERROR "Architecture specification is mandatory for firmware declaration!")
	endif()

	if ("${AF_TOOLCHAIN}" STREQUAL "")
		message(FATAL_ERROR "Toolchain specification is mandatory for firmware declaration!")
	endif()

	if ("${AF_VARIANT}" STREQUAL "")
		set(AF_VARIANT ${NAME})
	endif()

	if ("${AF_HOST}" STREQUAL "")
		set(TOOLCHAIN_SPEC toolchain-${AF_ARCH}-${AF_TOOLCHAIN})
	else()
		set(TOOLCHAIN_SPEC toolchain-${AF_ARCH}-${AF_HOST}-${AF_TOOLCHAIN})
	endif()

	find_file(TOOLCHAIN_FILE
		NAMES ${TOOLCHAIN_SPEC}.cmake
		PATHS ${CMAKE_MODULE_PATH}
		NO_DEFAULT_PATH
		NO_PACKAGE_ROOT_PATH
		NO_CMAKE_ENVIRONMENT_PATH
		NO_SYSTEM_ENVIRONMENT_PATH
		NO_CMAKE_SYSTEM_PATH
		NO_CMAKE_FIND_ROOT_PATH
		)

	if ("${TOOLCHAIN_FILE}" STREQUAL "TOOLCHAIN_FILE-NOTFOUND")
		message(FATAL_ERROR "Unable to find toolchain file for toolchain `${AF_TOOLCHAIN}` and architecture `${AF_ARCH}`!")
	endif()

	set (CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
	if (NOT TESTING)
		list(APPEND CMAKE_ARGS -DTOOLCHAIN_SPEC=${TOOLCHAIN_SPEC} -DTARGET_CPU=${AF_TARGET})
	else()
		list(APPEND CMAKE_ARGS -DTESTING=1)
	endif()

	foreach(GLOBAL ${FIRMWARE_GLOBALS})
		if (${${GLOBAL}})
			message(STATUS "${GLOBAL} set, forwarding into subproject")
			list(APPEND CMAKE_ARGS -D${GLOBAL}=${${GLOBAL}})
		endif()
	endforeach()


	file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME})

	execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS} -DSUBPROJECT=${AF_VARIANT} ${CMAKE_SOURCE_DIR}
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		)

	_finish_subproject(${NAME})
endfunction()

## Add subproject building native code
# Usage:
# add_native_code(<name>
#           [VARIANT <subproject_name>]
#           )
#
# This function simply adds a subproject being built using native toolchain.
# For sake of similarity, it accepts VARIANT option to change subproject name.
function(add_native_code NAME)
	file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME})
	cmake_parse_arguments(AF "OPTIONAL" "ARCH;TARGET;TOOLCHAIN;VARIANT" "" "${ARGN}")

	if (TESTING)
		list(APPEND CMAKE_ARGS -DTESTING=1)
	endif()

	if ("${AF_VARIANT}" STREQUAL "")
		set(AF_VARIANT ${NAME})
	endif()


	execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DSUBPROJECT=${AF_VARIANT} ${CMAKE_SOURCE_DIR}
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		)

	_finish_subproject(${NAME})
endfunction()

## Set target defined in subproject as being globally available
# Usage:
# add_group_target(<target_name>)
#
# This command will make existing target `<target_name>` available at top level using the same name.
# If this command is issued in multiple subprojects, then all subprojects' targets will be called from
# top level at once.
function(add_group_target TARGET)
	file(APPEND "${CMAKE_BINARY_DIR}/GroupTargets.cmake" "add_custom_target(${SUBPROJECT}-${TARGET} COMMAND \${CMAKE_MAKE_PROGRAM} ${TARGET} WORKING_DIRECTORY ${CMAKE_BINARY_DIR})\n")
	file(APPEND "${CMAKE_BINARY_DIR}/GroupTargets.cmake" "if (NOT TARGET ${TARGET})\n\tadd_custom_target(${TARGET})\nendif()\n\nadd_dependencies(${TARGET} ${SUBPROJECT}-${TARGET})\n")
endfunction()

file(WRITE "${CMAKE_BINARY_DIR}/GroupTargets.cmake" "")

function(_finish_subproject NAME)
	add_custom_target(${NAME} ALL
		COMMAND ${CMAKE_MAKE_PROGRAM} all
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		COMMENT "Building ${NAME}"
		)

	add_custom_target(${NAME}-clean
		COMMAND ${CMAKE_MAKE_PROGRAM} clean
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		COMMENT "Cleaning in ${NAME}"
		)

	if (NOT TARGET mrproper)
		add_custom_target(mrproper)
	endif()
	add_dependencies(mrproper ${NAME}-clean)

	include(${CMAKE_BINARY_DIR}/${NAME}/GroupTargets.cmake OPTIONAL)
endfunction()

## Add hook file to be ran when event is fired
# Usage:
# add_event_hook(<event_name>
#                <hook_file_name>
#               )
#
# If <event_name> is fired using run_event_hooks(), then
# file <hook_file_name> will be included. Inclusion happens inside
# a function. As of now the hook filename must be absolute path.
# Event name must form a valid CMAKE variable name.
function(add_event_hook EVNAME HOOKFILE)
	get_property(EVHOOKS GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNAME}_HOOKS)
	list(APPEND EVHOOKS ${HOOKFILE})
	set_property(GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNAME}_HOOKS "${EVHOOKS}")
endfunction()

## Runs registered event hooks
# Usage:
# run_event_hooks(<event_name>)
#
# Will run all scripts registered with event <event_name> same as if they
# were included manually at the place of function call. The only difference
# between direct inclusion and running events is that you can define, which
# scripts to run at different place. Note that you can run event multiple
# times resulting in multiple inclusions.
# As `run_event_hooks` is a function, scripts are actually included in function
# scope. If you want to set or update variable in outer context, you need to use
# PARENT_SCOPE option to set() command. You generally should avoid that as
# you can't really assume place where your handler was called, unless event
# is defined as some specific API of a module.
function(run_event_hooks EVNAME)
	get_property(EVHOOKS GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNAME}_HOOKS)
	foreach(HOOK ${EVHOOKS})
		include(${HOOK})
	endforeach()
endfunction()

if (NOT ("${SUBPROJECT}" STREQUAL "") AND NOT ("${TOOLCHAIN_SPEC}" STREQUAL ""))
	find_file(TOOLCHAIN_FILE
		NAMES ${TOOLCHAIN_SPEC}.cmake
		PATHS ${CMAKE_MODULE_PATH}
		NO_DEFAULT_PATH
		NO_PACKAGE_ROOT_PATH
		NO_CMAKE_ENVIRONMENT_PATH
		NO_SYSTEM_ENVIRONMENT_PATH
		NO_CMAKE_SYSTEM_PATH
		NO_CMAKE_FIND_ROOT_PATH
		)

	if ("${TOOLCHAIN_FILE}" STREQUAL "TOOLCHAIN_FILE-NOTFOUND")
		message(FATAL_ERROR "Unable to find toolchain file for toolchain `${AF_TOOLCHAIN}` and architecture `${AF_ARCH}`!")
	endif()

	set(CMAKE_TOOLCHAIN_FILE ${TOOLCHAIN_FILE})
endif()

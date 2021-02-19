function(add_firmware NAME)
	message(STATUS "Adding subproject ${NAME}")
	cmake_parse_arguments(AF "OPTIONAL" "ARCH;TARGET;TOOLCHAIN;VARIANT" "" "${ARGN}")
	if ("${AF_ARCH}" STREQUAL "")
		message(FATAL_ERROR "Architecture specification is mandatory for firmware declaration!")
	endif()

	if ("${AF_TOOLCHAIN}" STREQUAL "")
		message(FATAL_ERROR "Toolchain specification is mandatory for firmware declaration!")
	endif()

	if ("${AF_VARIANT}" STREQUAL "")
		set(AF_VARIANT ${NAME})
	endif()

	set(TOOLCHAIN_SPEC toolchain-${AF_ARCH}-${AF_TOOLCHAIN})

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


	file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME})

	execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS} -DSUBPROJECT=${AF_VARIANT} ${CMAKE_SOURCE_DIR}
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		)

	_finish_subproject(${NAME})
endfunction()


function(add_native_code NAME)
	file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME})
	cmake_parse_arguments(AF "OPTIONAL" "ARCH;TARGET;TOOLCHAIN;VARIANT" "" "${ARGN}")

	if ("${AF_VARIANT}" STREQUAL "")
		set(AF_VARIANT ${NAME})
	endif()


	execute_process(COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DSUBPROJECT=${AF_VARIANT} ${CMAKE_SOURCE_DIR}
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/${NAME}
		)

	_finish_subproject(${NAME})
endfunction()

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

function(add_event_hook EVNAME HOOKFILE)
	get_property(EVHOOKS GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNAME}_HOOKS)
	list(APPEND EVHOOKS ${HOOKFILE})
	set_property(GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNAME}_HOOKS "${EVHOOKS}")
endfunction()

function(run_event_hooks EVNAME)
	get_property(EVHOOKS GLOBAL PROPERTY TOOLCHAIN_UTILS_${EVNMAME}_HOOKS)
	foreach(HOOK EVHOOKS)
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

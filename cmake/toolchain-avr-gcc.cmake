# Copyright (C) 2021 Eduard Drusa
# SPDX-License-Identifier: MPL-2.0

SET(CMAKE_FIND_ROOT_PATH  /opt/avr /opt/avr/avr)

find_program(AVR_CC avr-gcc)
find_program(AVR_CXX avr-g++)
find_program(AVR_OBJCOPY avr-objcopy)
find_program(AVR_SIZE_TOOL avr-size)
find_program(AVR_AR avr-gcc-ar)
find_program(AVR_RANLIB avr-gcc-ranlib)

get_filename_component(AVR_PATH ${AVR_CC} DIRECTORY)

#find_file(LTO_PLUGIN 
#	NAMES liblto_plugin.so liblto_plugin.dll
#	PATHS 

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER   ${AVR_CC})
set(CMAKE_CXX_COMPILER ${AVR_CXX})
set(CMAKE_AR ${AVR_AR})
set(CMAKE_RANLIB ${AVR_RANLIB})
#set(CMAKE_LINKER ${AVR_CC})
set(CMAKE_EXECUTABLE_SUFFIX_C ".elf")

# XXX better use a seperate file for non toolchain stuff?
find_program(AVRDUDE avrdude)

if (NOT TARGET_CPU)
	set(TARGET_CPU atmega8)
endif()

add_definitions(-mmcu=${TARGET_CPU})
add_definitions(-Wall -fshort-enums -fpack-struct -fuse-linker-plugin)
link_directories(/opt/avr/avr/include)

set(CMAKE_EXE_LINKER_FLAGS "-Wall -flto -mmcu=${TARGET_CPU} -Wl,-Map=output.map") # --plugin=/opt/avr/libexec/gcc/avr/4.9.3/liblto_plugin.so")

set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> rcs <TARGET> <LINK_FLAGS> <OBJECTS>") # --plugin=/opt/avr/libexec/gcc/avr/4.9.3/liblto_plugin.so")
set(CMAKE_C_ARCHIVE_FINISH "")

set(
    AVR_DEFAULT_MCUS atmega8
    CACHE STRING
    "List of default target MCUs. See 'avr-gcc --target-help' for valid values."
)

function(_avr_get_mcu_list NAME OUTVAR)
    string(TOUPPER ${NAME} name_uc)
    set(mcu_type_var ${name_uc}_MCUS)
    set(
        ${mcu_type_var} ${AVR_DEFAULT_MCUS}
        CACHE STRING 
        "List of target MCUs. See 'avr-gcc --target-help' for valid values."
    )
    set(${OUTVAR} ${${mcu_type_var}} PARENT_SCOPE)
endfunction(_avr_get_mcu_list)

function(___add_executable EXECUTABLE_NAME)
	_add_executable(${EXECUTABLE_NAME} ${ARGN})
	set_target_properties(${EXECTABLE_NAME}
		PROPERTIES
		LINK_FLAGS "-Wl,-Map,${EXECUTABLE_NAME}.map"
		)
endfunction()

function(add_avr_executable EXECUTABLE_NAME)
    _avr_get_mcu_list(${EXECUTABLE_NAME} target_mcus)
    foreach(mcu ${target_mcus})
        set(elf_file ${EXECUTABLE_NAME}-${mcu}.elf)
        set(hex_file ${EXECUTABLE_NAME}-${mcu}.hex)
        set(map_file ${EXECUTABLE_NAME}-${mcu}.map)
        add_executable(${elf_file} EXCLUDE_FROM_ALL ${ARGN})
        set(common_opts "-mmcu=${mcu} -fshort-enums -fpack-struct")
        set_target_properties( 
            ${elf_file}
            PROPERTIES
                COMPILE_FLAGS "${common_opts}"
                LINK_FLAGS "${common_opts} -Wl,-Map,${map_file}"
        )

        add_custom_command(
            OUTPUT ${hex_file}
            COMMAND
                ${AVR_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}
            COMMAND
                ${AVR_SIZE_TOOL} ${elf_file}
            DEPENDS ${elf_file}
        )
        list(APPEND all_hex_files ${hex_file})
        list(APPEND all_map_files ${map_file})
    endforeach(mcu ${target_mcus})
    set(eeprom_image ${EXECUTABLE_NAME}-eeprom.hex)
    add_custom_command(
        OUTPUT ${eeprom_image}
        COMMAND
            ${AVR_OBJCOPY} -j .eeprom --change-section-lma .eeprom=0 
                -O ihex ${elf_file} ${eeprom_image}
        DEPENDS ${elf_file}
    )
    list(APPEND all_hex_files ${eeprom_image})
    add_custom_target(
        ${EXECUTABLE_NAME}
        ALL
        DEPENDS ${all_hex_files}
    )
    get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
    list(APPEND clean_files ${all_map_files})
    set_directory_properties(
        PROPERTIES
            ADDITIONAL_MAKE_CLEAN_FILES "${clean_files}"
    )

    string(TOUPPER ${EXECUTABLE_NAME} name_uc)
    list(GET target_mcus 0 default_upload_mcu)
    set(
        ${name_uc}_UPLOAD_MCU ${default_upload_mcu}
        CACHE STRING
        "The MCU this executable will be uploaded to."
    )
    set(upload_mcu ${${name_uc}_UPLOAD_MCU})
    set(upload_file ${EXECUTABLE_NAME}-${upload_mcu}.hex)
    add_custom_target(
        upload_${EXECUTABLE_NAME}
        ${AVRDUDE} -p ${upload_mcu} -c ${AVR_PROGRAMMER} ${AVRDUDE_OPTIONS}
            -U flash:w:${upload_file}
            -U eeprom:w:${eeprom_image}
            -P usb -b 115200 # XXX
        DEPENDS ${upload_file} ${eeprom_image}
        COMMENT "Uploading ${upload_file} to ${upload_mcu} using programmer ${AVR_PROGRAMMER}"
    )
    add_custom_target(
        disassemble_${EXECUTABLE_NAME}
        avr-objdump -h -S ${EXECUTABLE_NAME}-${upload_mcu}.elf > ${EXECUTABLE_NAME}.lst
        DEPENDS ${EXECUTABLE_NAME}-${upload_mcu}.elf
    )
endfunction(add_avr_executable)

function(add_avr_library LIBRARY_NAME)
    _avr_get_mcu_list(${LIBRARY_NAME} target_mcus)
    foreach(mcu ${target_mcus})
        set(lib_file ${LIBRARY_NAME}-${mcu})
        add_library(${lib_file} STATIC ${ARGN})
        set_target_properties( 
            ${lib_file}
            PROPERTIES
                COMPILE_FLAGS -mmcu=${mcu}
        )
    endforeach(mcu ${target_mcus})
endfunction(add_avr_library)


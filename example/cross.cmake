set(DEVICE "STM32L073RZT6")

include(LinkerConfig)

include_directories(${CMAKE_SOURCE_DIR}/libopencm3/include)

add_link_options(-Wl,-Map=helloworld.map --static -nostartfiles)
add_link_options(-Wl,--gc-sections)
add_definitions(-fno-common -fno-builtin-clz)

# Some toolchains apparently require this
#add_link_options(--specs=nosys.spec)

add_definitions(
	-fdata-sections
	-ffunction-sections
	)

set(CMAKE_C_FLAGS "--std=gnu99")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -g -Wall -Os -flto")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -ggdb3 -Wall")

add_subdirectory(src/cross)

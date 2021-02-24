include_directories(./libopencm3/include)

set(CMAKE_C_FLAGS "--std=gnu99")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -g -Wall -Os -flto")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -ggdb3 -Wall")

add_subdirectory(src/native)

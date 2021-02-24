set(cross_SRCS
	main.c
	)

message("OpenCM3: ${LIBOPENCM3}")

add_executable(cross ${cross_SRCS})
target_link_libraries(cross nosys ${LIBOPENCM3})

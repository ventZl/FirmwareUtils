set(native_SRCS
	main.c
	)

add_executable(native ${native_SRCS})
# no target_link_libraries as standard C library is linked out of the box with GCC

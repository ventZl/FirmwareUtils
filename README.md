FIRMWAREUTILS
=============

FirmwareUtils is a CMake module, which somewhat simplifies creation of
cross-compiled software. FirmwareUtils come in handy in case you need to build 
multiple sources targeting multiple different targets.

FirmwareUtils offers minimalistic facility to group multiple subprojects having
fundamentally different settings, which would normally require use of multiple
standalone CMakeLists.txt in order to keep things clean. Main goal is to get
*all* of the software getting built by single `make all`.

Features:

 * Almost no change to semantics of CMakeLists.txt
 * Ability to build only some of subprojects as if they were standalone
 * Automatic handling of CMake toolchain files
 * Support for hosted and unhosted targets
 * Support for inclusion of native builds (no cross-compiling)
 * Support for testing
 * Pass through of commandline arguments into subprojects

Typical use
-----------

In your top-level CMakeLists.txt, you can place following snipet of code:

~~~~~~~~~~~~~~~~~~~~
project(myprojectname LANGUAGES NONE)

if (NOT SUBPROJECT)
	add_firmware(main
		ARCH arm
		TOOLCHAIN gcc
		VARIANT embedded-main
		)

	add_firmware(sensor
		ARCH arm
		TOOLCHAIN gcc
		VARIANT embedded-sensor
		)

	add_firmware(console
		ARM arm
		TOOLCHAIN gcc
		HOST linux
		VARIANT hosted-console
		)
else()
	enable_language(C)
	enable_language(CXX)

	include(${SUBPROJECT}.cmake)
endif()
~~~~~~~~~~~~~~~~~~~~

What this snipet does is, that it defines three sub-projects `embedded-main`,
`embedded-sensor` and `hosted-console`. All three are potentially built using 
different toolchain and using different target settings. Main advantage, which
FirmwareUtils offer is, that CMake mechanism for toolchain detection works and
does not need to be bent. You can freely set options required by one subproject
without affecting others or breaking autodetection capabilities of CMake.

If you run CMake with above snipet of code in your CMakeLists.txt, then CMake
will create three subdirectories in your build directory named `embedded-main`,
`embedded-sensor` and `hosted-console`. It will then run CMake recursively in
each of them. While running, CMake will try to find toolchain files suitable for
`ARCH`, `TOOLCHAIN` and `HOST` combination given to `add_firmware` call. It if
finds one anywhere in module path, then it will pass it as
`CMAKE_TOOLCHAIN_FILE` automatically.

In each subproject, CMake file named after project is included, which contains
project-specific CMake directives. This is not mandatory as you can handle all
your variants in one CMake, if the nature of your projects allows that.

Now you can run `make all` and all of your subprojects will be built.

Support for testing
-------------------

FirmwareUtils does not come with any unit testing framework bundled, but
provides support for seamless testing integration. If you pass -DTESTING=1 to
your top-level CMake, then FirmwareUtils will:

 * pass this switch to all nested CMake invokations
 * not use toolchain files for subprojects

This means, that you can test for TESTING variable being set anywhere in your
CMakeLists.txt and add tests, such as:

~~~~~~~~~~~~~~~~~~
if (TESTING)
	set(test_something_SRCS test_main.c)
	add_executable(test_something ${test_something_SRCS})
	target_link_libraries(test_something lib_something)
	add_test(NAME something COMMAND test_something)
endif()
~~~~~~~~~~~~~~~~~~

This way, test driver will only ever be built if testing is activated and you
don't have to care about not including toolchain file. FirmwareUtils will
automatically omit it and you can run your test drivers on your build machine.

Group targets
-------------

It often happens that you want to run certain target on all/multiple of your 
projects. It is possible to define such targets using `add_group_target` command
provided by FirmwareUtils. Just use the following in your subprojects'
CMakeLists.txt:

~~~~~~~~~~~~~~~~~~
add_custom_target(something
	COMMAND echo Hello world
	)
add_group_target(something)
~~~~~~~~~~~~~~~~~~

And you can run `make something` at the top-level of your project. It will
automatically invoke `make something` in every subproject, which created target
`something` and declared it a group target.

Event hooks and event firing
----------------------------

While not directly bound to cross-compiling, this useful feature is missing from
CMake and was found to be useful during multiple-target builds. So it is
included in FirmwareUtils as well.

You can call following command to declare a hook being fired on certain event:

~~~~~~~~~~~~~~~~~~
add_event_hook(SOME_EVENT ${CMAKE_SOURCE_DIR}/cmake/on-some-event.cmake)

~~~~~~~~~~~~~~~~~~

It will register file `on-some-event.cmake` sitting in your source tree to be
called upon `SOME_EVENT` firing. You can fire SOME_EVENT using following call:

~~~~~~~~~~~~~~~~~~
run_event_hooks(SOME_EVENT)
~~~~~~~~~~~~~~~~~~

This will call all event hooks registered for this event up to this point in
order in which they were registered.


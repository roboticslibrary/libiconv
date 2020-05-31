include(FindPackageHandleStandardArgs)

find_program(MAN2HTML_EXECUTABLE man2html)

mark_as_advanced(MAN2HTML_EXECUTABLE)

find_package_handle_standard_args(
	Man2html
	DEFAULT_MSG
	MAN2HTML_EXECUTABLE
)

if(MAN2HTML_EXECUTABLE AND NOT TARGET Man2html::Man2html)
	add_executable(Man2html::Man2html IMPORTED GLOBAL)
	set_target_properties(Man2html::Man2html PROPERTIES IMPORTED_LOCATION "${MAN2HTML_EXECUTABLE}")
endif()

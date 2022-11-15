include(FindPackageHandleStandardArgs)

find_program(GPERF_EXECUTABLE gperf)

mark_as_advanced(GPERF_EXECUTABLE)

find_package_handle_standard_args(
	Gperf
	DEFAULT_MSG
	GPERF_EXECUTABLE
)

if(GPERF_EXECUTABLE AND NOT TARGET gperf::gperf)
	add_executable(gperf::gperf IMPORTED)
	set_target_properties(gperf::gperf PROPERTIES IMPORTED_LOCATION "${GPERF_EXECUTABLE}")
endif()

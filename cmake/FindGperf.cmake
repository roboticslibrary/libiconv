include(FindPackageHandleStandardArgs)

find_program(GPERF_EXECUTABLE gperf)

mark_as_advanced(GPERF_EXECUTABLE)

find_package_handle_standard_args(
	Gperf
	DEFAULT_MSG
	GPERF_EXECUTABLE
)

if(GPERF_EXECUTABLE AND NOT TARGET Gperf::Gperf)
	add_executable(Gperf::Gperf IMPORTED GLOBAL)
	set_target_properties(Gperf::Gperf PROPERTIES IMPORTED_LOCATION "${GPERF_EXECUTABLE}")
endif()

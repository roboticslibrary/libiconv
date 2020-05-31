cmake_minimum_required(VERSION 2.8.11)

project(libiconv)

include(CheckCCompilerFlag)
include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckSymbolExists)
include(CheckTypeSize)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
include(TestBigEndian)


set(VERSION_MAJOR 1)
set(VERSION_MINOR 15)
set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR})

option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(LIBICONV_ENABLE_EXTRA "Enable a few rarely used encodings" OFF)
option(LIBICONV_ENABLE_NLS "Translate program messages to user's native language" OFF)
option(LIBICONV_ENABLE_RELOCATABLE "Install a package that can be moved in the file system" ON)

check_symbol_exists(EILSEQ "errno.h" HAVE_EILSEQ)
if(NOT HAVE_EILSEQ)
	set(EILSEQ "ENOENT")
endif()
set(ENABLE_EXTRA ${LIBICONV_ENABLE_EXTRA})
set(ENABLE_NLS ${LIBICONV_ENABLE_NLS})
set(ENABLE_RELOCATABLE ${LIBICONV_ENABLE_RELOCATABLE})
check_function_exists(iconv HAVE_ICONV)
check_c_source_compiles("
	#include <langinfo.h>
	int main() { char* cs = nl_langinfo(CODESET); return !cs; }
" HAVE_LANGINFO_CODESET)
check_function_exists(mbrtowc HAVE_MBRTOWC)
check_function_exists(mbsinit HAVE_MBSINIT)
check_c_compiler_flag("-fvisibility=hidden -Werror" HAVE_VISIBILITY)
check_type_size(wchar_t WCHAR_T)
check_function_exists(wcrtomb HAVE_WCRTOMB)
check_c_source_compiles("
	#include <stdlib.h>
	#include <iconv.h>
	extern
	#ifdef __cplusplus
	\"C\"
	#endif
	#if defined(__STDC__) || defined(__cplusplus)
	size_t iconv(iconv_t cd, char** inbuf, size_t* inbytesleft, char** outbuf, size_t* outbytesleft);
	#else
	size_t iconv();
	#endif
	int main() { return 0; }
" ICONV_CONST_TEST)
if(NOT ICONV_CONST_TEST)
	set(ICONV_CONST "const")
endif()
set(INSTALLPREFIX ${CMAKE_INSTALL_PREFIX})
test_big_endian(WORDS_BIGENDIAN)
if(WORDS_BIGENDIAN)
	set(WORDS_LITTLEENDIAN OFF)
else()
	set(WORDS_LITTLEENDIAN ON)
endif()
check_type_size("size_t" SIZE_T)
if(NOT HAVE_SIZE_T)
	set(size_t "unsigned int")
endif()


configure_file(libcharset/config.h.cmake.in libcharset/config.h @ONLY)


configure_file(config.h.cmake.in config.h @ONLY)

if(HAVE_MBSTATE_T)
	set(USE_MBSTATE_T 1)
else()
	set(USE_MBSTATE_T 0)
endif()

if(HAVE_VISIBILTY)
	list(APPEND CMAKE_C_FLAGS "-fvisibility=hidden")
	list(APPEND CMAKE_CXX_FLAGS "-fvisibility=hidden")
	set(HAVE_VISIBILITY 1)
else()
	set(HAVE_VISIBILITY 0)
endif()

if(HAVE_WCHAR_T)
	set(BROKEN_WCHAR_H 0)
	set(HAVE_WCHAR_T 1)
else()
	set(BROKEN_WCHAR_H 1)
	set(HAVE_WCHAR_T 0)
endif()


configure_file(include/iconv.h.build.in include/iconv.h @ONLY)
configure_file(libcharset/include/localcharset.h.build.in include/localcharset.h @ONLY)

if(BUILD_SHARED_LIBS AND MSVC)
	set(DLL_VARIABLE "__declspec (dllimport)")
endif()

configure_file(include/iconv.h.in include/iconv.h.inst @ONLY)
configure_file(libcharset/include/libcharset.h.in include/libcharset.h @ONLY)

add_library(
	Charset
	libcharset/lib/localcharset.c
	libcharset/lib/relocatable-stub.c
)

target_compile_definitions(
	Charset
	PRIVATE
	BUILDING_LIBCHARSET
	HAVE_CONFIG_H
	IN_LIBRARY
	INSTALLDIR="${CMAKE_INSTALL_LIBDIR}"
	LIBDIR="${CMAKE_INSTALL_LIBDIR}"
	NO_XMALLOC
	relocate=libcharset_relocate
	set_relocation_prefix=libcharset_set_relocation_prefix
)

if(BUILD_SHARED_LIBS)
	target_compile_definitions(Charset PRIVATE _DLL BUILDING_DLL)
endif()

if(LIBICONV_ENABLE_EXTRA)
	target_compile_definitions(Charset PRIVATE ENABLE_EXTRA=1)
else()
	target_compile_definitions(Charset PRIVATE ENABLE_EXTRA=0)
endif()

if(LIBICONV_ENABLE_NLS)
	target_compile_definitions(Charset PRIVATE ENABLE_NLS=1)
else()
	target_compile_definitions(Charset PRIVATE ENABLE_NLS=0)
endif()

if(LIBICONV_ENABLE_RELOCATABLE)
	target_compile_definitions(Charset PRIVATE ENABLE_RELOCATABLE=1)
else()
	target_compile_definitions(Charset PRIVATE ENABLE_RELOCATABLE=0)
endif()

target_include_directories(
	Charset
	PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
	$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(
	Charset
	PROPERTIES
	IMPORT_PREFIX lib
	OUTPUT_NAME charset
	POSITION_INDEPENDENT_CODE ON
	PREFIX lib
	VERSION ${VERSION}
)

if(WIN32)
	if(BUILD_SHARED_LIBS)
		set_target_properties(
			Charset
			PROPERTIES
			DEBUG_POSTFIX d
		)
	else()
		set_target_properties(
			Charset
			PROPERTIES
			DEBUG_POSTFIX sd
			MINSIZEREL_POSTFIX s
			RELEASE_POSTFIX s
			RELWITHDEBINFO_POSTFIX s
		)
	endif()
endif()

add_library(
	Iconv
	lib/iconv.c
	lib/relocatable.c
	libcharset/lib/localcharset.c
)

target_compile_definitions(
	Iconv
	PRIVATE
	BUILDING_LIBICONV
	HAVE_CONFIG_H
	IN_LIBRARY
	INSTALLDIR="${CMAKE_INSTALL_LIBDIR}"
	LIBDIR="${CMAKE_INSTALL_LIBDIR}"
	NO_XMALLOC
	relocate=libiconv_relocate
	set_relocation_prefix=libiconv_set_relocation_prefix
)

if(BUILD_SHARED_LIBS)
	target_compile_definitions(Iconv PRIVATE _DLL BUILDING_DLL)
endif()

if(LIBICONV_ENABLE_EXTRA)
	target_compile_definitions(Iconv PRIVATE ENABLE_EXTRA=1)
else()
	target_compile_definitions(Iconv PRIVATE ENABLE_EXTRA=0)
endif()

if(LIBICONV_ENABLE_NLS)
	target_compile_definitions(Iconv PRIVATE ENABLE_NLS=1)
else()
	target_compile_definitions(Iconv PRIVATE ENABLE_NLS=0)
endif()

if(LIBICONV_ENABLE_RELOCATABLE)
	target_compile_definitions(Iconv PRIVATE ENABLE_RELOCATABLE=1)
else()
	target_compile_definitions(Iconv PRIVATE ENABLE_RELOCATABLE=0)
endif()

target_include_directories(
	Iconv
	PUBLIC
	$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
	$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(Iconv Charset)

set_target_properties(
	Iconv
	PROPERTIES
	IMPORT_PREFIX lib
	OUTPUT_NAME iconv
	POSITION_INDEPENDENT_CODE ON
	PREFIX lib
	VERSION ${VERSION}
)

if(WIN32)
	if(BUILD_SHARED_LIBS)
		set_target_properties(
			Iconv
			PROPERTIES
			DEBUG_POSTFIX d
		)
	else()
		set_target_properties(
			Iconv
			PROPERTIES
			DEBUG_POSTFIX sd
			MINSIZEREL_POSTFIX s
			RELEASE_POSTFIX s
			RELWITHDEBINFO_POSTFIX s
		)
	endif()
endif()

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/iconv.h.inst DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} RENAME iconv.h COMPONENT development)

install(
	TARGETS Charset Iconv
	EXPORT Iconv
	ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT development
	LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT runtime NAMELINK_SKIP
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT runtime
)

if(BUILD_SHARED_LIBS)
	install(
		TARGETS Charset Iconv
		EXPORT Iconv
		LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT development NAMELINK_ONLY
	)
endif()

if(MSVC AND BUILD_SHARED_LIBS AND NOT CMAKE_VERSION VERSION_LESS 3.1)
	install(FILES $<TARGET_PDB_FILE:Charset> DESTINATION ${CMAKE_INSTALL_BINDIR} CONFIGURATIONS Debug RelWithDebInfo COMPONENT debug)
	install(FILES $<TARGET_PDB_FILE:Iconv> DESTINATION ${CMAKE_INSTALL_BINDIR} CONFIGURATIONS Debug RelWithDebInfo COMPONENT debug)
endif()

install(FILES man/iconv.1 DESTINATION ${CMAKE_INSTALL_MANDIR}/man1 COMPONENT documentation)
install(FILES man/iconv.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3 COMPONENT documentation)
install(FILES man/iconv_close.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3 COMPONENT documentation)
install(FILES man/iconv_open.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3 COMPONENT documentation)
install(FILES man/iconv_open_into.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3 COMPONENT documentation)
install(FILES man/iconvctl.3 DESTINATION ${CMAKE_INSTALL_MANDIR}/man3 COMPONENT documentation)

install(FILES man/iconv.1.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)
install(FILES man/iconv.3.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)
install(FILES man/iconv_close.3.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)
install(FILES man/iconv_open.3.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)
install(FILES man/iconv_open_into.3.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)
install(FILES man/iconvctl.3.html DESTINATION ${CMAKE_INSTALL_DATADIR}/doc/libiconv COMPONENT documentation)

configure_package_config_file(
	iconv-config.cmake.in iconv-config.cmake
	INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/iconv-${VERSION}
)

install(
	FILES ${CMAKE_CURRENT_BINARY_DIR}/iconv-config.cmake
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/iconv-${VERSION}
)

write_basic_package_version_file(
	${CMAKE_CURRENT_BINARY_DIR}/iconv-config-version.cmake
	VERSION ${VERSION}
	COMPATIBILITY ExactVersion
)

install(
	FILES ${CMAKE_CURRENT_BINARY_DIR}/iconv-config-version.cmake
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/iconv-${VERSION}
	COMPONENT development
)

install(
	EXPORT Iconv
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/iconv-${VERSION}
	NAMESPACE Iconv::
	FILE iconv-export.cmake
	COMPONENT development
)

set(CPACK_COMPONENT_DEVELOPMENT_DEPENDS runtime)
set(CPACK_DEB_COMPONENT_INSTALL ON)
set(CPACK_DEBIAN_DEVELOPMENT_PACKAGE_DEPENDS "${PACKAGE_TARNAME}")
set(CPACK_DEBIAN_DEVELOPMENT_PACKAGE_NAME "libiconv-dev")
set(CPACK_DEBIAN_DEVELOPMENT_PACKAGE_SECTION "libdevel")
set(CPACK_DEBIAN_DOCUMENTATION_PACKAGE_NAME "libiconv-doc")
set(CPACK_DEBIAN_DOCUMENTATION_PACKAGE_SECTION "doc")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE ${PACKAGE_URL})
set(CPACK_DEBIAN_PACKAGE_NAME ${PACKAGE_TARNAME})
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
#set(CPACK_DEBIAN_PROGRAMS_PACKAGE_DEPENDS "${PACKAGE_TARNAME}")
#set(CPACK_DEBIAN_PROGRAMS_PACKAGE_NAME "${PACKAGE_TARNAME}-utils")
#set(CPACK_DEBIAN_PROGRAMS_PACKAGE_SECTION "utils")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_NAME "${PACKAGE_TARNAME}")
#set(CPACK_DEBIAN_RUNTIME_PACKAGE_RECOMMENDS "${PACKAGE_TARNAME}-programs")
set(CPACK_DEBIAN_RUNTIME_PACKAGE_SECTION "libs")
set(CPACK_NSIS_PACKAGE_NAME ${PACKAGE_STRING})
set(CPACK_NSIS_URL_INFO_ABOUT ${PACKAGE_URL})
set(CPACK_PACKAGE_CONTACT ${PACKAGE_BUGREPORT})
set(CPACK_PACKAGE_DISPLAY_NAME ${PACKAGE_STRING})
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${PACKAGE_TARNAME}-${PACKAGE_VERSION}")
set(CPACK_PACKAGE_NAME ${PACKAGE_TARNAME})
set(CPACK_PACKAGE_VERSION ${PACKAGE_VERSION})
set(CPACK_PACKAGE_VERSION_MAJOR ${VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${VERSION_MINOR})
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/COPYING)
set(CPACK_RPM_COMPONENT_INSTALL ON)
set(CPACK_RPM_development_PACKAGE_NAME "${PACKAGE_TARNAME}-devel")
set(CPACK_RPM_development_PACKAGE_REQUIRES "${PACKAGE_TARNAME}")
set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
set(CPACK_RPM_PACKAGE_LICENSE "GPL")
set(CPACK_RPM_PACKAGE_NAME ${PACKAGE_TARNAME})
set(CPACK_RPM_PACKAGE_URL ${PACKAGE_URL})
set(CPACK_RPM_programs_PACKAGE_NAME "${PACKAGE_NAME}-utils")
set(CPACK_RPM_programs_PACKAGE_REQUIRES "${PACKAGE_NAME}")
#set(CPACK_RPM_runtime_PACKAGE_SUGGESTS "${PACKAGE_NAME}-utils")

if(WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
endif()

include(CPack)

############################################################################
# CMakeLists.txt
# Copyright (C) 2014  Belledonne Communications, Grenoble France
#
############################################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
############################################################################

cmake_minimum_required(VERSION 2.8.12)
project(PYLINPHONE C) # Dummy project

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(PLATFORM_ARCH_NAME "x86_64")
else()
	set(PLATFORM_ARCH_NAME "i386")
endif()

find_package(PythonInterp REQUIRED)
find_package(PythonLibs 2.7 REQUIRED)
find_package(Git)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_PREFIX_PATH}/share/cmake/Modules)
find_package(Linphone REQUIRED)

set(LINPHONE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/../EP_linphone")

if(GIT_EXECUTABLE)
	execute_process(
		COMMAND ${GIT_EXECUTABLE} describe --always
		OUTPUT_VARIABLE LINPHONE_GIT_REVISION
		OUTPUT_STRIP_TRAILING_WHITESPACE
		WORKING_DIRECTORY ${LINPHONE_SOURCE_DIR}
	)
else()
	set(LINPHONE_GIT_REVISION "0.0.0")
endif()
STRING(REGEX REPLACE "([0-9.]+)-?.*" "\\1" LINPHONE_VERSION "${LINPHONE_GIT_REVISION}")

execute_process(
	COMMAND ${CMAKE_COMMAND} -E echo "#define LINPHONE_GIT_REVISION \"${LINPHONE_GIT_REVISION}\""
	OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/gitversion.h
)

# Find the doxygen XML directory
file(GLOB XML_DIR "${CMAKE_INSTALL_PREFIX}/share/doc/linphone-*/xml")

# Generate the API in XML format from the doxygen XML files
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/api.xml"
	COMMAND ${PYTHON_EXECUTABLE} "${LINPHONE_SOURCE_DIR}/tools/genapixml.py" "--pretty" "--outputfile" "${CMAKE_CURRENT_BINARY_DIR}/api.xml" "${XML_DIR}"
	DEPENDS ${XML_FILES} "${LINPHONE_SOURCE_DIR}/tools/genapixml.py"
)
add_custom_target(api_xml DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/api.xml")

# Generate the Python wrapper source code for the API in XML format
set(SOURCE_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/linphone.c")
add_custom_command(OUTPUT "${SOURCE_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${LINPHONE_SOURCE_DIR}/tools/python/apixml2python.py" "--outputfile" "${SOURCE_FILENAME}" "${CMAKE_CURRENT_BINARY_DIR}/api.xml"
	DEPENDS api_xml "${LINPHONE_SOURCE_DIR}/tools/python/apixml2python.py" "${LINPHONE_SOURCE_DIR}/tools/python/apixml2python/linphone.py"
	WORKING_DIRECTORY "${LINPHONE_SOURCE_DIR}/tools/python"
)
add_custom_target(pylinphone_source DEPENDS "${SOURCE_FILENAME}")

if(WIN32)
	set(PACKAGES_TO_BUILD "exe" "msi" "zip" "wheel")
	set(PY_MODULE_EXT ".pyd")
	file(GLOB LINPHONE_DYNAMIC_LIBRARIES_TO_INSTALL "${CMAKE_INSTALL_PREFIX}/bin/*.dll")
else()
	set(PACKAGES_TO_BUILD "zip" "wheel")
	set(PY_MODULE_EXT ".so")
	if(APPLE)
		set(LINPHONE_DYNAMIC_LIBRARIES_TO_INSTALL
			"${CMAKE_INSTALL_PREFIX}/lib/libavcodec.53.61.100.dylib"
			"${CMAKE_INSTALL_PREFIX}/lib/libavutil.51.35.100.dylib"
			"${CMAKE_INSTALL_PREFIX}/lib/libswscale.2.1.100.dylib"
		)
	else()
		set(LINPHONE_DYNAMIC_LIBRARIES_TO_INSTALL
			"${CMAKE_INSTALL_PREFIX}/lib/libavcodec.so.53.61.100"
			"${CMAKE_INSTALL_PREFIX}/lib/libavutil.so.51.35.100"
			"${CMAKE_INSTALL_PREFIX}/lib/libswscale.so.2.1.100"
		)
	endif()
endif()

if(UNIX)
	find_program(LORDER_EXECUTABLE lorder)
	if(NOT LORDER_EXECUTABLE)
		message(FATAL_ERROR "lorder executable is needed.")
	endif()
	find_program(TSORT_EXECUTABLE tsort)
	if(NOT TSORT_EXECUTABLE)
		message(FATAL_ERROR "tsort executable is needed.")
	endif()
	execute_process(COMMAND ${LORDER_EXECUTABLE} ${LINPHONE_LIBRARIES} OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/lorder.out")
	execute_process(COMMAND ${TSORT_EXECUTABLE} OUTPUT_VARIABLE LINPHONE_LIBRARIES INPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/lorder.out")
	separate_arguments(LINPHONE_LIBRARIES UNIX_COMMAND "${LINPHONE_LIBRARIES}")
endif()

add_library(pylinphone MODULE "${SOURCE_FILENAME}")
target_compile_options(pylinphone PUBLIC ${LINPHONE_CPPFLAGS})
target_include_directories(pylinphone PUBLIC ${LINPHONE_INCLUDE_DIRS} ${PYTHON_INCLUDE_DIRS} PRIVATE "${LINPHONE_SOURCE_DIR}/coreapi" "${LINPHONE_SOURCE_DIR}/include")
set(PYLINPHONE_LINK_LIBRARIES ${LINPHONE_LIBRARIES})
if(WIN32)
	find_library(GCC_LIBRARIES gcc)
	find_library(MINGWEX_LIBRARIES mingwex)
	list(APPEND PYLINPHONE_LINK_LIBRARIES ${PYTHON_LIBRARIES} ${GCC_LIBRARIES} ${MINGWEX_LIBRARIES})
endif()
target_link_libraries(pylinphone ${PYLINPHONE_LINK_LIBRARIES})
string(REPLACE ";" " " LINPHONE_LDFLAGS_STR "${LINPHONE_LDFLAGS}")
set(PYLINPHONE_LDFLAGS "")
if(APPLE)
	set(PYLINPHONE_LDFLAGS "${LINPHONE_LDFLAGS_STR} -undefined dynamic_lookup")
endif()
if(NOT "${PYLINPHONE_LDFLAGS}" STREQUAL "")
	set_target_properties(pylinphone PROPERTIES LINK_FLAGS "${PYLINPHONE_LDFLAGS}")
endif()
set_target_properties(pylinphone PROPERTIES OUTPUT_NAME linphone PREFIX "" SUFFIX "${PY_MODULE_EXT}")
if(UNIX)
	if(APPLE)
		set_target_properties(pylinphone PROPERTIES INSTALL_NAME_DIR "@executable_path")
	else()
		set_target_properties(pylinphone PROPERTIES INSTALL_RPATH "$ORIGIN" BUILD_WITH_INSTALL_RPATH TRUE)
	endif()
endif()
foreach(PACKAGE_TO_BUILD ${PACKAGES_TO_BUILD})
	add_custom_command(TARGET pylinphone POST_BUILD
		COMMAND "${CMAKE_COMMAND}" "-DLINPHONE_VERSION=${LINPHONE_VERSION}" "-DLINPHONE_GIT_REVISION=${LINPHONE_GIT_REVISION}"
			"-DLINPHONE_PYTHON_MODULE=$<TARGET_FILE:pylinphone>" "-DLINPHONE_RESOURCES_PREFIX=${CMAKE_INSTALL_PREFIX}"
			"-DLINPHONE_DYNAMIC_LIBRARIES_TO_INSTALL=\"${LINPHONE_DYNAMIC_LIBRARIES_TO_INSTALL}\"" "-DPACKAGE_TYPE=${PACKAGE_TO_BUILD}"
			"-DINPUT_DIR=${CMAKE_CURRENT_SOURCE_DIR}" "-DOUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}" "-DLINPHONE_SOURCE_DIR=${LINPHONE_SOURCE_DIR}"
			"-P" "${CMAKE_CURRENT_SOURCE_DIR}/prepare_packaging.cmake"
	)
	if(APPLE)
		add_custom_command(TARGET pylinphone POST_BUILD
			COMMAND "${PYTHON_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/mac_rpath.py" "${CMAKE_CURRENT_BINARY_DIR}/build_${PACKAGE_TO_BUILD}/linphone/linphone"
		)
	endif()
endforeach()

if(WIN32)

# Generate the installer
set(EXE_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_exe/linphone/dist/linphone-${LINPHONE_GIT_REVISION}.win32.exe")
add_custom_command(OUTPUT "${EXE_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_exe/linphone/setup.py" "bdist_wininst"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_exe/linphone"
)
add_custom_target(pylinphone_exe ALL DEPENDS "${EXE_FILENAME}")
install(FILES ${EXE_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_GIT_REVISION}.win32-py${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.exe")

# Generate the msi
set(MSI_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_msi/linphone/dist/linphone-${LINPHONE_VERSION}.win32.msi")
add_custom_command(OUTPUT "${MSI_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_msi/linphone/setup.py" "bdist_msi"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_msi/linphone"
)
add_custom_target(pylinphone_msi ALL DEPENDS "${MSI_FILENAME}")
install(FILES ${MSI_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_GIT_REVISION}.win32-py${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.msi")

# Generate the zip
set(ZIP_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone/dist/linphone-${LINPHONE_GIT_REVISION}.win32.zip")
add_custom_command(OUTPUT "${ZIP_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone/setup.py" "bdist" "--format=zip"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone"
)
add_custom_target(pylinphone_zip ALL DEPENDS "${ZIP_FILENAME}")
install(FILES ${ZIP_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_GIT_REVISION}.win32-py${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.zip")

# Generate the wheel package
string(REPLACE "-" "_" LINPHONE_UNDERSCORE_GIT_REVISION ${LINPHONE_GIT_REVISION})
set(WHEEL_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone/dist/linphone-${LINPHONE_UNDERSCORE_GIT_REVISION}-py2-none-any.whl")
add_custom_command(OUTPUT "${WHEEL_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone/setup.py" "bdist_wheel"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone"
)
add_custom_target(pylinphone_wheel ALL DEPENDS "${WHEEL_FILENAME}")
install(FILES ${WHEEL_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_UNDERSCORE_GIT_REVISION}-cp27-none-win32.whl")

endif()

if(UNIX)

if(APPLE)
	set(PLATFORM_OS "macosx-10.5")
else()
	set(PLATFORM_OS "linux")
endif()
string(REPLACE "-" "_" UNDERSCORE_PLATFORM_OS ${PLATFORM_OS})
string(REPLACE "." "_" UNDERSCORE_PLATFORM_OS ${UNDERSCORE_PLATFORM_OS})

# Generate the zip
set(ZIP_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone/dist/linphone-${LINPHONE_GIT_REVISION}.${PLATFORM_OS}-${PLATFORM_ARCH_NAME}.zip")
add_custom_command(OUTPUT "${ZIP_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone/setup.py" "bdist" "--format=zip"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_zip/linphone"
)
add_custom_target(pylinphone_zip ALL DEPENDS "${ZIP_FILENAME}")
install(FILES ${ZIP_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_GIT_REVISION}.${PLATFORM_OS}-${PLATFORM_ARCH_NAME}-py${PYTHON_VERSION_MAJOR}.${PYTHON_VERSION_MINOR}.zip")

# Generate the wheel package
string(REPLACE "-" "_" LINPHONE_UNDERSCORE_GIT_REVISION ${LINPHONE_GIT_REVISION})
set(WHEEL_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone/dist/linphone-${LINPHONE_UNDERSCORE_GIT_REVISION}-py2-none-any.whl")
add_custom_command(OUTPUT "${WHEEL_FILENAME}"
	COMMAND ${PYTHON_EXECUTABLE} "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone/setup.py" "bdist_wheel"
	DEPENDS pylinphone
	WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build_wheel/linphone"
)
add_custom_target(pylinphone_wheel ALL DEPENDS "${WHEEL_FILENAME}")
install(FILES ${WHEEL_FILENAME} DESTINATION "." RENAME "linphone-${LINPHONE_UNDERSCORE_GIT_REVISION}-cp27-none-${UNDERSCORE_PLATFORM_OS}_${PLATFORM_ARCH_NAME}.whl")

endif()

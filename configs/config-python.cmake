############################################################################
# config-python.cmake
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

# Define default values for the linphone builder options
set(DEFAULT_VALUE_ENABLE_VIDEO ON)
set(DEFAULT_VALUE_ENABLE_GPL_THIRD_PARTIES ON)
set(DEFAULT_VALUE_ENABLE_FFMPEG ON)
set(DEFAULT_VALUE_ENABLE_ZRTP ON)
set(DEFAULT_VALUE_ENABLE_SRTP ON)
set(DEFAULT_VALUE_ENABLE_AMRNB OFF)
set(DEFAULT_VALUE_ENABLE_AMRWB OFF)
set(DEFAULT_VALUE_ENABLE_G729 OFF)
set(DEFAULT_VALUE_ENABLE_GSM ON)
set(DEFAULT_VALUE_ENABLE_ILBC OFF)
set(DEFAULT_VALUE_ENABLE_ISAC OFF)
set(DEFAULT_VALUE_ENABLE_OPUS ON)
set(DEFAULT_VALUE_ENABLE_SILK OFF)
set(DEFAULT_VALUE_ENABLE_SPEEX ON)
set(DEFAULT_VALUE_ENABLE_WEBRTC_AEC OFF)
set(DEFAULT_VALUE_ENABLE_H263 OFF)
set(DEFAULT_VALUE_ENABLE_H263P OFF)
set(DEFAULT_VALUE_ENABLE_MPEG4 OFF)
set(DEFAULT_VALUE_ENABLE_OPENH264 OFF)
set(DEFAULT_VALUE_ENABLE_VPX ON)
set(DEFAULT_VALUE_ENABLE_X264 OFF)
set(DEFAULT_VALUE_ENABLE_TUNNEL OFF)
set(DEFAULT_VALUE_ENABLE_UNIT_TESTS OFF)


find_package(Doxygen REQUIRED)


# Global configuration
set(LINPHONE_BUILDER_PKG_CONFIG_LIBDIR ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig)	# Restrict pkg-config to search in the install directory

if (UNIX)
	if(APPLE)
		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			set(CMAKE_OSX_ARCHITECTURES "x86_64")
		else()
			set(CMAKE_OSX_ARCHITECTURES "i386")
		endif()
		set(CMAKE_OSX_DEPLOYMENT_TARGET "10.6")
		set(LINPHONE_BUILDER_CPPFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
		set(LINPHONE_BUILDER_OBJCFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
		set(LINPHONE_BUILDER_LDFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET} -arch ${CMAKE_OSX_ARCHITECTURES}")
	else()
		set(BUILD_V4L "yes")
		set(LINPHONE_BUILDER_LDFLAGS "-Wl,-Bsymbolic -fPIC")
	endif()
endif()
if(WIN32)
	set(LINPHONE_BUILDER_CPPFLAGS "-D_WIN32_WINNT=0x0501 -D_ALLOW_KEYWORD_MACROS")
endif()


# Include builders
include(builders/CMakeLists.txt)


# antlr3c
set(EP_antlr3c_LINKING_TYPE "-DENABLE_STATIC=YES")

# bellesip
set(EP_bellesip_LINKING_TYPE "-DENABLE_STATIC=YES")

# bzrtp
set(EP_bzrtp_LINKING_TYPE "-DENABLE_STATIC=YES")

# cunit
set(EP_cunit_LINKING_TYPE "-DENABLE_STATIC=YES")

# ffmpeg
set(EP_ffmpeg_LINKING_TYPE "--disable-static" "--enable-shared")

# gsm
set(EP_gsm_LINKING_TYPE "-DENABLE_STATIC=YES")

# linphone
set(EP_linphone_LINKING_TYPE "-DENABLE_STATIC=YES")
list(APPEND EP_linphone_CMAKE_OPTIONS "-DENABLE_RELATIVE_PREFIX=YES")

# ms2
set(EP_ms2_LINKING_TYPE "-DENABLE_STATIC=YES")
list(APPEND EP_ms2_CMAKE_OPTIONS "-DENABLE_RELATIVE_PREFIX=YES")
if(UNIX AND NOT APPLE)
	list(APPEND EP_ms2_CMAKE_OPTIONS "-DENABLE_ALSA=YES" "-DENABLE_PULSEAUDIO=NO" "-DENABLE_OSS=NO" "-DENABLE_GLX=NO" "-DENABLE_X11=YES" "-DENABLE_XV=YES")
endif()

# opus
if(NOT MSVC)
	# TODO: Also build statically on windows
	set(EP_opus_LINKING_TYPE "--enable-static" "--disable-shared" "--with-pic")
endif()

# ortp
set(EP_ortp_LINKING_TYPE "-DENABLE_STATIC=YES")

# polarssl
set(EP_polarssl_LINKING_TYPE "-DUSE_SHARED_POLARSSL_LIBRARY=NO")

# speex
set(EP_speex_LINKING_TYPE "-DENABLE_STATIC=YES")

# srtp
set(EP_srtp_LINKING_TYPE "-DENABLE_STATIC=YES")

# v4l
set(EP_v4l_LINKING_TYPE "--enable-static" "--disable-shared" "--with-pic")

# vpx
set(EP_vpx_LINKING_TYPE "--enable-static" "--disable-shared" "--enable-pic")

# xml2
set(EP_xml2_LINKING_TYPE "--enable-static" "--disable-shared" "--with-pic")


# Python module
linphone_builder_apply_flags()
linphone_builder_set_ep_directories(pylinphone)
linphone_builder_expand_external_project_vars()
ExternalProject_Add(TARGET_pylinphone
	DEPENDS TARGET_linphone
	TMP_DIR ${ep_tmp}
	BINARY_DIR ${ep_build}
	DOWNLOAD_COMMAND ""
	PATCH_COMMAND "${CMAKE_COMMAND}" "-E" "copy_directory" "${CMAKE_CURRENT_LIST_DIR}/python" "<SOURCE_DIR>"
	CMAKE_GENERATOR ${CMAKE_GENERATOR}
	CMAKE_ARGS ${LINPHONE_BUILDER_EP_ARGS}
)

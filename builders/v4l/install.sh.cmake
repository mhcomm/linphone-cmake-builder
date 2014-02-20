#!/bin/sh

export CC=@LINPHONE_BUILDER_TOOLCHAIN_CC@
export CXX=@LINPHONE_BUILDER_TOOLCHAIN_CXX@
export LD=@LINPHONE_BUILDER_TOOLCHAIN_LD@
export AR=@LINPHONE_BUILDER_TOOLCHAIN_AR@
export RANLIB=@LINPHONE_BUILDER_TOOLCHAIN_RANLIB@
export STRIP=@LINPHONE_BUILDER_TOOLCHAIN_STRIP@
export NM=@LINPHONE_BUILDER_TOOLCHAIN_NM@

export CPPFLAGS="@LINPHONE_BUILDER_TOOLCHAIN_CPPFLAGS@ @EP_v4l_EXTRA_CPPFLAGS@"
export CFLAGS="@LINPHONE_BUILDER_TOOLCHAIN_CFLAGS@ @EP_v4l_EXTRA_CFLAGS@"
export CXXFLAGS="@LINPHONE_BUILD_TOOLCHAIN_CXXFLAGS@ @EP_v4l_EXTRA_CXXFLAGS@"
export LDFLAGS="@LINPHONE_BUILDER_TOOLCHAIN_LDFLAGS@ @EP_v4l_EXTRA_LDFLAGS@"

export PKG_CONFIG_LIBDIR="@LINPHONE_BUILDER_PKG_CONFIG_LIBDIR@"

cd @ep_build@
make V=@CMAKE_VERBOSE_MAKEFILE@ install

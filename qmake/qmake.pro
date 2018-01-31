# CDDL HEADER START
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#
# CDDL HEADER END

# Copyright 2017 Saso Kiselkov. All rights reserved.

# Shared library without any Qt functionality
TEMPLATE = lib
QT -= gui core

CONFIG += plugin debug
CONFIG -= thread exceptions qt rtti

VERSION = 1.0.0

INCLUDEPATH += $$[LIBACFUTILS]/SDK/CHeaders/XPLM
INCLUDEPATH += $$[LIBACFUTILS]/SDK/CHeaders/Widgets
# Always just use the shipped OpenAL headers for predictability.
# The ABI is X-Plane-internal and stable anyway.
INCLUDEPATH += $$[LIBACFUTILS]/OpenAL/include
INCLUDEPATH += $$[LIBACFUTILS]/src
INCLUDEPATH += $$[LIBACFUTILS]/acf_apis
INCLUDEPATH += $$[LIBACFUTILS]/glew

# Needed for openwxr/xplane_api.h
INCLUDEPATH += ..

QMAKE_CFLAGS += -O2 -std=c99 -g -W -Wall -Wextra -Werror -fvisibility=hidden \
    -Wno-unused-local-typedefs -Wunused-result

# Make sure to disable Qmake's own warnings system, because it overrides
# our warning flags. This breaks CTASSERT, which relies on an unused local
# typedef.
QMAKE_CFLAGS_WARN_ON -= -W -Wall
QMAKE_CXXFLAGS_WARN_ON -= -W -Wall

# _GNU_SOURCE needed on Linux for getline()
# DEBUG - used by our ASSERT macro
# _FILE_OFFSET_BITS=64 to get 64-bit ftell and fseek on 32-bit platforms.
# _USE_MATH_DEFINES - sometimes helps getting M_PI defined from system headers
DEFINES += _GNU_SOURCE DEBUG _FILE_OFFSET_BITS=64 _USE_MATH_DEFINES

# Latest X-Plane APIs. No legacy support needed.
DEFINES += XPLM200 XPLM210 GLEW_BUILD=GLEW_STATIC

# Grab the latest tag as the version number for a release version.
# (TODO: beta builds are only identified by the git commit ID)
#DEFINES += PLUGIN_VERSION=\'\"$$system("git describe --abbrev=0 --tags")\"\'
DEFINES += PLUGIN_VERSION=\'\"$$system("git rev-parse --short HEAD")\"\'

# Just a generally good idea not to depend on shipped libgcc.
!macx {
	LIBS += -static-libgcc
}

QMAKE_CFLAGS += -Wno-missing-field-initializers

win32 {
	CONFIG += dll
	DEFINES += APL=0 IBM=1 LIN=0 _WIN32_WINNT=0x0600
	TARGET = win.xpl
	QMAKE_DEL_FILE = rm -f
	LIBS += -Wl,--exclude-libs,ALL
}

win32:contains(CROSS_COMPILE, x86_64-w64-mingw32-) {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps win-64 \
	    --cflags")

	# This must go first for GCC to properly find dependent symbols
	LIBS += -Wl,--whole-archive $$[LIBACFUTILS]/qmake/win64/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps win-64 --libs")

	LIBS += -L$$[LIBACFUTILS]/SDK/Libraries/Win -lXPLM_64
	LIBS += -L$$[LIBACFUTILS]/SDK/Libraries/Win -lXPWidgets_64
	LIBS += -L$$[LIBACFUTILS]/OpenAL/libs/Win64 -lOpenAL32
	LIBS += -L$$[LIBACFUTILS]/GL_for_Windows/lib -lglu32 -lopengl32

	LIBS += -ldbghelp
}

win32:contains(CROSS_COMPILE, i686-w64-mingw32-) {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps win-32 \
	    --cflags")

	LIBS += -Wl,--whole-archive $$[LIBACFUTILS]/qmake/win32/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps win-32 --libs")

	LIBS += -L$$[LIBACFUTILS]/SDK/Libraries/Win -lXPLM
	LIBS += -L$$[LIBACFUTILS]/SDK/Libraries/Win -lXPWidgets
	LIBS += -L$$[LIBACFUTILS]/OpenAL/libs/Win32 -lOpenAL32
	LIBS += -L$$[LIBACFUTILS]/GL_for_Windows/lib -lglu32 -lopengl32

	LIBS += -ldbghelp
}

unix:!macx {
	DEFINES += APL=0 IBM=0 LIN=1
	TARGET = lin.xpl
	LIBS += -nodefaultlibs
	LIBS += -Wl,--exclude-libs,ALL
	LIBS += -lc_nonshared
}

linux-g++-64 {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps linux-64 \
	    --cflags")

	LIBS += -L$$[LIBACFUTILS]/qmake/lin64/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps linux-64 --libs")
}

linux-g++-32 {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps linux-32 \
	    --cflags")

	# The stack protector forces us to depend on libc,
	# but we'd prefer to be static.
	QMAKE_CFLAGS += -fno-stack-protector
	LIBS += -fno-stack-protector

	LIBS += $$[LIBACFUTILS]/qmake/lin32/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps linux-32 --libs")

	LIBS += -lssp_nonshared
}

macx {
	# Prevent linking via clang++ which makes us depend on libstdc++
	QMAKE_LINK = $$QMAKE_CC
	QMAKE_CFLAGS += -mmacosx-version-min=10.7
	QMAKE_LFLAGS += -mmacosx-version-min=10.7

	DEFINES += APL=1 IBM=0 LIN=0
	TARGET = mac.xpl
	INCLUDEPATH += ../OpenAL/include
	LIBS += -F$$[LIBACFUTILS]/SDK/Libraries/Mac
	LIBS += -framework OpenGL -framework OpenAL -framework XPLM
	LIBS += -framework XPWidgets
}

macx-clang {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps mac-64 \
	    --cflags")
	QMAKE_CFLAGS += $$system("PKG_CONFIG_PATH=../pcre2/pcre2-mac-64 \
	    pkg-config --cflags libpcre2-8")
	QMAKE_CFLAGS += $$system("PKG_CONFIG_PATH=../libxml2/libxml2-mac-64 \
	    pkg-config --cflags libxml-2.0")

	LIBS += $$[LIBACFUTILS]/qmake/mac64/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps mac-64 --libs")

	LIBS += $$system("PKG_CONFIG_PATH=../pcre2/pcre2-mac-64 pkg-config \
	    --libs libpcre2-8")
	LIBS += "../libxml2/libxml2-mac-64/.libs/libxml2.a"
}

macx-clang-32 {
	QMAKE_CFLAGS += $$system("$$[LIBACFUTILS]/pkg-config-deps mac-32 \
	    --cflags")
	QMAKE_CFLAGS += $$system("PKG_CONFIG_PATH=../pcre2/pcre2-mac-32 \
	    pkg-config --cflags libpcre2-8")
	QMAKE_CFLAGS += $$system("PKG_CONFIG_PATH=../libxml2/libxml2-mac-32 \
	    pkg-config --cflags libxml-2.0")

	LIBS += $$[LIBACFUTILS]/qmake/mac32/libacfutils.a
	LIBS += $$system("$$[LIBACFUTILS]/pkg-config-deps mac-32 --libs")

	LIBS += $$system("PKG_CONFIG_PATH=../pcre2/pcre2-mac-32 pkg-config \
	    --libs libpcre2-8")
	LIBS += "../libxml2/libxml2-mac-32/.libs/libxml2.a"
}

HEADERS += ../src/*.h
SOURCES += ../src/*.c

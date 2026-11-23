cmake_minimum_required(VERSION 3.14.0)

# Build a 32-bit Windows executable
set(WINDOWS_32BIT 0)

# Build with release optimizations (Mac/Linux)
set(MAC_LINUX_RELEASE 1)

# Build using CI / system / vcpkg / Homebrew libraries instead of ~/Dev or C:/Dev
option(CI_BUILD "Use system/vcpkg/Homebrew libraries instead of prebuilt DEV_DIR" OFF)

# Project setup
set(CMAKE_CXX_STANDARD 17)
set(QT_VERSION "5.15.9")
if (WIN32)
	set(CMAKE_CONFIGURATION_TYPES "Debug" "RelWithDebInfo" "Release")
	if (WINDOWS_32BIT)
		set(PLATFORM "Win32")
		set(WIN_EXT_FOLDER "Win32")
		set(QT_VERSION "${QT_VERSION}-Win32")
	else()
		set(PLATFORM "x64")
		set(WIN_EXT_FOLDER "Win64")
	endif()
	set(CMAKE_GENERATOR_PLATFORM ${PLATFORM})
elseif (NOT APPLE)
	if (EXISTS "/usr/bin/clang-12" AND EXISTS "/usr/bin/clang++-12")
		set(CMAKE_C_COMPILER "/usr/bin/clang-12")
		set(CMAKE_CXX_COMPILER "/usr/bin/clang++-12")
	endif()
endif()

project(Mine-imator)
add_definitions("-DBUILD_FOLDER=QString(\"${CMAKE_BINARY_DIR}\")")
add_definitions("-DPROJECT_NAME=\"${PROJECT_NAME}\"")
add_definitions("-DAPP_STORAGE_NAME=\"Mine-imator-Legacy-Reborn\"")
add_definitions("-DAPP_DISPLAY_NAME=\"Mine-imator: Legacy Reborn\"")

# Platform specific configurations
if (WIN32)

	message("Windows platform (${PLATFORM})")
	add_definitions("-DOS_WINDOWS" /MP /bigobj /openmp)
	add_definitions("-DDEBUG_MODE=$<$<CONFIG:Debug>:1>$<$<CONFIG:RelWithDebInfo>:1>$<$<CONFIG:Release>:0>")
	add_definitions("-DRELEASE_MODE=!DEBUG_MODE")

	set(APPICON_RC "${CMAKE_SOURCE_DIR}/Asset/Icons/appicon.rc")
	if (CI_BUILD)
		set(CMAKE_CXX_FLAGS_DEBUG "/Zi /Ob0 /Od /RTC1 /MDd")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/Zi /O2 /Ob1 /DNDEBUG /MD")
		set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ot /Ox /DNDEBUG /MD")
		set(CMAKE_CXX_FLAGS_DEBUG_WIN32 ${CMAKE_CXX_FLAGS_DEBUG})
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_WIN32 ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
		set(CMAKE_CXX_FLAGS_RELEASE_WIN32 ${CMAKE_CXX_FLAGS_RELEASE})

		find_package(ZLIB REQUIRED)
		find_package(libzip CONFIG REQUIRED)
		find_package(Freetype REQUIRED)
		find_package(OpenAL CONFIG REQUIRED)

		set(FFMPEG_DIR "$ENV{FFMPEG_DIR}" CACHE PATH "FFmpeg root directory")
		set(FFMPEG_INCLUDE_DIRS "${FFMPEG_DIR}/include")
		find_library(AVFORMAT_LIB NAMES avformat libavformat PATHS "${FFMPEG_DIR}/lib" "${FFMPEG_DIR}" REQUIRED)
		find_library(AVCODEC_LIB NAMES avcodec libavcodec PATHS "${FFMPEG_DIR}/lib" "${FFMPEG_DIR}" REQUIRED)
		find_library(SWRESAMPLE_LIB NAMES swresample libswresample PATHS "${FFMPEG_DIR}/lib" "${FFMPEG_DIR}" REQUIRED)
		find_library(SWSCALE_LIB NAMES swscale libswscale PATHS "${FFMPEG_DIR}/lib" "${FFMPEG_DIR}" REQUIRED)
		find_library(AVUTIL_LIB NAMES avutil libavutil PATHS "${FFMPEG_DIR}/lib" "${FFMPEG_DIR}" REQUIRED)
		set(LIBS
			ZLIB::ZLIB
			libzip::zip
			Freetype::Freetype
			OpenAL::OpenAL
			${AVFORMAT_LIB}
			${AVCODEC_LIB}
			${SWRESAMPLE_LIB}
			${SWSCALE_LIB}
			${AVUTIL_LIB}
			"Mf" "Mfplat" "mfuuid" "strmiids"
			"d3d11.lib" "d3dcompiler.lib"
			"Winmm" "Ole32" "User32" "Ws2_32" "Bcrypt"
		)
	else()
		set(DEV_DIR $ENV{DEV_DIR})
		set(EXT_DIR "${CMAKE_SOURCE_DIR}/External/${WIN_EXT_FOLDER}")
		set(LIBS "${EXT_DIR}/zip.lib" "${EXT_DIR}/zlibstatic.lib" "${EXT_DIR}/OpenAL32.lib" "${EXT_DIR}/libx264.lib") # Zip, OpenAL, x264 (precompiled)
		set(LIBS ${LIBS} "Mf" "Mfplat" "mfuuid" "strmiids") # FFmpeg dependencies
		set(LIBS ${LIBS} "d3d11.lib" "d3dcompiler.lib") # Direct3D 11
		set(CMAKE_MFC_FLAG 1)
		set_property(GLOBAL PROPERTY USE_FOLDERS ON)
		
		set(CMAKE_CXX_FLAGS_DEBUG "/ZI /Ob0 /Od /RTC1 /MT")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/ZI /O2 /Ob1 /DNDEBUG /MT")
		set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ot /Ox /DNDEBUG /MT")
		set(CMAKE_CXX_FLAGS_DEBUG_WIN32 ${CMAKE_CXX_FLAGS_DEBUG})
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_WIN32 ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
		set(CMAKE_CXX_FLAGS_RELEASE_WIN32 ${CMAKE_CXX_FLAGS_RELEASE})
	endif()

else()

	set(DEV_DIR "~/Dev")
	add_definitions("-DOS_UNIX")
	add_compile_options("-Wall")
	add_compile_options("-Wno-overloaded-virtual")
	add_compile_options("-Wno-parentheses")
	add_compile_options("-Wno-switch")
	add_compile_options("-Wno-unknown-pragmas")
	if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
		add_compile_options("-Wno-sometimes-uninitialized")
		add_compile_options("-Wno-reorder-ctor")
	else()
		add_compile_options("-Wno-reorder")
		add_compile_options("-Wno-sign-compare")
		add_compile_options("-Wno-unused-variable")
		add_compile_options("-Wno-unused-but-set-variable")
		add_compile_options("-Wno-class-memaccess")
	endif()

	if (MAC_LINUX_RELEASE)
		add_compile_options("-O3")
		add_compile_options("-DNDEBUG")
		add_definitions("-DDEBUG_MODE=0")
		add_definitions("-DRELEASE_MODE=1")
	else()
		add_compile_options("-O0")
		add_compile_options("-g")
		add_definitions("-DDEBUG_MODE=1")
		add_definitions("-DRELEASE_MODE=0")
	endif()

	if(APPLE)

		message("Mac platform")
		add_definitions("-DOS_MAC")
		if (CI_BUILD)
			set(MAC_SYSTEM_LIBS ON)
			find_package(PkgConfig REQUIRED)
			pkg_check_modules(CI_DEPS REQUIRED IMPORTED_TARGET libavformat libavcodec libswresample libswscale libavutil freetype2 libzip openal)
			set(LIBS ${LIBS} PkgConfig::CI_DEPS
				"-framework OpenGL"
				"-framework AudioToolbox"
				"-framework VideoToolbox"
				"-framework CoreMedia"
				"-framework CoreAudio"
				"-framework CoreFoundation"
			)
		else()
			set(EXT_DIR "${CMAKE_SOURCE_DIR}/External/Mac")
		
			# FFmpeg dependencies
			set(LIBS ${LIBS} "iconv")
			set(LIBS ${LIBS} "-framework AudioToolBox")
			set(LIBS ${LIBS} "-framework VideoToolBox")
			set(LIBS ${LIBS} "-framework CoreMedia")
			set(LIBS ${LIBS} "-framework CoreAudio")
			set(LIBS ${LIBS} "-framework VideoDecodeAcceleration")
			set(LIBS ${LIBS} "${EXT_DIR}/libx264.a")
			set(LIBS ${LIBS} "${EXT_DIR}/libz.a" "${EXT_DIR}/libzip.a" "${EXT_DIR}/libopenal.a") # Zip, OpenAL (precompiled)
			set(LIBS ${LIBS} "bz2" "lzma")
		endif()
	
	else()

		message("Linux platform")
		set(EXT_DIR "${CMAKE_SOURCE_DIR}/External/Linux")
		if (CI_BUILD)
			set(LINUX_SYSTEM_LIBS ON)
			find_package(PkgConfig REQUIRED)
			pkg_check_modules(CI_DEPS REQUIRED IMPORTED_TARGET libavformat libavcodec libswresample libswscale libavutil freetype2 libzip openal)
			set(LIBS ${LIBS} PkgConfig::CI_DEPS "z" "GL")
		elseif (EXISTS "${DEV_DIR}/Qt/${QT_VERSION}/build")
			set(LINUX_SYSTEM_LIBS OFF)
			set(LIBS ${LIBS} "-lvdpau -lva -lva-drm -lva-x11 -lsndio -lx264 -lgnutls -lnettle")
			set(LIBS ${LIBS} "${EXT_DIR}/libz.a" "${EXT_DIR}/libzip.a" "${EXT_DIR}/libopenal.a")
		else()
			set(LINUX_SYSTEM_LIBS ON)
			find_package(PkgConfig REQUIRED)
			pkg_check_modules(FFMPEG REQUIRED libavformat libavcodec libswresample libswscale libavutil freetype2)
			set(LIBS ${LIBS} ${FFMPEG_LIBRARIES} "${EXT_DIR}/libzip.a" "gnutls" "nettle" "z" "openal" "GL")
		endif()
		if (NOT CI_BUILD)
			set(LIBS ${LIBS} "bz2" "lzma")
		endif()
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath='$ORIGIN'/Data") # Find .so in Data folder

	endif()
	
	# Add OpenMP
	find_package(OpenMP REQUIRED)
	set(LIBS ${LIBS} OpenMP::OpenMP_CXX)

endif()

message("DEV_DIR = ${DEV_DIR}")
message("EXT_DIR = ${EXT_DIR}")

# Add Qt
if (NOT LINUX_SYSTEM_LIBS AND NOT MAC_SYSTEM_LIBS AND NOT (WIN32 AND CI_BUILD))
	set(Qt_DIR "${DEV_DIR}/Qt/${QT_VERSION}/build")
	message("Qt_DIR = ${Qt_DIR}")
	list(APPEND CMAKE_PREFIX_PATH ${Qt_DIR})
endif()
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC OFF)
find_package(Qt5 COMPONENTS Widgets Gui Network REQUIRED)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${Qt5Widgets_EXECUTABLE_COMPILE_FLAGS}")
add_definitions(${Qt5Widgets_DEFINITIONS})
set(LIBS ${LIBS} Qt5::Widgets Qt5::Network)

# Find sprite and shader assets and create a project
file(GLOB_RECURSE ASSETS RELATIVE "${CMAKE_SOURCE_DIR}" "*.png" "*.vsh" "*.fsh" "*.d3d")
source_group(TREE "${CMAKE_SOURCE_DIR}/Asset" FILES ${ASSETS})
add_custom_target(Assets SOURCES ${ASSETS})

# Generate index.qrc file to embed assets into executable
set(INDEX_XML "<!-- Note: Auto-generated, do not modify! -->\n<RCC>\n\t<qresource prefix=\"/\">")
foreach(CURRENT_ASSET ${ASSETS})
	string(REGEX REPLACE "Asset/" "" CURRENT_ASSET "${CURRENT_ASSET}")
	set(INDEX_XML "${INDEX_XML}\n\t\t<file>${CURRENT_ASSET}</file>")
endforeach()
set(INDEX_XML "${INDEX_XML}\n\t</qresource>\n</RCC>")

set(QT_INDEX_FILE "${CMAKE_SOURCE_DIR}/Asset/index.qrc")
file(REMOVE ${QT_INDEX_FILE})
file(WRITE ${QT_INDEX_FILE} "${INDEX_XML}")
add_definitions(-DASSETS_DIR="${CMAKE_SOURCE_DIR}/Asset")

# Add external libraries
set(INCLUDE_DIRS ${CMAKE_SOURCE_DIR})
set(INCLUDE_DIRS ${INCLUDE_DIRS} ${Qt5Widgets_INCLUDE_DIRS})
if (CI_BUILD AND WIN32)
	set(INCLUDE_DIRS ${INCLUDE_DIRS} ${FFMPEG_INCLUDE_DIRS})
elseif (CI_BUILD)
	# Includes come from PkgConfig::CI_DEPS
elseif (LINUX_SYSTEM_LIBS)
	set(INCLUDE_DIRS ${INCLUDE_DIRS} ${FFMPEG_INCLUDE_DIRS})
else()
	set(INCLUDE_DIRS ${INCLUDE_DIRS} "${DEV_DIR}/Libzip/libzip-1.9.2/lib")
	set(INCLUDE_DIRS ${INCLUDE_DIRS} "${DEV_DIR}/FreeType/freetype-2.9.1/include")
	set(INCLUDE_DIRS ${INCLUDE_DIRS} "${DEV_DIR}/FFmpeg/ffmpeg-5.0")
	set(INCLUDE_DIRS ${INCLUDE_DIRS} "${DEV_DIR}/OpenAL/openal-soft-1.22.0/include")

	# Add FFmpeg (precompiled)
	set(LIBS ${LIBS} "${EXT_DIR}/libavformat.a")
	set(LIBS ${LIBS} "${EXT_DIR}/libavcodec.a")
	set(LIBS ${LIBS} "${EXT_DIR}/libswresample.a")
	set(LIBS ${LIBS} "${EXT_DIR}/libswscale.a")
	set(LIBS ${LIBS} "${EXT_DIR}/libavutil.a")
endif()
set(INCLUDE_DIRS ${INCLUDE_DIRS} "${CMAKE_SOURCE_DIR}/External") # simplexnoise1234.c and bundled headers

# Add C++ sources
file(GLOB_RECURSE SRCS RELATIVE "${CMAKE_SOURCE_DIR}" "*.cpp" "*.hpp")
source_group(TREE "${CMAKE_SOURCE_DIR}" PREFIX ${PROJECT_NAME} FILES ${SRCS})
qt5_add_resources(SRCS ${QT_INDEX_FILE})

# Create executable
add_executable(${PROJECT_NAME} ${SRCS} ${APPICON_RC})
if (WIN32)
	set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "Mine-imator-Legacy-Reborn")
	target_link_libraries(${PROJECT_NAME} shell32)
endif()
target_precompile_headers(${PROJECT_NAME} PUBLIC "Common.hpp")
target_include_directories(${PROJECT_NAME} PUBLIC ${INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} ${LIBS})

# Project file settings
set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE "$<$<CONFIG:Debug>:0>$<$<CONFIG:Release>:1>")
set_directory_properties(PROPERTIES VS_STARTUP_PROJECT Mine-imator)
if (WIN32 AND WINDOWS_32BIT)
	set_target_properties(${PROJECT_NAME} PROPERTIES
		LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/Release-Win32"
		RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/Release-Win32"
	)
elseif (APPLE)
	set_target_properties(${PROJECT_NAME} PROPERTIES
		LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}"
		RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}"
	)
endif()

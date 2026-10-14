cmake_minimum_required(VERSION 3.22)
project(ObjectN C CXX)

# Engine tree; override with -DENGINE_DIR=... (gradle property objectn.engineDir) to build
# against an upgraded Zircon tree without touching the project layout.
if(NOT ENGINE_DIR)
    set(ENGINE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../engine_source")
endif()
get_filename_component(ENGINE_DIR "${ENGINE_DIR}" ABSOLUTE)
message(STATUS "ObjectN engine tree: ${ENGINE_DIR}")
set(TP "${CMAKE_CURRENT_SOURCE_DIR}/third_party")

add_subdirectory(SDL2)

set(BUILD_SHARED_LIBS OFF)
set(BUILD_TESTING OFF)
set(INSTALL_DOCS OFF CACHE BOOL "" FORCE)
add_subdirectory(${TP}/libogg-1.3.6 libogg EXCLUDE_FROM_ALL)

set(OGG_INCLUDE_DIR "${TP}/libogg-1.3.6/include" CACHE PATH "" FORCE)
set(OGG_LIBRARY ogg CACHE STRING "" FORCE)
add_subdirectory(${TP}/libvorbis-1.3.7 libvorbis EXCLUDE_FROM_ALL)

set(FT_DISABLE_ZLIB ON CACHE BOOL "" FORCE)
set(FT_DISABLE_BZIP2 ON CACHE BOOL "" FORCE)
set(FT_DISABLE_PNG ON CACHE BOOL "" FORCE)
set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "" FORCE)
set(FT_DISABLE_BROTLI ON CACHE BOOL "" FORCE)
add_subdirectory(${TP}/freetype-2.13.3 freetype EXCLUDE_FROM_ALL)

# libjpeg-turbo rejects add_subdirectory(), so it builds as a separate CMake project.
include(ExternalProject)
set(JPEG_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/jpeg")
ExternalProject_Add(jpegturbo_ext
    SOURCE_DIR "${TP}/libjpeg-turbo-3.1.2"
    BINARY_DIR "${JPEG_PREFIX}/build"
    INSTALL_DIR "${JPEG_PREFIX}/install"
    CMAKE_GENERATOR "${CMAKE_GENERATOR}"
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
        -DANDROID_ABI=${ANDROID_ABI}
        -DANDROID_PLATFORM=${ANDROID_PLATFORM}
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_INSTALL_LIBDIR=lib
        -DENABLE_SHARED=OFF
        -DENABLE_STATIC=ON
        -DWITH_SIMD=OFF
        -DWITH_TURBOJPEG=OFF
        -DWITH_TOOLS=OFF
        -DWITH_TESTS=OFF
    BUILD_BYPRODUCTS "${JPEG_PREFIX}/install/lib/libjpeg.a"
)
add_library(jpeg_static STATIC IMPORTED)
set_target_properties(jpeg_static PROPERTIES IMPORTED_LOCATION "${JPEG_PREFIX}/install/lib/libjpeg.a")
add_dependencies(jpeg_static jpegturbo_ext)

set(ENGINE_SOURCES
    bih crypto cd_shared cl_cmd cl_collision cl_demo cl_ents cl_ents4 cl_ents5
    cl_ents_nq cl_ents_qw cl_input cl_main cl_parse cl_particles cl_screen cl_video
    clvm_cmds cmd collision com_crc16 com_ents com_ents4 com_game com_infostring
    com_msg common console csprogs curves cvar dpvsimpledecode filematch
    fractalnoise fs ft2 utf8lib gl_backend gl_draw gl_rmain gl_rsurf gl_textures
    hmac host image image_png jpeg keys lhnet libcurl lodepng mathlib matrixlib
    mdfour meshqueue mod_skeletal_animatevertices_sse
    mod_skeletal_animatevertices_generic model_alias model_brush model_shared
    model_sprite netconn palette phys polygon portals protocol prvm_cmds
    prvm_edict prvm_exec r_explosion r_lightning r_modules r_shadow r_sky
    r_sprites r_stats sbar sv_ccmds sv_demo sv_ents sv_ents4 sv_ents5
    sv_ents_csqc sv_ents_nq sv_main sv_move sv_phys sv_save sv_send sv_user
    svbsp svvm_cmds sys_shared taskqueue vid_shared view wad world zone
    menu mvm_cmds snd_main snd_mem snd_mix snd_ogg snd_wav snd_xmp snd_sdl
    sys_sdl vid_sdl thread_sdl builddate convex cl_steam
)
list(TRANSFORM ENGINE_SOURCES PREPEND "${ENGINE_DIR}/")
list(TRANSFORM ENGINE_SOURCES APPEND ".c")

# Upstream occasionally moves or drops a file (Beta 164 replaced cl_steam.c with steam.c);
# skip what no longer exists so an engine upgrade does not fail at configure time.
set(ENGINE_SOURCES_FOUND "")
foreach(src ${ENGINE_SOURCES})
    if(EXISTS "${src}")
        list(APPEND ENGINE_SOURCES_FOUND "${src}")
    else()
        get_filename_component(missing "${src}" NAME)
        message(STATUS "engine source not in this tree, skipped: ${missing}")
    endif()
endforeach()
set(ENGINE_SOURCES ${ENGINE_SOURCES_FOUND})

add_library(main SHARED ${ENGINE_SOURCES} steam_android.c touch_android.c shader_cache_android.c)

target_include_directories(main PRIVATE
    ${ENGINE_DIR}
    ${TP}/freetype-2.13.3/include
    ${JPEG_PREFIX}/install/include
    ${TP}/libvorbis-1.3.7/include
    ${TP}/libogg-1.3.6/include
    ${CMAKE_CURRENT_BINARY_DIR}/libogg/include
)

target_compile_definitions(main PRIVATE
    CORE_SDL CONFIG_MENU USE_GLES2 ANDROID_TOUCH_OVERLAY _GNU_SOURCE
    LINK_TO_ZLIB LINK_TO_LIBVORBIS LINK_TO_LIBJPEG
    _FILE_OFFSET_BITS=64 __KERNEL_STRICT_NAMES
)

# OBJECTN selects the ObjectN game definition; QUAKE builds the engine's stock id1 mode
set(ZIRCON_GAME "OBJECTN" CACHE STRING "game define: OBJECTN or QUAKE")
if(NOT ZIRCON_GAME STREQUAL "QUAKE")
    target_compile_definitions(main PRIVATE ${ZIRCON_GAME})
endif()

target_compile_options(main PRIVATE
    -include ${CMAKE_CURRENT_SOURCE_DIR}/android_compat.h
    -fno-strict-aliasing -fno-math-errno -fno-trapping-math
    -Wno-error=implicit-function-declaration
    -Wno-error=incompatible-pointer-types
    -Wno-error=int-conversion
    -Wno-deprecated-non-prototype
    -w
)

target_link_libraries(main PRIVATE
    SDL2 SDL2main freetype jpeg_static vorbisfile vorbis ogg z log android GLESv3 EGL m dl
)
target_link_options(main PRIVATE "-Wl,-z,max-page-size=16384")

cmake_minimum_required(VERSION 3.20)
project(SMBIOSGame LANGUAGES C OBJC)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_XCODE_GENERATE_SCHEME ON)

get_filename_component(SMB_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(NESRECOMP_ROOT "${SMB_ROOT}/nesrecomp")

set(SMB_SDL_SOURCE "" CACHE PATH "SDL2 2.30.0 source checkout")
set(SMB_ROM "" CACHE FILEPATH "Private original SMB cartridge, never committed")
set(SMB_HOST_RECOMPILER "" CACHE FILEPATH "Native macOS NESRecomp executable")

foreach(required_file
        "${SMB_SDL_SOURCE}/CMakeLists.txt"
        "${SMB_ROM}"
        "${SMB_HOST_RECOMPILER}"
        "${NESRECOMP_ROOT}/runner/cyc/project.cmake")
    if(NOT EXISTS "${required_file}")
        message(FATAL_ERROR "Required build input is missing: ${required_file}")
    endif()
endforeach()

# A separate target: leave the validated Windows build untouched.
set(NESRECOMP_PPU_IMPL HLE CACHE STRING "" FORCE)
set(NESRECOMP_RECOMP_UI OFF CACHE STRING "" FORCE)
set(NESRECOMP_STARTUP_DIAGNOSTICS OFF CACHE BOOL "" FORCE)
set(NESRECOMP_APU_OPERATION OFF CACHE BOOL "" FORCE)
set(NESRECOMP_NATIVE_WAIT_LOOPS OFF CACHE BOOL "" FORCE)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)

add_subdirectory("${SMB_SDL_SOURCE}" "${CMAKE_CURRENT_BINARY_DIR}/SDL2" EXCLUDE_FROM_ALL)
if(NOT TARGET SDL2::SDL2-static)
    message(FATAL_ERROR "SDL2 2.30.0 static target is unavailable")
endif()

include("${NESRECOMP_ROOT}/runner/cyc/project.cmake")
nesrecomp_add_cycle_game(SMBIOSGame
    HEADLESS
    NO_RECOMP_UI
    ROM "${SMB_ROM}"
    RECOMPILER "${SMB_HOST_RECOMPILER}"
    GAME_CONFIG "${SMB_ROOT}/game-cycle.toml"
    SEED_FILE "${SMB_ROOT}/cyc_seeds.txt"
    PLAYERS 2
    REGION NTSC
)

# HEADLESS above suppresses automatic SDL discovery (which may pick up a
# desktop SDL). Install the real SDL2 iOS sources on this game target instead.
set(CYC_DIR "${NESRECOMP_ROOT}/runner/cyc")
target_sources(SMBIOSGame PRIVATE
    "${CYC_DIR}/cyc_sdl.c"
    "${CYC_DIR}/cyc_input.c"
    "${CYC_DIR}/cyc_settings.c"
    "${CYC_DIR}/cyc_tcp.c"
    "${CYC_DIR}/cyc_chat.c"
    "${CYC_DIR}/cyc_affinity.c"
    "${CMAKE_CURRENT_SOURCE_DIR}/main.m"
)
target_compile_definitions(SMBIOSGame PRIVATE CYC_WITH_SDL=1)
target_include_directories(SMBIOSGame PRIVATE "${SMB_SDL_SOURCE}/include")
target_link_libraries(SMBIOSGame PRIVATE SDL2::SDL2-static)

# The original cyc_host.c defines the working Windows main(). Rename only the
# iOS translation unit's entry point; don't patch the engine submodule.
set_source_files_properties("${CYC_DIR}/cyc_host.c"
    PROPERTIES COMPILE_DEFINITIONS "main=nesrecomp_host_entry")

target_sources(SMBIOSGame PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/touch_controls.m"
)
set_source_files_properties(
    "${CMAKE_CURRENT_SOURCE_DIR}/touch_controls.m"
    PROPERTIES COMPILE_FLAGS "-fobjc-arc"
)
find_library(SMB_FOUNDATION Foundation REQUIRED)
find_library(SMB_UIKIT UIKit REQUIRED)
target_link_libraries(SMBIOSGame PRIVATE "${SMB_FOUNDATION}" "${SMB_UIKIT}")

# Private build input: package the verified ROM as an app resource.
# Never commit the ROM or publish the resulting app artifact.
set_source_files_properties("${SMB_ROM}" PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources")
target_sources(SMBIOSGame PRIVATE "${SMB_ROM}")

set_target_properties(SMBIOSGame PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.ansinerd.smbiosgame"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
)


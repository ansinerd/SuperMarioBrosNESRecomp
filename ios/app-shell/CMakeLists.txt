cmake_minimum_required(VERSION 3.20)
project(SMBIOSApp LANGUAGES C OBJC)

set(CMAKE_C_STANDARD 11)
set(SMB_SDL_SOURCE "" CACHE PATH "Path to SDL2 2.30.0 source checkout")
if(NOT EXISTS "${SMB_SDL_SOURCE}/CMakeLists.txt")
    message(FATAL_ERROR "Set SMB_SDL_SOURCE to the SDL2 2.30.0 source directory")
endif()

set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TEST OFF CACHE BOOL "" FORCE)
add_subdirectory("${SMB_SDL_SOURCE}" "${CMAKE_CURRENT_BINARY_DIR}/SDL2" EXCLUDE_FROM_ALL)

if(NOT TARGET SDL2::SDL2-static)
    message(FATAL_ERROR "SDL2::SDL2-static is unavailable")
endif()

add_executable(SMBIOSApp MACOSX_BUNDLE main.m)
target_include_directories(SMBIOSApp PRIVATE "${SMB_SDL_SOURCE}/include")
target_link_libraries(SMBIOSApp PRIVATE SDL2::SDL2-static)

set_target_properties(SMBIOSApp PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.ansinerd.smbiosapp"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
)

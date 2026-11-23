cmake_minimum_required(VERSION 3.20)
project(SMBIOSCore C)

set(CMAKE_C_STANDARD 11)

get_filename_component(SMB_ROOT
    "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

set(NESRECOMP_ROOT "${SMB_ROOT}/nesrecomp")

set(NESRECOMP_PPU_IMPL HLE CACHE STRING "" FORCE)
set(NESRECOMP_APU_OPERATION OFF CACHE BOOL "" FORCE)
set(NESRECOMP_NATIVE_WAIT_LOOPS OFF CACHE BOOL "" FORCE)

include("${NESRECOMP_ROOT}/runner/cyc/cyc.cmake")

add_library(SMBIOSCoreObjects OBJECT
    ${NESRECOMP_CYC_SOURCES}
)

target_include_directories(SMBIOSCoreObjects PRIVATE
    ${NESRECOMP_CYC_INCLUDE_DIRS}
)

target_compile_features(SMBIOSCoreObjects PRIVATE c_std_11)

target_compile_definitions(SMBIOSCoreObjects PRIVATE
    CYC_HOST_EXTRAS_STRONG=1
    CYC_GAME_PLAYERS=2
    NESRECOMP_GAME_PLAYERS=2
    CYC_GAME_REGION=0
    NESRECOMP_NATIVE_INTERVALS=0
)

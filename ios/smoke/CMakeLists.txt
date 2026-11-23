cmake_minimum_required(VERSION 3.20)
project(SMBIOSSmoke C)

set(CMAKE_C_STANDARD 11)

get_filename_component(SMB_ROOT
    "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)

set(NESRECOMP_ROOT "${SMB_ROOT}/nesrecomp")

set(NESRECOMP_PPU_IMPL HLE CACHE STRING "" FORCE)
set(NESRECOMP_RECOMP_UI OFF CACHE STRING "" FORCE)
set(NESRECOMP_STARTUP_DIAGNOSTICS OFF CACHE BOOL "" FORCE)

set(NESRECOMP_ROM "" CACHE FILEPATH "Owner supplied SMB ROM")

if(NOT EXISTS "${NESRECOMP_ROM}")
    message(FATAL_ERROR "Set NESRECOMP_ROM to the verified ROM")
endif()

include("${NESRECOMP_ROOT}/runner/cyc/project.cmake")

nesrecomp_add_cycle_game(SMBIOSSmoke
    NO_RECOMP_UI
    ROM "${NESRECOMP_ROM}"
    GAME_CONFIG "${SMB_ROOT}/game-cycle.toml"
    SEED_FILE "${SMB_ROOT}/cyc_seeds.txt"
    PLAYERS 2
    REGION NTSC
)

get_target_property(HAS_SDL SMBIOSSmoke NESRECOMP_CYC_SDL)
if(NOT HAS_SDL)
    message(FATAL_ERROR "SDL2 was not found")
endif()

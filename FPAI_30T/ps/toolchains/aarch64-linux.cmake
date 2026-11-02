set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
# Set FPAI_CROSS_PREFIX to an installed compiler prefix, e.g.
# D:/toolchains/gcc-arm-10.3/bin/aarch64-none-linux-gnu-
# or /usr/bin/aarch64-linux-gnu-. No workstation path is embedded here.
if(NOT DEFINED FPAI_CROSS_PREFIX)
  if(DEFINED ENV{FPAI_CROSS_PREFIX})
    set(FPAI_CROSS_PREFIX "$ENV{FPAI_CROSS_PREFIX}")
  else()
    set(FPAI_CROSS_PREFIX aarch64-linux-gnu-)
  endif()
endif()
set(FPAI_CROSS_PREFIX "${FPAI_CROSS_PREFIX}" CACHE STRING "AArch64 Linux compiler prefix")
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES FPAI_CROSS_PREFIX)
# Resolve on the host so Windows .exe suffixes are found even though the
# produced application targets Linux. Preserve the prefix in compiler probes.
find_program(FPAI_C_COMPILER NAMES "${FPAI_CROSS_PREFIX}gcc" NO_CMAKE_FIND_ROOT_PATH)
find_program(FPAI_CXX_COMPILER NAMES "${FPAI_CROSS_PREFIX}g++" NO_CMAKE_FIND_ROOT_PATH)
if(NOT FPAI_C_COMPILER OR NOT FPAI_CXX_COMPILER)
  message(FATAL_ERROR "Cannot find the AArch64 Linux gcc/g++ compiler; set FPAI_CROSS_PREFIX")
endif()
set(CMAKE_C_COMPILER "${FPAI_C_COMPILER}")
set(CMAKE_CXX_COMPILER "${FPAI_CXX_COMPILER}")

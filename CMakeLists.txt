cmake_minimum_required(VERSION 3.18)
project(pydunedaqfmt_superbuild LANGUAGES CXX)

include(ExternalProject)

# scikit-build-core sets SKBUILD_PLATLIB_DIR to the wheel staging directory
# for platform-specific (compiled) Python files. Fall back for manual builds.
if(DEFINED SKBUILD_PLATLIB_DIR)
    set(PYTHON_INSTALL_DIR "${SKBUILD_PLATLIB_DIR}")
else()
    set(PYTHON_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/python")
endif()

# Locate the pybind11 CMake config provided by the pip-installed package.
# daq-cmakeConfig.cmake calls find_dependency(pybind11), so all packages
# need this on their CMAKE_PREFIX_PATH.
execute_process(
    COMMAND python3 -m pybind11 --cmakedir
    OUTPUT_VARIABLE PYBIND11_CMAKE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _pybind11_result
)
if(NOT _pybind11_result EQUAL 0 OR NOT PYBIND11_CMAKE_DIR)
    message(FATAL_ERROR "Could not locate pybind11 cmake dir via 'python3 -m pybind11 --cmakedir'")
endif()
message(STATUS "Found pybind11 cmake dir: ${PYBIND11_CMAKE_DIR}")

# Intermediate install prefixes for each package.
set(DAQ_CMAKE_STAGING        "${CMAKE_CURRENT_BINARY_DIR}/daq-cmake-install")
set(DETDATAFORMATS_STAGING   "${CMAKE_CURRENT_BINARY_DIR}/detdataformats-install")
set(DAQDATAFORMATS_STAGING   "${CMAKE_CURRENT_BINARY_DIR}/daqdataformats-install")
set(FDDETDATAFORMATS_STAGING "${CMAKE_CURRENT_BINARY_DIR}/fddetdataformats-install")
set(TRGDATAFORMATS_STAGING   "${CMAKE_CURRENT_BINARY_DIR}/trgdataformats-install")
set(CETPLUGIN_STAGING        "${CMAKE_CURRENT_BINARY_DIR}/cetplugin-install")
set(TRACE_STAGING            "${CMAKE_CURRENT_BINARY_DIR}/trace-install")
set(ERS_STAGING              "${CMAKE_CURRENT_BINARY_DIR}/ers-install")
set(LOGGING_STAGING          "${CMAKE_CURRENT_BINARY_DIR}/logging-install")
set(DETCHANNELMAPS_STAGING   "${CMAKE_CURRENT_BINARY_DIR}/detchannelmaps-install")
set(RAWDATAUTILS_STAGING     "${CMAKE_CURRENT_BINARY_DIR}/rawdatautils-install")

# ── Step 1: build and install daq-cmake ──────────────────────────────────────
ExternalProject_Add(
    daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/daq-cmake"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/daq-cmake-build"
    INSTALL_DIR "${DAQ_CMAKE_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    TEST_COMMAND ""
)

# ── Step 2: build detdataformats ─────────────────────────────────────────────
ExternalProject_Add(
    detdataformats_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/detdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/detdataformats-build"
    INSTALL_DIR "${DETDATAFORMATS_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 3: build daqdataformats ─────────────────────────────────────────────
ExternalProject_Add(
    daqdataformats_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/daqdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/daqdataformats-build"
    INSTALL_DIR "${DAQDATAFORMATS_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 4: build trgdataformats ─────────────────────────────────────────────
ExternalProject_Add(
    trgdataformats_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/trgdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/trgdataformats-build"
    INSTALL_DIR "${TRGDATAFORMATS_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 5: build fddetdataformats (needs detdataformats) ────────────────────
ExternalProject_Add(
    fddetdataformats_ep
    DEPENDS     daq_cmake_ep detdataformats_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/fddetdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/fddetdataformats-build"
    INSTALL_DIR "${FDDETDATAFORMATS_STAGING}"
    LIST_SEPARATOR  |
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        "-DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}|${DETDATAFORMATS_STAGING}"
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 6: build cetplugin (provides cetlib/cetlib_except) ──────────────────
ExternalProject_Add(
    cetplugin_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/cetplugin"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/cetplugin-build"
    INSTALL_DIR "${CETPLUGIN_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_INSTALL_LIBDIR=lib
    TEST_COMMAND ""
)

# ── Step 7: build trace ───────────────────────────────────────────────────────
ExternalProject_Add(
    trace_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/trace"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/trace-build"
    INSTALL_DIR "${TRACE_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_INSTALL_LIBDIR=lib
    TEST_COMMAND ""
)

# ── Step 8: build ers ─────────────────────────────────────────────────────────
ExternalProject_Add(
    ers_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/ers"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/ers-build"
    INSTALL_DIR "${ERS_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 9: build logging ─────────────────────────────────────────────────────
ExternalProject_Add(
    logging_ep
    DEPENDS     daq_cmake_ep ers_ep trace_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/logging"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/logging-build"
    INSTALL_DIR "${LOGGING_STAGING}"
    LIST_SEPARATOR  |
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        "-DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}|${ERS_STAGING}|${TRACE_STAGING}"
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR>
)

# ── Step 10: build detchannelmaps ─────────────────────────────────────────────
ExternalProject_Add(
    detchannelmaps_ep
    DEPENDS     daq_cmake_ep detdataformats_ep cetplugin_ep ers_ep logging_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/detchannelmaps"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/detchannelmaps-build"
    INSTALL_DIR "${DETCHANNELMAPS_STAGING}"
    LIST_SEPARATOR  |
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        "-DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}|${DETDATAFORMATS_STAGING}|${CETPLUGIN_STAGING}|${ERS_STAGING}|${LOGGING_STAGING}"
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 11: build rawdatautils ───────────────────────────────────────────────
ExternalProject_Add(
    rawdatautils_ep
    DEPENDS     daq_cmake_ep daqdataformats_ep detdataformats_ep fddetdataformats_ep detchannelmaps_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/rawdatautils"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/rawdatautils-build"
    INSTALL_DIR "${RAWDATAUTILS_STAGING}"
    LIST_SEPARATOR  |
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        "-DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}|${DAQDATAFORMATS_STAGING}|${DETDATAFORMATS_STAGING}|${FDDETDATAFORMATS_STAGING}|${DETCHANNELMAPS_STAGING}|${CETPLUGIN_STAGING}|${ERS_STAGING}|${LOGGING_STAGING}"
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

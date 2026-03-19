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
# daq-cmakeConfig.cmake calls find_dependency(pybind11), so detdataformats
# needs this on its CMAKE_PREFIX_PATH.
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

# Intermediate prefix where daq-cmake is installed so that detdataformats
# can resolve find_package(daq-cmake REQUIRED).
set(DAQ_CMAKE_STAGING        "${CMAKE_CURRENT_BINARY_DIR}/daq-cmake-install")
set(DETDATAFORMATS_STAGING   "${CMAKE_CURRENT_BINARY_DIR}/detdataformats-install")

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

# ── Step 2: build detdataformats against the installed daq-cmake ─────────────
# After install, the superbuild copies lib/python/ into PYTHON_INSTALL_DIR
# so scikit-build-core harvests the .so and __init__.py into the wheel.
ExternalProject_Add(
    detdataformats_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/detdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/detdataformats-build"
    INSTALL_DIR "${DETDATAFORMATS_STAGING}"
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        # Let detdataformats find the daq-cmake package installed in step 1
        -DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}
        # Point directly at the pip-installed pybind11 cmake config
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        # Force lib/ (not lib64/) so the Python install path is predictable
        -DCMAKE_INSTALL_LIBDIR=lib
        # Tests require Boost but we do not need them in the wheel
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

# ── Step 3: build daqdataformats against the installed daq-cmake ─────────────
ExternalProject_Add(
    daqdataformats_ep
    DEPENDS     daq_cmake_ep
    SOURCE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/daqdataformats"
    BINARY_DIR  "${CMAKE_CURRENT_BINARY_DIR}/daqdataformats-build"
    INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/daqdataformats-install"
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

# ── Step 4: build fddetdataformats against daq-cmake + detdataformats ─────────
ExternalProject_Add(
    fddetdataformats_ep
    DEPENDS         daq_cmake_ep detdataformats_ep
    SOURCE_DIR      "${CMAKE_CURRENT_SOURCE_DIR}/cpp_packages/fddetdataformats"
    BINARY_DIR      "${CMAKE_CURRENT_BINARY_DIR}/fddetdataformats-build"
    INSTALL_DIR     "${CMAKE_CURRENT_BINARY_DIR}/fddetdataformats-install"
    # Use | as list separator so semicolons in CMAKE_PREFIX_PATH are not
    # misinterpreted as CMake list separators by ExternalProject_Add.
    LIST_SEPARATOR  |
    CMAKE_ARGS
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        # Provide daq-cmake and detdataformats cmake configs
        "-DCMAKE_PREFIX_PATH=${DAQ_CMAKE_STAGING}|${DETDATAFORMATS_STAGING}"
        # Point directly at the pip-installed pybind11 cmake config
        -Dpybind11_DIR=${PYBIND11_CMAKE_DIR}
        # Force lib/ so the Python install path is predictable
        -DCMAKE_INSTALL_LIBDIR=lib
        -DBUILD_TESTING=OFF
    BUILD_COMMAND   ${CMAKE_COMMAND} --build <BINARY_DIR>
    INSTALL_COMMAND
        ${CMAKE_COMMAND} --install <BINARY_DIR>
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            <INSTALL_DIR>/lib/python
            "${PYTHON_INSTALL_DIR}"
)

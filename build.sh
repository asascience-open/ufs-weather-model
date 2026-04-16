#!/bin/bash
set -eu

SCRIPT_REALPATH=$(realpath "${BASH_SOURCE[0]}")
UFS_MODEL_DIR=$(dirname "${SCRIPT_REALPATH}")
readonly UFS_MODEL_DIR
echo "UFS MODEL DIR: ${UFS_MODEL_DIR}"

export CC=${CC:-mpicc}
export CXX=${CXX:-mpicxx}
export FC=${FC:-mpif90}

BUILD_DIR=${BUILD_DIR:-${UFS_MODEL_DIR}/build}
mkdir -p "${BUILD_DIR}"

cd "${BUILD_DIR}"
ARR_CMAKE_FLAGS=()
for i in ${CMAKE_FLAGS}; do ARR_CMAKE_FLAGS+=("${i}") ; done
cmake "${UFS_MODEL_DIR}" "${ARR_CMAKE_FLAGS[@]}"

# Turn off OpenMP threading for parallel builds
# to avoid exhausting the number of user processes
# OMP_NUM_THREADS=1 make -j "${BUILD_JOBS:-4}" "VERBOSE=${BUILD_VERBOSE:-}"
#
# PT: 'make' doesn't use openmp library, so this doesn't do anything
# PT: to see if make is built with openmp library, use 'ldd <path_to_make>/make'
# PT: Normally, make only uses -j $BUILD_JOBS, not

# This is the more correct way to do it
if [ $(nproc) -eq 1 ]; then
  BUILD_JOBS=1
else
  BUILD_JOBS=$(($(nproc)/2))
fi

make -j "${BUILD_JOBS:-4}" "VERBOSE=${BUILD_VERBOSE:-}"


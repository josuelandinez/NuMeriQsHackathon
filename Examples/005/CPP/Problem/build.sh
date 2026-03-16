#!/bin/bash
set -e

# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8
module load CMake/3.31.8
#Needed to  build with Score-P
module load Score-P/9.4

# Regular build CMake
rm -rf build_regular
# Generate the regular build system in 'build_regular'
CXX=g++ cmake -B build_regular -DCMAKE_BUILD_TYPE=Release
# Compile the regular version
cmake --build build_regular

rm -rf build_profile
# Generate the build system in a folder called 'build_regular'
#enabled with some other profiler / debugger
CXX=g++ cmake -B build_profile -DCMAKE_BUILD_TYPE=Debug
# Compile the profile version
cmake --build build_profile

ldd build_profile/aos_soa

#Score-p build

# For safety set these variables
# Define Score-P compiler wrappers
export SCOREP_CC="scorep-gcc"
export SCOREP_CXX="scorep-g++"
export SCOREP_MPICC="scorep-mpicc"
export SCOREP_MPICXX="scorep-mpicxx"
export SCOREP_CUDA_ENABLE=no # disable cuda support
export SCOREP_WRAPPER_INSTRUMENTER_FLAGS="--thread=omp"


rm -rf build_scorep
#prepend compiler when build it s
#CC="scorep-gcc" CXX="scorep-g++" cmake -B build_scorep -DCMAKE_BUILD_TYPE=Debug
# Generate the build system in a folder called 'build_scorep'
SCOREP_WRAPPER=off cmake -B build_scorep -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_COMPILER=${SCOREP_CXX} \
    -DCMAKE_C_COMPILER=${SCOREP_CC} 
    
# Compile it
cmake --build build_scorep

ldd build_scorep/aos_soa

#!/bin/bash
set -e

# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8
#Needed to  build with Score-P
module load Score-P/9.4

# Regular build 
rm -rf build_regular
make BUILD=release OUT_DIR=build_regular


rm -rf build_profile
#profile build
make BUILD=profile OUT_DIR=build_profile


ldd build_profile/matmul

#Score-p build

# For safety set these variables
# Define Score-P compiler wrappers
export SCOREP_CC="scorep-gcc"
export SCOREP_CXX="scorep-g++"
export SCOREP_MPICC="scorep-mpicc"
export SCOREP_MPICXX="scorep-mpicxx"
export SCOREP_FC="scorep-gfortran"
export SCOREP_MPIFC="scorep-mpif90"

rm -rf build_scorep
#build regular
make FC=${SCOREP_FC} BUILD=profile OUT_DIR=build_scorep

ldd build_scorep/matmul

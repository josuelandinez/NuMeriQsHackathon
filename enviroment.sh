#!/bin/bash

# Load Environment (Stage 2026)
module --force purge
echo "Loading Modules..."
module load Stages/2026
module load GCC/14.3.0
module load OpenMPI/5.0.8
module load CMake/3.31.8
#Needed to  build with Score-P
module load Score-P/9.4
module load VTune/2025.4.0
module load CubeGUI/4.9.1

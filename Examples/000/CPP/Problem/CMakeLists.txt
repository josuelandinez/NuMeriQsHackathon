cmake_minimum_required(VERSION 3.10)
project(MatMul_Profiling)

set(CMAKE_CXX_STANDARD 17)

# Flags to keep debug symbols (Aggresive optimization -O3,  -march=native)
set(CMAKE_CXX_FLAGS_RELEASE "-O3  -march=native")

# Flags for Debugging/Score-P/VTune/Perf (No optimization -O0, Mild optimizaton -O2, Aggressive optimization -O3 (possible heavy inline), keep debug symbols -g, CPU specific optimization -march=native)
#set(CMAKE_CXX_FLAGS_DEBUG "-O2  -march=native -g -fno-omit-frame-pointer")
set(CMAKE_CXX_FLAGS_DEBUG "-O2  -march=native -g -fno-omit-frame-pointer -fno-inline")

# Replace this with whichever file you are compiling
add_executable(matmul matmul.cpp)


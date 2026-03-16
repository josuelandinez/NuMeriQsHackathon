# Usage:
#   make                -> Builds optimized version for VTune/perf
#   make BUILD=scorep   -> Builds debug version wrapped with Score-P

# Default build type
BUILD ?= release

# Source files
SRC = mandelbrot_omp.f90

ifeq ($(BUILD), profile)
    # --- Profile Configuration ---
    FC = gfortran
    # -g for symbols, -O3 for aggresive optimization, -O2 mild optimization, -O0 no optimization 	
    FFLAGS = -g -O2 -march=native -fno-omit-frame-pointer -fopenmp
    OUT_DIR = build_scorep
    TARGET = $(OUT_DIR)/mandelbrot_omp
else
    # --- Regular Configuration ---
    FC = gfortran
    # -march=native (machine specific), -O3 for aggresive optimization, -O2 mild optimization, -O0 no optimization	
    FFLAGS = -O3 -march=native -fopenmp
    OUT_DIR = build_profile
    TARGET = $(OUT_DIR)/mandelbrot_omp
endif

all: $(OUT_DIR) $(TARGET)

# Create the directory if it doesn't exist
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Compile the executable into the chosen directory
$(TARGET): $(SRC)
	$(FC) $(FFLAGS) -o $@ $^

# Clean both directories
clean:
	rm -rf build_regular build_scorep build_profile

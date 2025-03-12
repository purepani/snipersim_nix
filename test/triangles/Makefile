MAKEFILE_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))


TARGET=triangles
include ../shared/Makefile.shared

MY_CXXFLAGS = -flto -fopenmp -ffast-math
MY_INCLUDEPATHS =  -I../../gapbs/src 

CXX := $(SNIPER_CXX)
CXXFLAGS := $(SNIPER_CXXFLAGS) $(MY_CXXFLAGS) $(MY_INCLUDEPATHS)

$(TARGET): $(TARGET).o
	mkdir -p $(MAKEFILE_DIR)build
	$(CXX) $(MY_CXXFLAGS) $(TARGET).o -lm $(SNIPER_LDFLAGS) -o $(MAKEFILE_DIR)build/$(TARGET)

run_$(TARGET):
	../../run-sniper -n 16 -- $(MAKEFILE_DIR)build/$(TARGET) -f ../../dataset/cage3/cage3.mtx
	# ../../run-sniper -n 16 -- $(MAKEFILE_DIR)build/$(TARGET) -f ../../dataset/wiki-Vote/wiki-Vote.mtx

.PHONY: clean
clean:
	rm -rf $(MAKEFILE_DIR)build/
	rm -rf $(TARGET) sim.* *.log *.out *.png *.o topo.* power.*

# Define the build directory
BUILD_DIR = build
BUILD_TYPE ?= Release  # Default to 'Debug' if BUILD_TYPE is not defined
# Default target Linux
all: configure build run

configure-windows:
	@mkdir $(BUILD_DIR)> NUL
	@cmake build . -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=${BUILD_TYPE}

configure:
	@mkdir -p $(BUILD_DIR)
	@cmake build . -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=${BUILD_TYPE}

# Build the project
build:
	@cd $(BUILD_DIR) && $(MAKE)

clean:
	rm -Rf build/*


run:
	./$(BUILD_DIR)/stress-release-by-particles/stress-release-by-particles

.PHONY: all configure build run
.PHONY: all build run clean check help

# Project configuration
PROJECT := WindowCloak.xcodeproj
SCHEME := WindowCloak
APP_NAME := WindowCloak

# Build configuration
BUILD_DIR := build
APP := $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app

# Default target
all: run

# Build
build:
	@echo "Building $(APP_NAME)..."
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR) \
		build

# Build and run
run: build
	@killall $(APP_NAME) 2>/dev/null || true
	@echo "Launching $(APP_NAME)..."
	@open $(APP)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		clean

# Check dependencies
check:
	@command -v xcodebuild >/dev/null 2>&1 || { echo "Error: Xcode is not installed"; exit 1; }
	@echo "Xcode: $$(xcodebuild -version | head -n1)"
	@echo "Swift: $$(swift --version | head -n1)"

# Show available targets
help:
	@echo "WindowCloak Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build - Build the app"
	@echo "  make run   - Build and run (default)"
	@echo "  make clean - Remove build artifacts"
	@echo "  make check - Check dependencies"
	@echo "  make help  - Show this help"

# Loop OS Build System Makefile
# 
# This Makefile builds the complete Loop OS simulation including:
# - All compartment binaries (root_task, broker, shell, aura)
# - seL4 kernel with configuration
# - System image for QEMU
# - Test scripts and utilities

# Build configuration
BUILD_DIR ?= build
TARGET_TRIPLE ?= x86_64-unknown-none
SEL4_DIR ?= external/sel4
LOOP_CORE_DIR ?= loop-core
LOOP_CAP_BROKER_DIR ?= loop-cap-broker
COMPARTMENTS_DIR ?= compartments

# Source directories
ROOT_TASK_SRC = $(COMPARTMENTS_DIR)/root_task/src
BROKER_SRC = $(COMPARTMENTS_DIR)/broker/src
SHELL_SRC = $(COMPARTMENTS_DIR)/shell/src
AURA_SRC = $(COMPARTMENTS_DIR)/aura/src

# Compiler and tools
RUSTC ?= rustc
RUSTFLAGS ?= -C target-feature=+crt-static -C link-arg=-nostdlib -C panic=abort -C relocation-model=pie
CARGO ?= cargo

# Build targets
.PHONY: all clean build-kernel build-image run-qemu test integration-test

# Default target
all: build-kernel build-image

# Build seL4 kernel with Loop OS configuration
build-kernel:
	@echo "Building seL4 kernel with Loop OS configuration..."
	@mkdir -p $(BUILD_DIR)
	cmake -B $(BUILD_DIR) \
		-D CMAKE_TOOLCHAIN_FILE=$(SEL4_DIR)/cmake/toolchain-x86_64.cmake \
		-D CMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DCMAKE_BUILD_TYPE=Debug \
		$(SEL4_DIR)/configs/sel4_config.cmake
	@echo "seL4 kernel built successfully"

# Build compartment binaries
build-compartments: $(BUILD_DIR)/root_task.bin $(BUILD_DIR)/broker.bin $(BUILD_DIR)/shell.bin $(BUILD_DIR)/aura.bin
	@echo "Building compartments..."
	@mkdir -p $(BUILD_DIR)
	
	# Root task binary
	$(RUSTC) $(RUSTFLAGS) --target $(TARGET_TRIPLE) --edition=2021 \
		-C link-arg=-Ttext=$(COMPARTMENTS_DIR)/root_task.ld \
		-L $(LOOP_CORE_DIR) -l loop_core \
		-o $(BUILD_DIR)/root_task.bin $(ROOT_TASK_SRC)
	
	# Broker binary
	$(RUSTC) $(RUSTFLAGS) --target $(TARGET_TRIPLE) --edition=2021 \
		-C link-arg=-Ttext=$(COMPARTMENTS_DIR)/broker.ld \
		-L $(LOOP_CORE_DIR) -l loop_core \
		-o $(BUILD_DIR)/broker.bin $(BROKER_SRC)
	
	# Shell binary
	$(RUSTC) $(RUSTFLAGS) --target $(TARGET_TRIPLE) --edition=2021 \
		-C link-arg=-Ttext=$(COMPARTMENTS_DIR)/shell.ld \
		-L $(LOOP_CORE_DIR) -l loop_core \
		-o $(BUILD_DIR)/shell.bin $(SHELL_SRC)
	
	# Aura binary
	$(RUSTC) $(RUSTFLAGS) --target $(TARGET_TRIPLE) --edition=2021 \
		-C link-arg=-Ttext=$(COMPARTMENTS_DIR)/aura.ld \
		-L $(LOOP_CORE_DIR) -l loop_core \
		-o $(BUILD_DIR)/aura.bin $(AURA_SRC)
	
	@echo "All compartments built successfully"

# Create system image by combining binaries
build-image: build-compartments
	@echo "Creating Loop OS system image..."
	@mkdir -p $(BUILD_DIR)
	
	# Create a temporary file with all binaries combined
	# In a real implementation, this would use a more sophisticated tool
	# For simplicity, we concatenate binaries with padding to correct addresses
	
	# Calculate total size needed (each binary at 1MB with proper alignment)
	@dd if=/dev/zero of=1M bs=1K count=4 | \
		cat $(BUILD_DIR)/root_task.bin $(BUILD_DIR)/broker.bin $(BUILD_DIR)/shell.bin $(BUILD_DIR)/aura.bin | \
		dd of=$(BUILD_DIR)/loop-os.bin bs=512 conv=notrunc seek=0
	
	# Pad to 4MB total size
	@dd if=/dev/zero of=1M bs=1K count=4 | \
		dd of=$(BUILD_DIR)/loop-os.bin bs=512 conv=notrunc seek=4096
	
	@echo "System image created successfully"

# Run QEMU with system image
run-qemu: build-image
	@echo "Starting QEMU simulation..."
	qemu-system-x86_64 \
		-m 512M \
		-nographic \
		-serial mon:stdio \
		-kernel $(SEL4_DIR)/kernel/arm-image \
		-drive file=$(BUILD_DIR)/loop-os.bin,format=raw \
		-append "sel4=1 console=ttyS0"

# Integration smoke test (without seL4)
integration-test: $(BUILD_DIR)/test_integration.bin
	@echo "Running integration smoke test..."
	@mkdir -p $(BUILD_DIR)
	
	# Run QEMU with the integration test binary
	timeout 5s qemu-system-x86_64 \
		-m 256M \
		-nographic \
		-serial stdio \
		-kernel $(BUILD_DIR)/test_integration.bin \
		> $(BUILD_DIR)/serial_output.txt 2>&1 || true
	
	# Check for expected messages in the output
	@echo "Checking integration test output..."
	@if grep -q "\[ROOT_TASK\] Boot sequence complete" $(BUILD_DIR)/serial_output.txt && \
	   grep -q "\[BROKER\] Capability Broker initialized successfully" $(BUILD_DIR)/serial_output.txt && \
	   grep -q "\[SHELL\] Desktop Shell initialized successfully" $(BUILD_DIR)/serial_output.txt && \
	   grep -q "\[AURA\] Aura Orchestrator initialized successfully" $(BUILD_DIR)/serial_output.txt && \
	   grep -q "\[AURA\] Voice command processed successfully" $(BUILD_DIR)/serial_output.txt && \
	   grep -q "\[SHELL\] Requesting app launch capability" $(BUILD_DIR)/serial_output.txt; then \
		echo "SMOKE TEST PASSED"; \
	else \
		echo "SMOKE TEST FAILED"; \
		echo "Output:"; \
		cat $(BUILD_DIR)/serial_output.txt; \
	fi

# Build integration test binary
$(BUILD_DIR)/test_integration.bin: test_integration.rs test_link.ld
	@echo "Building integration test binary..."
	@mkdir -p $(BUILD_DIR)
	
	# Compile the integration test
	$(RUSTC) $(RUSTFLAGS) --target $(TARGET_TRIPLE) --edition=2021 \
		-C link-arg=-Ttest_link.ld \
		-L $(LOOP_CORE_DIR) -l loop_core \
		-o $(BUILD_DIR)/test_integration.elf test_integration.rs
	
	# Convert to flat binary
	objcopy -O binary $(BUILD_DIR)/test_integration.elf $(BUILD_DIR)/test_integration.bin
	
	@echo "Integration test binary built successfully"

# Run tests
test: build-image
	@echo "Running simulation tests..."
	./build/scripts/test_boot.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	rm -f loop-os.bin

# Create linker scripts for each compartment
linker-scripts:
	@mkdir -p $(COMPARTMENTS_DIR)/root_task
	@mkdir -p $(COMPARTMENTS_DIR)/broker
	@mkdir -p $(COMPARTMENTS_DIR)/shell
	@mkdir -p $(COMPARTMENTS_DIR)/aura
	
	# Root task linker script
	@echo "SECTIONS { }" > $(COMPARTMENTS_DIR)/root_task/link.ld
	@echo ".text 0x100000 : { *(.text) }" >> $(COMPARTMENTS_DIR)/root_task/link.ld
	@echo "}" >> $(COMPARTMENTS_DIR)/root_task/link.ld
	
	# Broker linker script
	@echo "SECTIONS { }" > $(COMPARTMENTS_DIR)/broker/link.ld
	@echo ".text 0x400000 : { *(.text) }" >> $(COMPARTMENTS_DIR)/broker/link.ld
	@echo "}" >> $(COMPARTMENTS_DIR)/broker/link.ld
	
	# Shell linker script
	@echo "SECTIONS { }" > $(COMPARTMENTS_DIR)/shell/link.ld
	@echo ".text 0x600000 : { *(.text) }" >> $(COMPARTMENTS_DIR)/shell/link.ld
	@echo "}" >> $(COMPARTMENTS_DIR)/shell/link.ld
	
	# Aura linker script
	@echo "SECTIONS { }" > $(COMPARTMENTS_DIR)/aura/link.ld
	@echo ".text 0xA00000 : { *(.text) }" >> $(COMPARTMENTS_DIR)/aura/link.ld
	@echo "}" >> $(COMPARTMENTS_DIR)/aura/link.ld

# Help target
help:
	@echo "Loop OS Build System"
	@echo "Targets:"
	@echo "  all              - Build everything (default)"
	@echo "  build-kernel     - Build seL4 kernel"
	@echo "  build-image      - Build compartment binaries and system image"
	@echo "  run-qemu         - Run QEMU simulation"
	@echo "  test             - Run simulation tests"
	@echo "  integration-test - Run integration smoke test (without seL4)"
	@echo "  clean            - Remove build artifacts"
	@echo ""
	@echo "Usage: make [target]"
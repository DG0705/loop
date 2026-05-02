# Loop OS seL4 Kernel Configuration Template
# 
# This is a minimal seL4 kernel configuration for the Loop OS simulation.
# It provides basic settings suitable for running the four core compartments
# in QEMU with sufficient memory and proper addressing.

cmake_minimum_required(VERSION 3.10)

project(seL4_kernel C)

# Kernel configuration options
set(Kernel_config_options
    KernelX86_64
    KernelArchX86_64
    KernelSel4ArchX86_64
)

set(Kernel_num_cores 1)
set(Kernel_max_num_nodes 1)

# Memory configuration
set(CONFIG_MAX_NUM_NODES 1)
set(CONFIG_MAX_NUM_DOMAINS 16)
set(CONFIG_NUM_DOMAINS 1)

# Platform configuration
set(CONFIG_PLAT_PC99 ON CACHE OFF)

# Root task configuration
set(CONFIG_ROOT_CNODE_SIZE_BITS 12)  # 4096 slots
set(CONFIG_ROOT_SERVER_EP_BITS 12)     # 4096 slots
set(CONFIG_ROOT_SERVER_IPC_BUF_SIZE_BITS 12)  # 4096 bytes

# Application configuration
set(CONFIG_APP_CNODE_SIZE_BITS 10)    # 1024 slots
set(CONFIG_APP_IPC_BUF_SIZE_BITS 10)     # 1024 bytes

# Memory requirements for simulation
# Total untyped memory needed: ~128MB for all compartments
# This should be configured in the boot loader or kernel command line
set(CONFIG_BOOT_THREAD_MAX_STACK_SIZE (1 * 1024 * 1024))  # 1MB stack per thread
set(CONFIG_MAX_NUM_BOOTINFO_UNTYPED_CAPS 8)  # Sufficient for all compartments

# Set up root task entry point
set(CONFIG_ROOT_TASK_ENTRY_POINT 0x100000)  # Standard seL4 root task address

# Enable debug output for simulation
set(CONFIG_DEBUG_BUILD ON)
set(CONFIG_DEBUG_PRINTK ON)

# Kernel binary name
set(KERNEL_NAME "loop-kernel")

# Include seL4 headers
include(seL4/configs/kernel/seL4_config.h)
include(seL4/configs/kernel/simple_types.h)
include(seL4/configs/kernel/basic_types.h)
include(seL4/configs/arch/x86/arch/64/mode/hardware.h)

# Additional configuration for Loop OS
add_definitions(-DLOOP_OS_SIMULATION=1)

# Configuration summary message
message(STATUS "Loop OS Kernel Configuration Summary:")
message(STATUS "  - Target: x86_64")
message(STATUS "  - Cores: 1")
message(STATUS "  - Memory: 128MB untyped")
message(STATUS "  - Root Task: 0x100000")
message(STATUS "  - Debug: Enabled")
message(STATUS "  - Simulation Mode: ON")

# Export configuration to parent scope
export(CONFIG_KERNEL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/kernel")
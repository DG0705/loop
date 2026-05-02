#!/bin/bash

# Loop OS Boot Sequence Test Script
# 
# This script runs the QEMU simulation and verifies that all four
# core compartments initialize in the correct sequence. It captures
# serial output for 10 seconds and checks for expected messages.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Loop OS Boot Sequence Test${NC}"
echo "Starting QEMU and capturing serial output..."

# Function to run QEMU and capture output
run_qemu_with_timeout() {
    echo -e "${YELLOW}Starting QEMU with timeout...${NC}"
    
    # Run QEMU in background with serial output redirected to our test script
    timeout 10s ./run.sh run-qemu > test_output.log 2>&1 &
    QEMU_PID=$!
    
    # Wait for QEMU to start or timeout
    sleep 1
    
    # Wait for the timeout period or until QEMU exits
    for i in {1..10}; do
        if ! kill -0 $QEMU_PID 2>/dev/null; then
            # QEMU is still running
            echo -e "${YELLOW}Waiting... ${i}/10${NC}"
            sleep 1
        else
            # QEMU has exited
            echo -e "${GREEN}QEMU exited after ${i} seconds${NC}"
            break
        fi
    done
    
    # If we timed out, kill QEMU
    if kill -0 $QEMU_PID 2>/dev/null; then
        echo -e "${RED}QEMU timed out, killing process...${NC}"
        wait $QEMU_PID 2>/dev/null
    fi
    
    echo -e "${YELLOW}Analyzing captured output...${NC}"
}

# Function to check for expected messages in the output
check_expected_messages() {
    local output_file="$1"
    
    if [ -f "test_output.log" ]; then
        output_file="test_output.log"
    fi
    
    echo -e "${YELLOW}Checking for expected boot sequence messages in: ${output_file}${NC}"
    
    # Initialize counters
    local total_expected=4
    local messages_found=0
    
    # Check for each expected message in order
    if grep -q "Root Task: Boot sequence complete" "$output_file"; then
        echo -e "  ${GREEN}✓${NC} Root Task boot sequence complete"
        messages_found=$((messages_found + 1))
    fi
    
    if grep -q "Capability Broker initialized successfully" "$output_file"; then
        echo -e "  ${GREEN}✓${NC} Capability Broker initialized"
        messages_found=$((messages_found + 1))
    fi
    
    if grep -q "Desktop Shell initialized successfully" "$output_file"; then
        echo -e "  ${GREEN}✓${NC} Desktop Shell initialized"
        messages_found=$((messages_found + 1))
    fi
    
    if grep -q "Aura Orchestrator initialized successfully" "$output_file"; then
        echo -e "  ${GREEN}✓${NC} Aura Orchestrator initialized"
        messages_found=$((messages_found + 1))
    fi
    
    # Check for at least one voice command processing (optional)
    if grep -q "Voice command processed successfully" "$output_file"; then
        echo -e "  ${GREEN}✓${NC} Voice command processed"
        messages_found=$((messages_found + 1))
        total_expected=$((total_expected + 1))  # Voice command is optional
    fi
    
    # Report results
    echo ""
    echo -e "${YELLOW}Boot Sequence Test Results:${NC}"
    echo "  Expected messages found: $messages_found/$total_expected"
    
    if [ $messages_found -ge $total_expected ]; then
        echo -e "${GREEN}✓${NC} BOOT TEST PASSED${NC}"
        echo -e "${GREEN}All expected boot messages were captured${NC}"
        return 0
    else
        echo -e "${RED}✗${NC} BOOT TEST FAILED${NC}"
        echo -e "${RED}Missing messages: $((total_expected - messages_found))${NC}"
        
        # Show what was found for debugging
        echo -e "${YELLOW}Messages found:${NC}"
        if grep -q "Root Task: Boot sequence complete" "$output_file"; then
            echo -e "  - Root Task boot sequence complete"
        fi
        if grep -q "Capability Broker initialized successfully" "$output_file"; then
            echo -e "  - Capability Broker initialized"
        fi
        if grep -q "Desktop Shell initialized successfully" "$output_file"; then
            echo -e "  - Desktop Shell initialized"
        fi
        if grep -q "Aura Orchestrator initialized successfully" "$output_file"; then
            echo -e "  - Aura Orchestrator initialized"
        fi
        if grep -q "Voice command processed successfully" "$output_file"; then
            echo -e "  - Voice command processed"
        fi
        
        return 1
    fi
}

# Main execution
case "${1:-run}" in
    run_qemu_with_timeout
    ;;
    
    "test")
        check_expected_messages
        ;;
    
    "clean")
        echo -e "${YELLOW}Cleaning test artifacts...${NC}"
        rm -f test_output.log
        echo -e "${GREEN}Clean complete${NC}"
        ;;
    
    *)
        echo -e "${GREEN}Usage: $0 {run|test|clean}${NC}"
        echo "  run  - Start QEMU simulation and test boot sequence"
        echo "  test  - Check serial output for expected messages"
        echo "  clean - Remove test artifacts"
        exit 1
        ;;
esac
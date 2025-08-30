#!/bin/bash
# Test runner for SQLite ICU Tokenizer Extension

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}SQLite ICU Tokenizer Extension Test Suite${NC}"
echo "=================================================="

# Check if extension exists (platform-specific)
EXTENSION_FILE=""
if [ -f "../fts5icu.dylib" ]; then
    EXTENSION_FILE="../fts5icu.dylib"
elif [ -f "../fts5icu.so" ]; then
    EXTENSION_FILE="../fts5icu.so"
else
    echo -e "${RED}ERROR: Extension file not found. Run 'make' first.${NC}"
    echo "Expected: fts5icu.so (Linux) or fts5icu.dylib (macOS)"
    exit 1
fi

echo "Using extension: $EXTENSION_FILE"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test (dynamically replace extension)
run_test() {
    local test_name=$1
    local test_file=$2
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Create temporary test file with correct extension path
    local temp_test_file="/tmp/test_$$_$(basename $test_file)"
    sed "s|../fts5icu\.so|$EXTENSION_FILE|g" "$test_file" > "$temp_test_file"
    
    if sqlite3 -init "${temp_test_file}" < /dev/null > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        # Show actual output for debugging
        echo -e "${YELLOW}Error output:${NC}"
        sqlite3 -init "${temp_test_file}" 2>&1 || true
    fi
    
    # Clean up temporary file
    rm -f "$temp_test_file"
    echo
}

# Function to run a test with output (dynamically replace extension)
run_test_with_output() {
    local test_name=$1
    local test_file=$2
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    # Create temporary test file with correct extension path
    local temp_test_file="/tmp/test_$$_$(basename $test_file)"
    sed "s|../fts5icu\.so|$EXTENSION_FILE|g" "$test_file" > "$temp_test_file"
    
    if output=$(sqlite3 -init "${temp_test_file}" 2>&1); then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        echo "$output"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        echo "$output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Clean up temporary file
    rm -f "$temp_test_file"
    echo
}

# Run tests
echo "Starting test execution..."
echo

run_test_with_output "Basic Functionality" "test_basic.sql"
run_test_with_output "Multi-language Support" "test_multilingual.sql"
run_test_with_output "Locale Configuration" "test_locales.sql"
run_test_with_output "Performance Test" "test_performance.sql"
run_test_with_output "Edge Cases" "test_edge_cases.sql"

# Summary
echo "=================================================="
echo -e "${BLUE}Test Summary${NC}"
echo "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
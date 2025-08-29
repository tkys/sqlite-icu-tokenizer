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

# Check if extension exists
if [ ! -f "../fts5icu.so" ]; then
    echo -e "${RED}ERROR: fts5icu.so not found. Run 'make' first.${NC}"
    exit 1
fi

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_file=$2
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if sqlite3 -init "${test_file}" < /dev/null > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        # Show actual output for debugging
        echo -e "${YELLOW}Error output:${NC}"
        sqlite3 -init "${test_file}" 2>&1 || true
    fi
    echo
}

# Function to run a test with output
run_test_with_output() {
    local test_name=$1
    local test_file=$2
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if output=$(sqlite3 -init "${test_file}" 2>&1); then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        echo "$output"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        echo "$output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
}

# Run tests
echo "Starting test execution..."
echo

run_test_with_output "Basic Functionality" "test_basic.sql"
run_test_with_output "Multi-language Support" "test_multilingual.sql"
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
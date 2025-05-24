#!/bin/zsh

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'
NORMAL='\033[0m'

# Test configuration
TEST_DIR="$HOME/.mgsh-test"
ORIGINAL_MGSH_DIR="$HOME/.mgsh"
SCRIPT_PATH="../main.sh"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test setup
setup_test_environment() {
    echo "${BLUE}${BOLD}Setting up test environment...${NORMAL}${NC}"
    
    # Backup existing mgsh directory if it exists
    if [ -d "$ORIGINAL_MGSH_DIR" ]; then
        mv "$ORIGINAL_MGSH_DIR" "${ORIGINAL_MGSH_DIR}.backup"
    fi
    
    mkdir -p "$TEST_DIR/connections/dev"
    mkdir -p "$TEST_DIR/connections/prod"
    mkdir -p "$TEST_DIR/connections/personal"
    
    # Create a symlink to make mgsh use our test directory
    ln -s "$TEST_DIR" "$ORIGINAL_MGSH_DIR"
    
    # Create test connections
    echo "mongodb://test-dev-connection" > "$TEST_DIR/connections/dev/testapp"
    echo "mongodb://test-prod-connection" > "$TEST_DIR/connections/prod/mainapp"
    echo "mongodb://personal-connection" > "$TEST_DIR/connections/personal/mydb"
    
    echo "${GREEN}Test environment setup complete${NC}"
}

# Test teardown
teardown_test_environment() {
    echo "${BLUE}${BOLD}Cleaning up test environment...${NORMAL}${NC}"
    
    # Remove test symlink
    rm -f "$ORIGINAL_MGSH_DIR"
    
    # Remove test directory
    rm -rf "$TEST_DIR"
    
    # Restore original mgsh directory if it existed
    if [ -d "${ORIGINAL_MGSH_DIR}.backup" ]; then
        mv "${ORIGINAL_MGSH_DIR}.backup" "$ORIGINAL_MGSH_DIR"
    fi
    
    echo "${GREEN}Test environment cleaned up${NC}"
}

# Test utility functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$expected" = "$actual" ]; then
        echo "${GREEN}✓ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

assert_contains() {
    local substring="$1"
    local text="$2"
    local test_name="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [[ "$text" == *"$substring"* ]]; then
        echo "${GREEN}✓ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected substring: $substring"
        echo "  In text: $text"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local test_name="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$expected_code" = "$actual_code" ]; then
        echo "${GREEN}✓ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected exit code: $expected_code"
        echo "  Actual exit code: $actual_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test functions
test_help_command() {
    echo "${YELLOW}${BOLD}Testing help command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" 2>&1)
    local exit_code=$?
    
    assert_contains "mgsh [command] [options]" "$output" "Help shows usage"
    assert_contains "Commands:" "$output" "Help shows commands section"
}

test_list_command() {
    echo "${YELLOW}${BOLD}Testing list command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" list 2>&1)
    local exit_code=$?
    
    assert_contains "dev/testapp" "$output" "List shows dev/testapp connection"
    assert_contains "prod/mainapp" "$output" "List shows prod/mainapp connection"
    assert_contains "personal/mydb" "$output" "List shows personal/mydb connection"
    assert_exit_code "0" "$exit_code" "List command exits with code 0"
    
    local dev_output=$(zsh "$SCRIPT_PATH" list dev 2>&1)
    assert_contains "testapp" "$dev_output" "List dev shows testapp"
    
    local invalid_output=$(zsh "$SCRIPT_PATH" list invalid 2>&1)
    assert_contains "Invalid namespace" "$invalid_output" "List invalid namespace shows error"
}

test_get_command() {
    echo "${YELLOW}${BOLD}Testing get command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" get dev/testapp 2>&1)
    local exit_code=$?
    
    assert_contains "Connection string copied to clipboard" "$output" "Get command shows success message"
    assert_exit_code "0" "$exit_code" "Get command exits with code 0"
    
    local output_nonexist=$(zsh "$SCRIPT_PATH" get dev/nonexistent 2>&1)
    local exit_code_nonexist=$?
    
    assert_contains "No connection found" "$output_nonexist" "Get non-existing connection shows error"
    assert_exit_code "0" "$exit_code_nonexist" "Get non-existing connection exits with code 0"
    
    local output_invalid=$(zsh "$SCRIPT_PATH" get invalidformat 2>&1)
    assert_contains "Invalid connection format" "$output_invalid" "Get invalid format shows error"
}

test_create_command() {
    echo "${YELLOW}${BOLD}Testing create command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" create dev/newapp "mongodb://new-connection" 2>&1)
    local exit_code=$?
    
    assert_contains "Connection created successfully" "$output" "Create command shows success"
    assert_exit_code "0" "$exit_code" "Create command exits with code 0"
    
    local verify_output=$(zsh "$SCRIPT_PATH" list dev 2>&1)
    assert_contains "newapp" "$verify_output" "Created connection appears in list"
    
    local output_exist=$(zsh "$SCRIPT_PATH" create dev/testapp "mongodb://duplicate" 2>&1)
    assert_contains "Connection already exists" "$output_exist" "Create existing connection shows error"
    
    local output_invalid=$(zsh "$SCRIPT_PATH" create invalidformat "mongodb://test" 2>&1)
    assert_contains "Invalid connection format" "$output_invalid" "Create invalid format shows error"
    
    local output_empty=$(zsh "$SCRIPT_PATH" create dev/empty 2>&1)
    assert_contains "No connection string provided" "$output_empty" "Create without connection string shows error"
}

test_update_command() {
    echo "${YELLOW}${BOLD}Testing update command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" update dev/testapp "mongodb://updated-connection" 2>&1)
    local exit_code=$?
    
    assert_contains "Connection updated successfully" "$output" "Update command shows success"
    assert_exit_code "0" "$exit_code" "Update command exits with code 0"
    
    local output_nonexist=$(zsh "$SCRIPT_PATH" update dev/nonexistent "mongodb://test" 2>&1)
    assert_contains "No connection found" "$output_nonexist" "Update non-existing connection shows error"
    
    local output_invalid=$(zsh "$SCRIPT_PATH" update invalidformat "mongodb://test" 2>&1)
    assert_contains "Invalid connection format" "$output_invalid" "Update invalid format shows error"
}

test_delete_command() {
    echo "${YELLOW}${BOLD}Testing delete command...${NORMAL}${NC}"
    
    local output=$(zsh "$SCRIPT_PATH" delete personal/mydb 2>&1)
    local exit_code=$?
    
    assert_contains "Connection deleted successfully" "$output" "Delete command shows success"
    assert_exit_code "0" "$exit_code" "Delete command exits with code 0"
    
    local verify_output=$(zsh "$SCRIPT_PATH" list personal 2>&1)
    if [[ "$verify_output" == *"mydb"* ]]; then
        echo "${RED}✗ FAIL${NC}: Deleted connection still appears in list"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    else
        echo "${GREEN}✓ PASS${NC}: Deleted connection removed from list"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local output_nonexist=$(zsh "$SCRIPT_PATH" delete dev/nonexistent 2>&1)
    assert_contains "No connection found" "$output_nonexist" "Delete non-existing connection shows error"
}

# Main test runner
run_tests() {
    echo "${BLUE}${BOLD}Starting mgsh tests...${NORMAL}${NC}"
    echo "Script path: $SCRIPT_PATH"
    echo ""
    
    setup_test_environment
    echo ""
    
    # Run all tests
    test_help_command
    echo ""
    test_list_command
    echo ""
    test_get_command
    echo ""
    test_create_command
    echo ""
    test_update_command
    echo ""
    test_delete_command
    echo ""
    
    teardown_test_environment
    echo ""
    
    # Print summary
    echo "${BLUE}${BOLD}Test Summary:${NORMAL}${NC}"
    echo "Total tests: $TOTAL_TESTS"
    echo "${GREEN}Passed: $PASSED_TESTS${NC}"
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "${RED}Failed: $FAILED_TESTS${NC}"
    fi
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo "${GREEN}${BOLD}All tests passed! ✓${NORMAL}${NC}"
        exit 0
    else
        echo "${RED}${BOLD}Some tests failed! ✗${NORMAL}${NC}"
        exit 1
    fi
}

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "${RED}Error: Script $SCRIPT_PATH not found${NC}"
    exit 1
fi

run_tests 
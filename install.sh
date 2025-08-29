#!/bin/bash
# SQLite ICU Tokenizer Extension Installation Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="/usr/local/lib"
BIN_DIR="/usr/local/bin"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for required tools
    local missing_deps=()
    
    if ! command_exists gcc; then
        missing_deps+=("gcc")
    fi
    
    if ! command_exists make; then
        missing_deps+=("make")
    fi
    
    if ! command_exists pkg-config; then
        missing_deps+=("pkg-config")
    fi
    
    if ! command_exists sqlite3; then
        missing_deps+=("sqlite3")
    fi
    
    # Check ICU libraries
    if ! pkg-config --exists icu-uc icu-i18n 2>/dev/null; then
        missing_deps+=("libicu-dev")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "On Ubuntu/Debian, install with:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install build-essential libicu-dev sqlite3"
        return 1
    fi
    
    print_success "All dependencies are satisfied"
    return 0
}

# Function to build the extension
build_extension() {
    print_info "Building SQLite ICU tokenizer extension..."
    
    if [ ! -f "Makefile" ]; then
        print_error "Makefile not found. Please run from project root directory."
        return 1
    fi
    
    # Clean and build
    make clean >/dev/null 2>&1 || true
    if ! make; then
        print_error "Build failed"
        return 1
    fi
    
    if [ ! -f "fts5icu.so" ]; then
        print_error "Extension library not found after build"
        return 1
    fi
    
    print_success "Extension built successfully"
    return 0
}

# Function to run tests
run_tests() {
    print_info "Running test suite..."
    
    if ! make test; then
        print_warning "Some tests failed, but installation will continue"
        return 0
    fi
    
    print_success "All tests passed"
    return 0
}

# Function to install the extension
install_extension() {
    print_info "Installing extension to $INSTALL_DIR..."
    
    # Create installation directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Creating installation directory: $INSTALL_DIR"
        sudo mkdir -p "$INSTALL_DIR"
    fi
    
    # Copy the extension library
    sudo cp fts5icu.so "$INSTALL_DIR/"
    sudo chmod 755 "$INSTALL_DIR/fts5icu.so"
    
    # Update library cache
    if command_exists ldconfig; then
        sudo ldconfig
    fi
    
    print_success "Extension installed to $INSTALL_DIR/fts5icu.so"
}

# Function to create a wrapper script
create_wrapper() {
    local wrapper_script="$BIN_DIR/sqlite3-icu"
    
    print_info "Creating wrapper script: $wrapper_script"
    
    sudo tee "$wrapper_script" >/dev/null <<EOF
#!/bin/bash
# SQLite3 with ICU tokenizer extension pre-loaded

EXTENSION_PATH="$INSTALL_DIR/fts5icu.so"

if [ ! -f "\$EXTENSION_PATH" ]; then
    echo "Error: ICU extension not found at \$EXTENSION_PATH"
    exit 1
fi

# If no arguments, start interactive mode with extension loaded
if [ \$# -eq 0 ]; then
    sqlite3 -cmd ".load \$EXTENSION_PATH sqlite3_icufts5_init"
else
    # Pass through all arguments, but preload extension
    sqlite3 -cmd ".load \$EXTENSION_PATH sqlite3_icufts5_init" "\$@"
fi
EOF

    sudo chmod +x "$wrapper_script"
    print_success "Wrapper script created at $wrapper_script"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    # Test loading the extension
    local test_result
    test_result=$(echo ".load $INSTALL_DIR/fts5icu.so sqlite3_icufts5_init
CREATE VIRTUAL TABLE test USING fts5(content, tokenize='icu');
INSERT INTO test(content) VALUES ('テスト');
SELECT * FROM test WHERE test MATCH 'テスト';
.quit" | sqlite3 2>/dev/null)
    
    if [[ "$test_result" == *"テスト"* ]]; then
        print_success "Installation verified successfully"
        return 0
    else
        print_error "Installation verification failed"
        return 1
    fi
}

# Function to show usage information
show_usage() {
    print_success "Installation completed successfully!"
    echo ""
    echo "Usage:"
    echo "1. Load extension in SQLite:"
    echo "   sqlite3"
    echo "   .load $INSTALL_DIR/fts5icu.so sqlite3_icufts5_init"
    echo ""
    echo "2. Use the wrapper script (recommended):"
    echo "   sqlite3-icu"
    echo ""
    echo "3. Create tables with ICU tokenizer:"
    echo "   CREATE VIRTUAL TABLE docs USING fts5(content, tokenize='icu');"
    echo "   CREATE VIRTUAL TABLE docs_zh USING fts5(content, tokenize='icu zh');"
    echo ""
    echo "For more information, see README.md or visit:"
    echo "https://github.com/tkys/sqlite-icu-tokenizer"
}

# Function to uninstall
uninstall() {
    print_info "Uninstalling SQLite ICU tokenizer extension..."
    
    # Remove extension library
    if [ -f "$INSTALL_DIR/fts5icu.so" ]; then
        sudo rm -f "$INSTALL_DIR/fts5icu.so"
        print_success "Extension library removed"
    fi
    
    # Remove wrapper script
    if [ -f "$BIN_DIR/sqlite3-icu" ]; then
        sudo rm -f "$BIN_DIR/sqlite3-icu"
        print_success "Wrapper script removed"
    fi
    
    print_success "Uninstall completed"
}

# Main function
main() {
    echo "SQLite ICU Tokenizer Extension Installer"
    echo "========================================"
    
    # Parse command line arguments
    case "${1:-install}" in
        install)
            check_dependencies || exit 1
            build_extension || exit 1
            run_tests
            install_extension || exit 1
            create_wrapper || exit 1
            verify_installation || exit 1
            show_usage
            ;;
        uninstall)
            uninstall
            ;;
        build-only)
            check_dependencies || exit 1
            build_extension || exit 1
            run_tests
            print_success "Build completed. Run 'sudo ./install.sh install' to install."
            ;;
        test)
            check_dependencies || exit 1
            if [ ! -f "fts5icu.so" ]; then
                build_extension || exit 1
            fi
            run_tests
            ;;
        *)
            echo "Usage: $0 [install|uninstall|build-only|test]"
            echo ""
            echo "Commands:"
            echo "  install     - Build, test and install the extension (default)"
            echo "  uninstall   - Remove installed extension and wrapper"
            echo "  build-only  - Build and test without installing"
            echo "  test        - Run test suite only"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
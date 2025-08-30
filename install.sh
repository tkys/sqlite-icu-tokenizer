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

# Function to compare version numbers (returns 0 if version1 >= version2)
version_compare() {
    local version1="$1"
    local version2="$2"
    
    # Remove any non-numeric suffixes
    version1=$(echo "$version1" | sed 's/[^0-9.].*//')
    version2=$(echo "$version2" | sed 's/[^0-9.].*//')
    
    # Use sort -V to compare versions
    if printf '%s\n' "$version2" "$version1" | sort -V -C 2>/dev/null; then
        return 0  # version1 >= version2
    else
        return 1  # version1 < version2
    fi
}

# Function to detect OS and package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif command_exists lsb_release; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VER=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="redhat"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    
    print_info "Detected OS: $OS $VER"
}

# Function to install dependencies automatically
install_dependencies() {
    local missing_deps=("$@")
    
    print_info "Installing missing dependencies: ${missing_deps[*]}"
    
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update -qq
            case "${missing_deps[*]}" in
                *gcc*) sudo apt-get install -y build-essential ;;
            esac
            case "${missing_deps[*]}" in
                *libicu-dev*) sudo apt-get install -y libicu-dev ;;
            esac
            case "${missing_deps[*]}" in
                *sqlite3*) sudo apt-get install -y sqlite3 ;;
            esac
            case "${missing_deps[*]}" in
                *pkg-config*) sudo apt-get install -y pkg-config ;;
            esac
            ;;
        centos|rhel|fedora)
            if command_exists dnf; then
                PKG_MGR="dnf"
            else
                PKG_MGR="yum"
            fi
            case "${missing_deps[*]}" in
                *gcc*) sudo $PKG_MGR install -y gcc make ;;
            esac
            case "${missing_deps[*]}" in
                *libicu-dev*) sudo $PKG_MGR install -y libicu-devel ;;
            esac
            case "${missing_deps[*]}" in
                *sqlite3*) sudo $PKG_MGR install -y sqlite ;;
            esac
            case "${missing_deps[*]}" in
                *pkg-config*) sudo $PKG_MGR install -y pkgconfig ;;
            esac
            ;;
        arch)
            case "${missing_deps[*]}" in
                *gcc*) sudo pacman -S --noconfirm base-devel ;;
            esac
            case "${missing_deps[*]}" in
                *libicu-dev*) sudo pacman -S --noconfirm icu ;;
            esac
            case "${missing_deps[*]}" in
                *sqlite3*) sudo pacman -S --noconfirm sqlite ;;
            esac
            case "${missing_deps[*]}" in
                *pkg-config*) sudo pacman -S --noconfirm pkgconf ;;
            esac
            ;;
        darwin)
            if ! command_exists brew; then
                print_error "Homebrew not found. Please install Homebrew first:"
                echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                return 1
            fi
            
            # Install dependencies
            local brew_packages=()
            case "${missing_deps[*]}" in
                *gcc*) brew_packages+=(gcc) ;;
            esac
            case "${missing_deps[*]}" in
                *libicu-dev*) brew_packages+=(icu4c) ;;
            esac
            case "${missing_deps[*]}" in
                *sqlite3*) brew_packages+=(sqlite) ;;
            esac
            case "${missing_deps[*]}" in
                *pkg-config*) brew_packages+=(pkg-config) ;;
            esac
            
            if [ ${#brew_packages[@]} -gt 0 ]; then
                brew install "${brew_packages[@]}"
            fi
            
            # Set up ICU environment for macOS (both Intel and Apple Silicon)
            local icu_prefix
            if [ -d "/opt/homebrew/opt/icu4c" ]; then
                # Apple Silicon path
                icu_prefix="/opt/homebrew/opt/icu4c"
            elif [ -d "/usr/local/opt/icu4c" ]; then
                # Intel Mac path
                icu_prefix="/usr/local/opt/icu4c"
            fi
            
            if [ -n "$icu_prefix" ]; then
                export PKG_CONFIG_PATH="$icu_prefix/lib/pkgconfig:$PKG_CONFIG_PATH"
                export LDFLAGS="-L$icu_prefix/lib $LDFLAGS"
                export CPPFLAGS="-I$icu_prefix/include $CPPFLAGS"
                print_info "ICU configured at: $icu_prefix"
            fi
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_info "Please install dependencies manually:"
            echo "  - C compiler (gcc/clang)"
            echo "  - make"
            echo "  - pkg-config"  
            echo "  - sqlite3"
            echo "  - ICU development libraries"
            return 1
            ;;
    esac
    
    print_success "Dependencies installed successfully"
}

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Detect OS first
    detect_os
    
    # Check for required tools
    local missing_deps=()
    
    if ! command_exists gcc && ! command_exists clang; then
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
    else
        # Check SQLite version for FTS5 support
        local sqlite_version
        sqlite_version=$(sqlite3 --version | cut -d' ' -f1)
        local required_version="3.35.0"
        
        if ! version_compare "$sqlite_version" "$required_version"; then
            print_warning "SQLite version $sqlite_version found, but $required_version+ required for FTS5"
            print_info "Consider upgrading SQLite or the extension may not work properly"
        fi
    fi
    
    # Check ICU libraries
    if ! pkg-config --exists icu-uc icu-i18n 2>/dev/null; then
        missing_deps+=("libicu-dev")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warning "Missing dependencies: ${missing_deps[*]}"
        
        # Ask user if they want automatic installation
        echo ""
        read -p "Install missing dependencies automatically? [Y/n]: " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Manual installation required:"
            case "$OS" in
                ubuntu|debian)
                    echo "  sudo apt-get update"
                    echo "  sudo apt-get install build-essential libicu-dev sqlite3 pkg-config"
                    ;;
                centos|rhel|fedora)
                    echo "  sudo yum install gcc make libicu-devel sqlite pkgconfig"
                    ;;
                arch)
                    echo "  sudo pacman -S base-devel icu sqlite pkgconf"
                    ;;
                darwin)
                    echo "  brew install gcc icu4c sqlite pkg-config"
                    ;;
            esac
            return 1
        else
            install_dependencies "${missing_deps[@]}" || return 1
        fi
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
    
    # Check if already built and skip if possible
    if [ -f "fts5icu.so" ] && [ -f "fts5icu.c" ]; then
        if [ "fts5icu.so" -nt "fts5icu.c" ]; then
            print_info "Extension already built and up-to-date"
            return 0
        fi
    fi
    
    # Clean and build with parallel jobs
    make clean >/dev/null 2>&1 || true
    
    # Detect number of CPU cores for parallel build
    local jobs=1
    if command_exists nproc; then
        jobs=$(nproc)
    elif command_exists sysctl; then
        jobs=$(sysctl -n hw.ncpu 2>/dev/null || echo "1")
    fi
    
    print_info "Building with $jobs parallel jobs..."
    
    if ! make -j"$jobs"; then
        print_warning "Parallel build failed, trying single-threaded build..."
        make clean >/dev/null 2>&1 || true
        if ! make; then
            print_error "Build failed"
            return 1
        fi
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
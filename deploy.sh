#!/bin/bash

# Deployment Script for Yatırım Rehberi
# This script helps with building and deploying the app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_success "Flutter found: $(flutter --version | head -n 1)"
}

# Clean build
clean_build() {
    print_header "Cleaning Build"
    flutter clean
    flutter pub get
    print_success "Build cleaned"
}

# Build iOS
build_ios() {
    print_header "Building iOS"
    
    # Check if on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "iOS build requires macOS"
        return 1
    fi
    
    flutter build ios --release
    print_success "iOS build complete"
    print_warning "Next: Open ios/Runner.xcworkspace in Xcode and archive"
}

# Build Android APK
build_android_apk() {
    print_header "Building Android APK"
    
    flutter build apk --release
    
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        print_success "APK built successfully"
        echo -e "Location: ${GREEN}build/app/outputs/flutter-apk/app-release.apk${NC}"
        
        # Get file size
        SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
        echo -e "Size: ${BLUE}$SIZE${NC}"
    else
        print_error "APK build failed"
        return 1
    fi
}

# Build Android App Bundle
build_android_bundle() {
    print_header "Building Android App Bundle"
    
    # Check if keystore exists
    if [ ! -f "android/key.properties" ]; then
        print_error "android/key.properties not found!"
        print_warning "Please create keystore first. See ANDROID_SIGNING_GUIDE.md"
        return 1
    fi
    
    flutter build appbundle --release
    
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        print_success "App Bundle built successfully"
        echo -e "Location: ${GREEN}build/app/outputs/bundle/release/app-release.aab${NC}"
        
        # Get file size
        SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
        echo -e "Size: ${BLUE}$SIZE${NC}"
        
        print_warning "Ready to upload to Google Play Console"
    else
        print_error "App Bundle build failed"
        return 1
    fi
}

# Verify Android signing
verify_android_signing() {
    print_header "Verifying Android Signing"
    
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
        print_success "App Bundle signature verified"
    elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
        print_success "APK signature verified"
    else
        print_error "No release build found to verify"
        return 1
    fi
}

# Run tests
run_tests() {
    print_header "Running Tests"
    flutter test
    print_success "Tests passed"
}

# Check version
check_version() {
    print_header "Current Version"
    VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //')
    echo -e "Version: ${GREEN}$VERSION${NC}"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Yatırım Rehberi Deployment Tool     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    
    echo "1) Clean Build"
    echo "2) Build iOS"
    echo "3) Build Android APK"
    echo "4) Build Android App Bundle (Play Store)"
    echo "5) Verify Android Signing"
    echo "6) Run Tests"
    echo "7) Check Version"
    echo "8) Full iOS Deployment"
    echo "9) Full Android Deployment"
    echo "0) Exit"
    echo ""
}

# Full iOS deployment
full_ios_deployment() {
    print_header "Full iOS Deployment"
    clean_build
    run_tests
    build_ios
    print_success "iOS deployment ready"
    print_warning "Next steps:"
    echo "1. Open ios/Runner.xcworkspace in Xcode"
    echo "2. Select 'Any iOS Device' as destination"
    echo "3. Product → Archive"
    echo "4. Distribute to App Store Connect"
}

# Full Android deployment
full_android_deployment() {
    print_header "Full Android Deployment"
    clean_build
    run_tests
    build_android_bundle
    verify_android_signing
    print_success "Android deployment ready"
    print_warning "Next steps:"
    echo "1. Go to Google Play Console"
    echo "2. Upload build/app/outputs/bundle/release/app-release.aab"
    echo "3. Fill in release notes"
    echo "4. Submit for review"
}

# Main script
main() {
    check_flutter
    check_version
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        while true; do
            show_menu
            read -p "Select option: " choice
            
            case $choice in
                1) clean_build ;;
                2) build_ios ;;
                3) build_android_apk ;;
                4) build_android_bundle ;;
                5) verify_android_signing ;;
                6) run_tests ;;
                7) check_version ;;
                8) full_ios_deployment ;;
                9) full_android_deployment ;;
                0) print_success "Goodbye!"; exit 0 ;;
                *) print_error "Invalid option" ;;
            esac
            
            read -p "Press Enter to continue..."
        done
    else
        # Command line mode
        case $1 in
            clean) clean_build ;;
            ios) build_ios ;;
            apk) build_android_apk ;;
            bundle) build_android_bundle ;;
            verify) verify_android_signing ;;
            test) run_tests ;;
            version) check_version ;;
            ios-full) full_ios_deployment ;;
            android-full) full_android_deployment ;;
            *)
                echo "Usage: $0 [clean|ios|apk|bundle|verify|test|version|ios-full|android-full]"
                exit 1
                ;;
        esac
    fi
}

main "$@"

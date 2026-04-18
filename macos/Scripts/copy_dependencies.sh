#!/bin/bash

# Find SRT library
SRT_LIB=$(find /opt/homebrew/lib -name "libsrt.1.5.dylib" 2>/dev/null | head -1)

if [ -n "$SRT_LIB" ]; then
    echo "Found SRT library: $SRT_LIB"
    
    # Create Frameworks directory if it doesn't exist
    mkdir -p "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks"
    
    # Copy the library
    cp "$SRT_LIB" "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks/"
    
    # Update library paths in the frameworks that need it
    install_name_tool -change "/opt/homebrew/lib/libsrt.1.5.dylib" \
        "@loader_path/../libsrt.1.5.dylib" \
        "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks/libavcodec.framework/Versions/A/libavcodec"
    
    install_name_tool -change "/opt/homebrew/lib/libsrt.1.5.dylib" \
        "@loader_path/../libsrt.1.5.dylib" \
        "$BUILT_PRODUCTS_DIR/$PRODUCT_NAME.app/Contents/Frameworks/libavdevice.framework/Versions/A/libavdevice"
    
    echo "SRT library bundled successfully"
else
    echo "Warning: SRT library not found. Installing via Homebrew..."
    brew install srt
fi
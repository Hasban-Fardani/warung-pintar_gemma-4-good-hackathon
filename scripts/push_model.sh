#!/bin/bash
set -e

MODEL_FILE="gemma-4-E2B-it.litertlm"
SOURCE="$HOME/Downloads/$MODEL_FILE"
# Direct Downloads folder path
DEST="/storage/emulated/0/Download/$MODEL_FILE"

if [ ! -f "$SOURCE" ]; then
    echo "ERROR: Model not found at $SOURCE"
    echo "Please download gemma-4-E2B-it.litertlm to ~/Downloads/ first"
    exit 1
fi

SOURCE_SIZE=$(stat -f%z "$SOURCE" 2>/dev/null || stat -c%s "$SOURCE" 2>/dev/null)
echo "Source: $SOURCE ($SOURCE_SIZE bytes)"

# Check if already on device with same size
if adb shell test -f "$DEST" 2>/dev/null; then
    DEST_SIZE=$(adb shell stat -c%s "$DEST" 2>/dev/null || echo "0")
    echo "Device already has: $DEST ($DEST_SIZE bytes)"
    if [ "$DEST_SIZE" = "$SOURCE_SIZE" ]; then
        echo "Size matches, skipping push"
        exit 0
    else
        echo "Size differs, re-pushing..."
    fi
else
    echo "Pushing to $DEST..."
fi

echo "This may take a few minutes for 2.5GB..."
adb push "$SOURCE" "$DEST"

echo "Done! Model ready at $DEST"

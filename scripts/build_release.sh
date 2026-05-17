#!/bin/bash
# WarungPintar Cimahi — Release APK Build Script (ACT-113)
# Usage: chmod +x scripts/build_release.sh && ./scripts/build_release.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=== WarungPintar Cimahi — Release Build ==="

echo "[1/4] Cleaning..."
flutter clean && flutter pub get

echo "[2/4] Analyzing..."
flutter analyze || { echo "❌ Analysis failed"; exit 1; }

echo "[3/4] Testing..."
flutter test || { echo "❌ Tests failed"; exit 1; }

echo "[4/4] Building APK..."
flutter build apk \
    --release \
    --obfuscate \
    --split-debug-info=build/debug-info \
    --target-platform android-arm64

APK="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK" ]; then
    echo "✅ APK: $APK ($(du -h "$APK" | cut -f1))"
    echo "🔒 Debug info: build/debug-info/"
else
    echo "❌ APK not found"; exit 1
fi

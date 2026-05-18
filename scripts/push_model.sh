#!/bin/bash

MODEL_NAME="gemma-4-E2B-it.litertlm"
LOCAL_PATH="$HOME/Downloads/$MODEL_NAME"
ANDROID_PATH="/sdcard/Download/$MODEL_NAME"

echo "🔍 Checking local model..."

if [ ! -f "$LOCAL_PATH" ]; then
  echo "❌ Model not found at $LOCAL_PATH"
  echo "   Download dulu dari HuggingFace ke ~/Downloads/"
  exit 1
fi

echo "📱 Checking ADB connection..."
if ! adb devices | grep -q "device$"; then
  echo "❌ No Android device connected"
  exit 1
fi

# Cek apakah model sudah ada di device dan ukurannya sama
LOCAL_SIZE=$(stat -f%z "$LOCAL_PATH" 2>/dev/null || stat -c%s "$LOCAL_PATH")
REMOTE_SIZE=$(adb shell stat -c%s "$ANDROID_PATH" 2>/dev/null || echo "0")

if [ "$LOCAL_SIZE" = "$REMOTE_SIZE" ]; then
  echo "✅ Model already on device (size match: $LOCAL_SIZE bytes), skipping push"
  exit 0
fi

echo "⬆️  Pushing model to device ($((LOCAL_SIZE / 1024 / 1024)) MB)..."
adb push "$LOCAL_PATH" "$ANDROID_PATH"

if [ $? -eq 0 ]; then
  echo "✅ Model pushed successfully to $ANDROID_PATH"
else
  echo "❌ Push failed"
  exit 1
fi
#!/bin/bash

MODEL_SRC="/Users/antonioperez/Desktop/hasban/sampingan/warung_pintar_cimahi/gemma_model/gemma-4-E2B-it.litertlm"
PACKAGE="com.example.warung_pintar_cimahi"
DEVICE="0O14219I22103DF3"  # USB device — lebih stabil dari WiFi ADB

echo "Using device: $DEVICE"

echo "Creating models directory..."
adb -s $DEVICE shell run-as $PACKAGE mkdir -p app_flutter/models

echo "Pushing model (2.59GB)..."
adb -s $DEVICE push "$MODEL_SRC" /sdcard/gemma-4-E2B-it.litertlm

echo "Moving to app directory..."
adb -s $DEVICE shell run-as $PACKAGE cp /sdcard/gemma-4-E2B-it.litertlm app_flutter/models/gemma-4-E2B-it.litertlm

echo "Cleaning sdcard..."
adb -s $DEVICE shell rm /sdcard/gemma-4-E2B-it.litertlm

echo "Verifying..."
adb -s $DEVICE shell run-as $PACKAGE ls -lh app_flutter/models/

echo "Done. Kill and restart the app."
#!/bin/bash
set -e

echo "Building GhostFinisher..."

swiftc \
  -target arm64-apple-macosx13.0 \
  -framework Cocoa \
  -framework ApplicationServices \
  -framework ServiceManagement \
  Sources/GhostFinisher.swift \
  -o GhostFinisher

echo "Bundling .app..."
rm -rf GhostFinisher.app
mkdir -p GhostFinisher.app/Contents/MacOS
cp GhostFinisher GhostFinisher.app/Contents/MacOS/
cp Info.plist GhostFinisher.app/Contents/

echo ""
echo "Done — GhostFinisher.app is ready."
echo ""
echo "To install:"
echo "  cp -r GhostFinisher.app /Applications/"
echo "  open /Applications/GhostFinisher.app"
echo ""
echo "Then allow Input Monitoring in System Settings when prompted."

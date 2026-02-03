#!/bin/bash

set -e

REPO="atpugvaraa/quickly"
QUICKLY_DIR="/opt/quickly"
BIN_DIR="/usr/local/bin"
BINARY_NAME="ql"

echo "Installing quickly..."
echo "Running this script will ask for sudo permissions to allow quickly to run without any issues."

# 1. Setup Directories
if [ ! -d "$QUICKLY_DIR" ]; then
    echo "Creating global store at $QUICKLY_DIR..."
    sudo mkdir -p "$QUICKLY_DIR"
fi

echo "Setting permissions..."
sudo chown -R $(whoami) "$QUICKLY_DIR"

echo "Finding latest release..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "Error: Could not find latest release tag."
    exit 1
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$BINARY_NAME"

echo "Downloading $BINARY_NAME ($LATEST_TAG)..."
curl -L -o "$BINARY_NAME" "$DOWNLOAD_URL"
chmod +x "$BINARY_NAME"

# 3. Install
echo "Installing to $BIN_DIR..."
sudo mv "$BINARY_NAME" "$BIN_DIR/$BINARY_NAME"

echo "Installed! Run 'ql --help' to get started."

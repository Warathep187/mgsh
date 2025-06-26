#!/bin/bash

REMOTE_MAIN_SCRIPT_FILE="https://github.com/Warathep187/mgsh/blob/f56b801cf7beb1176589b10ab82da080066b6985/main.sh"

MAIN_DIR="$HOME/.mgsh"
CONNECTIONS_DIR="$MAIN_DIR/connections"

if command -v mgsh &> /dev/null; then
  echo -e "mgsh is already installed."
  echo ""
  exit 0
fi

OS=$(uname -s)
ARCH=$(uname -m)

SELECTED_SHELL=$(basename $SHELL)
SHELL_CONFIG_FILE="$HOME/.${SELECTED_SHELL}rc"

case $OS in
  Darwin)
    PLATFORM="darwin"
    PACKAGE_EXT="zip"
    ;;
  Linux)
    PLATFORM="linux"
    PACKAGE_EXT="tgz"
    ;;
  *)
    echo -e "Error: Unsupported OS: $OS"
    exit 1
    ;;
esac

ARCH=$(uname -m)
case $ARCH in
  x86_64)
    ARCH_SUFFIX="x64"
    ;;
  arm64|aarch64)
    ARCH_SUFFIX="arm64"
    ;;
  *)
    echo -e "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo -e "MGSH Installation for $OS ($ARCH)"

MONGOSH_DOWLOAD_URL="https://downloads.mongodb.com/compass"
MONGOSH_PACKAGE="mongosh-2.5.3-$PLATFORM-$ARCH_SUFFIX"
MONGOSH_PACKAGE_EXT="$MONGOSH_PACKAGE.$PACKAGE_EXT"

if [ ! -d "$CONNECTIONS_DIR" ]; then
  mkdir -p "$CONNECTIONS_DIR"
fi

echo -e "MGSH (MongoDB Shell Helper) Installation$"
echo ""

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  echo "Adding $HOME/bin to PATH..."
  echo "Shell Config File: $SHELL_CONFIG_FILE"
  echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_CONFIG_FILE"
  export PATH="$HOME/bin:$PATH"

  if [ ! -d "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
  fi
fi

if ! command -v mongosh &> /dev/null; then
  echo -e "Warning: Dependency (mongosh) is not installed."
  echo ""
  echo "Installing mongosh..."
  echo "Downloading mongosh to $HOME..."

  if command -v curl &> /dev/null; then
    curl -o "$HOME/$MONGOSH_PACKAGE_EXT" "$MONGOSH_DOWLOAD_URL/$MONGOSH_PACKAGE_EXT"
  elif command -v wget &> /dev/null; then
    wget -O "$HOME/$MONGOSH_PACKAGE_EXT" "$MONGOSH_DOWLOAD_URL/$MONGOSH_PACKAGE_EXT"
  else
    echo -e "Error: Neither curl nor wget is available. Please install one of them first."
    exit 1
  fi

  echo "Extracting mongosh..."
  
  mkdir -p "$HOME/mongosh"

  if [ "$PACKAGE_EXT" == "zip" ]; then
    unzip "$HOME/$MONGOSH_PACKAGE_EXT" -d "$HOME/mongosh"
  else
    tar -xzf "$HOME/$MONGOSH_PACKAGE_EXT" -C "$HOME/mongosh"
  fi

  cp "$HOME/mongosh/$MONGOSH_PACKAGE/bin/mongosh" "$HOME/bin/mongosh"
  rm -rf "$HOME/mongosh"
  rm "$HOME/$MONGOSH_PACKAGE_EXT"

  if command -v mongosh &> /dev/null; then
    echo -e "mongosh installed successfully."
  else
    echo -e "Error: Failed to install mongosh."
    exit 1
  fi
else
  echo -e "Dependency (mongosh) is already installed."
fi

curl -o "$HOME/bin/mgsh" "$REMOTE_MAIN_SCRIPT_FILE"
chmod +x "$HOME/bin/mgsh"

echo "mgsh is installed"
echo "Done."

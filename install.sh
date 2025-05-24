#!/bin/zsh

BOLD='\033[1m'
NORMAL='\033[0m'
YELLOW='\033[33m'
GREEN='\033[32m'
NC='\033[0m'

MAIN_DIR="$HOME/.mgsh"
CONNECTIONS_DIR="$MAIN_DIR/connections"

MONGOSH_PACKAGE="mongosh-2.5.1-darwin-arm64"

if [ ! -d "$CONNECTIONS_DIR" ]; then
  mkdir -p "$CONNECTIONS_DIR"
fi

echo -e "${BOLD}MGSH (MongoDB Shell Helper) Installation${NC}"
echo ""

if command -v mgsh &> /dev/null; then
  echo -e "${GREEN}mgsh is already installed.${NC}"
  echo ""
  exit 0
fi

# Check if $HOME/bin is in the PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  echo "Adding $HOME/bin to PATH..."
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
  source "$HOME/.zshrc"
fi

# Check if mongosh is installed
if ! command -v mongosh &> /dev/null; then
  echo -e "${YELLOW}Warning: mongosh is not installed.${NC}"
  echo ""
  echo "Installing ..."
  echo "Downloading mongosh..."

  if command -v brew &> /dev/null; then
    echo "Homebrew is installed. Installing mongosh with Homebrew..."
    brew install mongosh
  else
    echo "Downloading mongosh to $HOME..."
    curl -o "$HOME/$MONGOSH_PACKAGE.zip" https://downloads.mongodb.com/compass/$MONGOSH_PACKAGE.zip
    echo "Extracting mongosh..."
    unzip "$HOME/$MONGOSH_PACKAGE.zip" -d "$HOME/mongosh"
    cp "$HOME/mongosh/$MONGOSH_PACKAGE/bin/mongosh" "$HOME/bin/mongosh"
    rm -rf "$HOME/mongosh"
    rm "$HOME/$MONGOSH_PACKAGE.zip"
  fi

  echo -e "${GREEN}mongosh installed successfully.${NC}"
else
  echo -e "${GREEN}mongosh is already installed.${NC}"
fi

cp main.sh "$HOME/bin/mgsh"
chmod +x "$HOME/bin/mgsh"

echo "${GREEN}Done.${NC}"

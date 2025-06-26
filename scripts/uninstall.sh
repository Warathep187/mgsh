#!/bin/bash

echo "Uninstalling mgsh..."

if command -v mgsh &> /dev/null; then
  echo "Removing dependencies (mongosh) ..."
  if [ -f "$HOME/bin/mongosh" ]; then
    rm "$HOME/bin/mongosh"
  fi

  rm "$HOME/bin/mgsh"
  rm -rf "$HOME/.mgsh" # Remove connections
  echo "mgsh removed."

  echo "Done."
else
  echo "mgsh is not installed."
fi
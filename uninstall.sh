#!/bin/zsh

echo "Uninstalling mgsh..."

REMOVE_DEPS=false
for arg in "$@"; do
  case $arg in
    --deps)
      REMOVE_DEPS=true
      shift
      ;;
  esac
done

if command -v mgsh &> /dev/null; then
  if [ "$REMOVE_DEPS" = true ]; then
    echo "Removing dependencies (mongosh) ..."
    if command -v brew &> /dev/null; then
      MATCH=$(brew list | grep -E "mongosh")
      if [ -n "$MATCH" ]; then
        brew uninstall mongosh
      else
        rm "$HOME/bin/mongosh"
      fi
    else
      rm "$HOME/bin/mongosh" 
    fi
  else
    echo "Skipping dependencies removal."
  fi

  rm "$HOME/bin/mgsh"
  echo "mgsh removed."

  echo "Done."
else
  echo "mgsh is not installed."
fi
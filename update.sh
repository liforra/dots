#!/bin/bash

# Get the directory where this script is located
DOTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Updating dotfiles..."

cd "$DOTS_DIR"

if [ -d ".git" ]; then
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        if [ "$1" == "auto" ]; then
             echo "Uncommitted changes found. Skipping auto-update."
             exit 0
        fi
        echo "⚠️  WARNING: You have uncommitted changes in your dotfiles repository."
        git status
        read -p "Do you want to stash them and proceed with pull? (Stash will be popped after) [y/N] " stash_resp
        if [[ "$stash_resp" =~ ^([yY][eE][sS]|[yY])$ ]]; then
             git stash
             STASHED=true
        else
             echo "Aborting update to prevent conflicts."
             exit 1
        fi
    fi

    echo "Pulling latest changes from git..."
    if ! git pull; then
        echo "❌ Error: Git pull failed. Please resolve conflicts manually."
        if [ "$STASHED" = true ]; then
            echo "Attempting to pop stash..."
            git stash pop
        fi
        exit 1
    fi

    if [ "$STASHED" = true ]; then
        echo "Restoring local changes..."
        git stash pop
    fi
else
    echo "Not a git repository. Skipping git pull."
fi

# Run install script
echo "Running install.sh to refresh links..."
if ./install.sh; then
    echo "✅ Links refreshed."
else
    echo "❌ Error running install.sh"
    exit 1
fi

if [ "$1" != "auto" ]; then
    # Ask to run setup for dependencies
    read -p "Do you want to run setup.sh to check for new dependencies? [y/N] " setup_resp
    if [[ "$setup_resp" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        ./setup.sh
    fi
fi

echo "Update complete."
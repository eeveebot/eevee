#!/bin/bash

# Install Zsh completion for eeveevm (vm.sh)

COMPLETION_FILE="./completion/_eeveevm"
ZSH_COMPLETION_DIR="$HOME/.oh-my-zsh/completions"

# Create completions directory if it doesn't exist
if [ ! -d "$ZSH_COMPLETION_DIR" ]; then
    echo "Creating Zsh completions directory: $ZSH_COMPLETION_DIR"
    mkdir -p "$ZSH_COMPLETION_DIR"
fi

# Copy completion file
echo "Installing completion file to $ZSH_COMPLETION_DIR"
cp "$COMPLETION_FILE" "$ZSH_COMPLETION_DIR/"

# Check if fpath already includes the completions directory
if ! grep -q "fpath+=($ZSH_COMPLETION_DIR)" ~/.zshrc; then
    echo "Adding completion directory to fpath in ~/.zshrc"
    echo "" >> ~/.zshrc
    echo "# Add custom completions directory" >> ~/.zshrc
    echo "fpath+=($ZSH_COMPLETION_DIR)" >> ~/.zshrc
    echo "autoload -Uz compinit && compinit" >> ~/.zshrc
fi

echo "Completion installed successfully!"
echo "Please restart your terminal or run 'source ~/.zshrc' to enable completions."

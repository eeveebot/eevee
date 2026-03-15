# Zsh Completion for eeveevm

This directory contains a Zsh completion script for the `eeveevm` command (vm.sh script).

## Installation

### Automatic Installation

Run the installation script:

```bash
./install-completion.sh
```

This will:
1. Copy the completion script to `~/.oh-my-zsh/completions/`
2. Add the completions directory to your `fpath` in `~/.zshrc`
3. Enable autoloading of completions

### Manual Installation

1. Copy the completion file to a directory in your `$fpath`:
   ```bash
   cp _eeveevm ~/.oh-my-zsh/completions/
   ```

2. Add the following to your `~/.zshrc` if not already present:
   ```bash
   fpath+=(~/.oh-my-zsh/completions)
   autoload -Uz compinit && compinit
   ```

3. Restart your terminal or run:
   ```bash
   source ~/.zshrc
   ```

## Usage

Once installed, you can use tab completion with the `eeveevm` command:

```bash
eeveevm <TAB>           # Show available commands
eeveevm version <TAB>   # Show available packages
eeveevm version-all <TAB> # Show bump types
```

The completion supports:
- All eeveevm commands
- Package names for relevant commands
- Bump types (major, minor, patch)
- The `--exclude` option with package name completion

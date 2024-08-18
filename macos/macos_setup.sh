#!/bin/bash
#
# This script is designed to back up and restore macOS system preferences,
# Homebrew packages, dotfiles, and other essential configurations.
# It uses Mackup, a tool that syncs and backs up your dotfiles to cloud storage (like Dropbox),
# to ensure that your configuration files are preserved and can be easily restored.

set -e  # Exit immediately if a command exits with a non-zero status

BACKUP_DIR="$HOME/Backup"
PREFERENCE_DOMAINS=(
    "com.apple.dock"
    "com.apple.finder"
    "NSGlobalDomain"
)

log_message() {
    local prefix_style="\033[1m\033[32m"  # Bold and Green for prefix
    local reset="\033[0m"  # Reset color
    local prefix="[*]"

    echo -e "${prefix_style}${prefix}${reset} $*"
}

handle_error() {
    local exit_code=$1
    local message="$2"
    if [ $exit_code -ne 0 ]; then
        log_message "\033[1m\033[31mError: ${message}\033[0m"
        exit $exit_code
    fi
}

manage_preferences() {
    local action=$1
    mkdir -p $BACKUP_DIR/system_settings
    for domain in "${PREFERENCE_DOMAINS[@]}"; do
        if [ "$action" = "backup" ]; then
            log_message "Backing up $domain preferences..."
            defaults export "$domain" - > "$BACKUP_DIR/system_settings/$domain.plist"
            handle_error $? "Failed to back up $domain preferences"
        else
            log_message "Restoring $domain preferences..."
            defaults import "$domain" - < "$BACKUP_DIR/system_settings/$domain.plist"
            handle_error $? "Failed to restore $domain preferences"
        fi
    done
}

backup() {
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$(dirname "$BACKUP_DIR/brew/Brewfile")"
    log_message "Starting backup..."

    log_message "Backing up Homebrew packages..."
    brew bundle dump --force --file "$BACKUP_DIR/brew/Brewfile"
    handle_error $? "Failed to back up Homebrew packages"
    log_message "Homebrew packages backed up!"

    # Backup preferences
    manage_preferences backup

    log_message "Backing up dotfiles using Mackup..."
    mackup backup -f
    handle_error $? "Failed to back up dotfiles using Mackup"
    log_message "Dotfiles backed up!"

    log_message "Backup completed. Files are saved in $BACKUP_DIR"
}

restore() {
    log_message "Starting restore..."

    # Check if Xcode Command Line Tools are installed
    if ! xcode-select --print-path &> /dev/null; then
        log_message "Installing Xcode Command Line Tools..."
        xcode-select --install
        handle_error $? "Failed to start Xcode Command Line Tools installation"

        # Wait for the installation to complete
        until xcode-select --print-path &> /dev/null; do
            log_message "Waiting for Xcode Command Line Tools to finish installing..."
            sleep 5
        done
        log_message "Xcode Command Line Tools installed!"
    else
        log_message "Xcode Command Line Tools are already installed."
    fi

    # Add Python to the PATH
    log_message "Adding Python to the PATH..."
    PYTHON_PATH="$HOME/Library/Python/3.9/bin"
    if [ -d "$PYTHON_PATH" ]; then
        PATH="$PYTHON_PATH:$PATH"
        log_message "Python added to the PATH!"
    else
        log_message "Python directory not found; make sure Python is installed."
        exit 1
    fi

    # Check if gdown is installed
    if ! command -v gdown &> /dev/null; then
        log_message "Installing gdown..."
        pip install gdown
        handle_error $? "Failed to install gdown"
        log_message "gdown installed!"
    else
        log_message "gdown is already installed."
    fi

    # Check if backup folder exists
    if [ ! -d "$BACKUP_DIR" ]; then
        log_message "Downloading backup from Google Drive..."
        gdown --folder https://drive.google.com/drive/folders/1tlODNHSBAWtpNPHLiLG0kyVtL2T_ajcl
        handle_error $? "Failed to download backup from Google Drive"
        log_message "Download completed!"
    else
        log_message "Backup folder already exists; skipping download."
    fi

    # Install Homebrew if not installed
    if ! command -v brew &> /dev/null; then
        log_message "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        handle_error $? "Failed to install Homebrew"
        log_message "Homebrew installed!"
    else
        log_message "Homebrew is already installed."
    fi

    log_message "Adding Homebrew to the PATH..."
    if ! grep -q 'eval $(/opt/homebrew/bin/brew shellenv)' "$HOME/.zprofile"; then
        echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> "$HOME/.zprofile"
        log_message "Homebrew added to the PATH in .zprofile!"
    else
        log_message "Homebrew PATH already exists in .zprofile, skipping."
    fi

    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Check if Homebrew packages are already installed
    if [ -z "$(brew list)" ]; then
        log_message "Restoring Homebrew packages..."
        brew bundle --file "$BACKUP_DIR/brew/Brewfile"
        handle_error $? "Failed to restore Homebrew packages"
        log_message "Homebrew packages restored!"
    else
        log_message "Homebrew packages already installed; skipping restore."
    fi

    log_message "Make sure Dropbox is opened and synced before continuing."
    while true; do
        read -p "Type 'c' or 'continue' to proceed: " input
        if [[ "$input" == "c" || "$input" == "continue" ]]; then
            break
        else
            log_message "Invalid input. Please type 'c' or 'continue'."
        fi
    done

    log_message "Restoring dotfiles using Mackup..."
    mackup restore -f
    mackup uninstall -f
    handle_error $? "Failed to restore dotfiles using Mackup"
    log_message "Dotfiles restored!"

    # Restore preferences
    manage_preferences restore
    killall Dock

    # Setup and restore Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_message "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        handle_error $? "Failed to install Oh My Zsh"
        log_message "Oh My Zsh installed!"
    fi

    # Clone powerlevel10k theme if not already present
    log_message "Cloning powerlevel10k theme..."

    if [ ! -d "$THEME_DIR" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
        handle_error $? "Failed to clone powerlevel10k theme"
        log_message "powerlevel10k theme cloned!"
    else
        log_message "powerlevel10k theme already cloned."
    fi

    # Update .zshrc for plugins and theme
    log_message "Updating .zshrc for plugins and theme..."

    # Ensure the plugins section in .zshrc
    if ! grep -q 'plugins=' "$HOME/.zshrc"; then
        echo "plugins=(git alias-tips zsh-autosuggestions copyfile autoupdate)" >> "$HOME/.zshrc"
        handle_error $? "Failed to update .zshrc plugins list"
    else
        log_message ".zshrc plugins list already updated."
    fi

    # Ensure the theme section in .zshrc
    if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
        sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
        handle_error $? "Failed to update .zshrc theme"
    else
        log_message ".zshrc theme already set."
    fi

    # Clone custom plugins if not already cloned
    PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

    log_message "Cloning custom Oh My Zsh plugins..."
    mkdir -p "$PLUGIN_DIR"

    if [ ! -d "$PLUGIN_DIR/alias-tips" ]; then
        git clone https://github.com/djui/alias-tips.git "$PLUGIN_DIR/alias-tips"
        handle_error $? "Failed to clone alias-tips plugin"
        log_message "alias-tips plugin cloned!"
    else
        log_message "alias-tips plugin already cloned."
    fi

    if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
        handle_error $? "Failed to clone zsh-autosuggestions plugin"
        log_message "zsh-autosuggestions plugin cloned!"
    else
        log_message "zsh-autosuggestions plugin already cloned."
    fi

    if [ ! -d "$PLUGIN_DIR/autoupdate" ]; then
        git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins "$PLUGIN_DIR/autoupdate"
        handle_error $? "Failed to clone autoupdate plugin"
        log_message "autoupdate plugin cloned!"
    else
        log_message "autoupdate plugin already cloned."
    fi

    # Source .zshrc to apply changes immediately
    source "$HOME/.zshrc"

    log_message "Installing Vim plugins..."
    vim +PluginInstall +qall
    handle_error $? "Failed to install Vim plugins"
    log_message "Vim plugins installed!"

    log_message "Restore completed."
}

case "$1" in
    backup) backup ;;
    restore) restore ;;
    *) echo "Usage: $0 {backup|restore}" ;;
esac

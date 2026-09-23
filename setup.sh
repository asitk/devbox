#!/bin/bash
set -e

# Ensure $HOME is set
if [ -z "$HOME" ]; then
	echo -e "\033[31m✗\033[0m \$HOME is not set. Exiting"
	exit 1
fi

# Check if OS is Linux or macOS
if [[ "$OSTYPE" != "linux-gnu"* && "$OSTYPE" != "darwin"* ]]; then
	echo -e "\033[31m✗\033[0m OS is unsupported. Exiting"
	exit 1
fi

# ==============================================================================
# ⚠ WARNING & COMPATIBILITY NOTICE (macOS ONLY)
# ==============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo -e "\033[33m"
	echo "┌────────────────────────────────────────────────────────────────────────┐"
	echo "│  ⚠  NOTICE: macOS environment has not been completely tested!          │"
	echo "│                                                                        │"
	echo "│  The default stock Apple Terminal.app DOES NOT correctly render the    │"
	echo "│  advanced Nerd Font glyphs, multi-cell icons, or True Color strings    │"
	echo "│  deployed by this devbox installation.                                 │"
	echo "│                                                                        │"
	echo "│  To prevent layout bugs, please use one of these emulators instead:    │"
	echo "│  • Ghostty                                                             │"
	echo "│  • iTerm2  (Will be installed)                                         │"
	echo "│  • WezTerm                                                             │"
	echo "│                                                                        │"
	echo "│  CRITICAL: You MUST manually open your chosen terminal's Preferences   │"
	echo "│  and explicitly bind your font family framework option directly to:    │"
	echo "│  \"JetBrainsMono Nerd Font Mono\"                                       │"
	echo "└────────────────────────────────────────────────────────────────────────┘"
	echo -e "\033[0m"

	# Read exactly one character instantly
	echo -n "Do you want to proceed? (y/N): "
	read -r -n 1 response
	echo "" # Move to a clean newline after instant character capture

	# Validate choice (Aborts on blank/Enter, 'n', or any unexpected character keys)
	if [[ "$response" != "y" && "$response" != "Y" ]]; then
		echo -e "\033[31m✗ Setup aborted. Please switch to a compatible terminal and re-run.\033[0m"
		exit 1
	fi

	echo -e "\033[32m✓ Proceeding with installation...\033[0m\n"
fi
# ==============================================================================

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
	echo -e "\033[32m✓\033[0m Installing Homebrew ..."
	/bin/bash -c "$(curl -fsSL \
		https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
		echo -e "\033[31m✗\033[0m Failed to install Homebrew"
		exit 1
	}
fi

# Load Homebrew into the current shell environment
if [ -f "/opt/homebrew/bin/brew" ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)" # Apple Silicon Mac
elif [ -f "/usr/local/bin/brew" ]; then
	eval "$(/usr/local/bin/brew shellenv)" # Intel Mac
elif [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # Linux / WSL
fi

# Helper function to install brew packages without warnings
brew_install_quiet() {
	local -a packages_to_install=()

	for package in "$@"; do
		if ! brew list "$package" &>/dev/null; then
			packages_to_install+=("$package")
		else
			echo -e "\033[32m✓\033[0m $package is already installed"
		fi
	done

	if [ ${#packages_to_install[@]} -gt 0 ]; then
		echo -e "\033[32m✓\033[0m Installing:${packages_to_install[*]}"
		brew install "${packages_to_install[@]}" || {
			echo -e "\033[31m✗\033[0m Failed to install packages"
			exit 1
		}
	fi
}

# Update Homebrew and clean up old versions
echo -e "\033[32m✓\033[0m Updating Homebrew ..."
brew update || {
	echo -e "\033[31m✗\033[0m Failed to update Homebrew"
	exit 1
}

echo -e "\033[32m✓\033[0m Cleaning up old Homebrew versions ..."
brew cleanup || {
	echo -e "\033[33m⚠\033[0m Failed to cleanup Homebrew (continuing)"
}

# Install prerequisites
echo -e "\033[32m✓\033[0m Installing prerequisites ..."
brew_install_quiet \
	stow fastfetch shellcheck git lazygit tree-sitter-cli lua luarocks \
	git-delta eza ripgrep shfmt tealdeer multitail tree bottom zoxide \
	trash-cli fzf fd curl bat nvim tmux tpm xclip gcc make cmake gh \
	go php ruby composer perl julia imagemagick tectonic node starship

# Platform-specific modern terminal installation for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo -e "\033[32m✓\033[0m macOS detected. Installing modern developer terminal emulator iTerm2 ..."
	brew install --cask iterm2 || {
		echo -e "\033[33m⚠\033[0m Failed to install GUI terminal casks (continuing)"
	}
fi

# Install fonts
echo -e "\033[32m✓\033[0m Installing fonts ..."
brew_install_quiet \
	font-meslo-lg-nerd-font font-fira-code-nerd-font \
	font-jetbrains-mono-nerd-font

# Install bash completion
echo -e "\033[32m✓\033[0m Installing bash completion ..."
version=$(bash --version | head -n1 | cut -d' ' -f4 |
	cut -d'(' -f1)
if [[ $(printf '%s\n' "$version" "4.2" | sort -V |
	head -n1) == "4.2" ]]; then
	brew_install_quiet bash-completion@2
else
	brew_install_quiet bash-completion
fi

# Install LazyVim
echo -e "\033[32m✓\033[0m Installing AstroVim Template ..."
# NOTE: Existing configs are backed up to /tmp before installation
if [ -d "$HOME/devbox/nvim" ]; then
	if [ -d "/tmp/nvim" ]; then
		rm -rf /tmp/nvim
	fi
	mv "$HOME/devbox/nvim" /tmp || {
		echo -e "\033[31m✗\033[0m Failed to cleanup existing nvim config"
		exit 1
	}
fi

# Remove nvim directories (optional but recommended)
if [ -d ~/.local/share/nvim ]; then
	rm -rf ~/.local/share/nvim
fi
if [ -d ~/.local/state/nvim ]; then
	rm -rf ~/.local/state/nvim
fi
if [ -d ~/.cache/nvim ]; then
	rm -rf ~/.cache/nvim
fi

# Clone AstroVim starter
git clone --depth 1 https://github.com/AstroNvim/template "$HOME/devbox/nvim/.config/nvim" || {
	echo -e "\033[31m✗\033[0m Failed to clone AstroVim starter"
	exit 1
}

# Remove .git directory
rm -rf ~/.config/nvim/.git || {
	echo -e "\033[31m✗\033[0m Failed to remove .git from nvim config"
	exit 1
}

# Restore devbox
DOTFILES_DIR="$HOME/devbox"

# Navigate to the devbox directory
cd "$DOTFILES_DIR" || {
	echo -e "\033[31m✗\033[0m $HOME/devbox not found"
	exit 1
}

echo "Restoring configs ..."
tldr --update

# NOTE: Existing bashrc, git, nvim, tmux, and starship configs are moved to
#       $HOME/.local/share/Trash/ or ~/.Trash (macOS) before stowing
if command -v trash &>/dev/null; then
	echo -e "\033[32m✓\033[0m Moving older configs and setting up devbox ..."

	# Safely trash files only if they exist to prevent script failure
	[ -e ~/.config/git ] && trash ~/.config/git
	stow -R "git"

	[ -e ~/.config/nvim ] && trash ~/.config/nvim
	stow -R "nvim"

	[ -e ~/.config/starship.toml ] && trash ~/.config/starship.toml
	stow -R "starship"

	[ -e ~/.config/tmux ] && trash ~/.config/tmux
	stow -R "tmux"

	[ -e ~/.bashrc ] && trash ~/.bashrc
	stow -R "bashrc"

	# Copy custom nvim configuration files
	echo -e "\033[32m✓\033[0m Installing custom nvim configuration files ..."

	# Define paths
	ASTROCORE_TARGET="$HOME/.config/nvim/lua/plugins/astrocore.lua"
	NEOTREE_TARGET="$HOME/.config/nvim/lua/plugins/neo-tree.lua"
	ASTROCOMMUNITY_TARGET="$HOME/.config/nvim/lua/community.lua"
	ASTROCORE_SOURCE="$HOME/devbox/patches/nvim-custom-astrocore.lua"
	NEOTREE_SOURCE="$HOME/devbox/patches/nvim-custom-neo-tree.lua"
	ASTROCOMMUNITY_SOURCE="$HOME/devbox/patches/nvim-custom-community.lua"

	# Validate that all source custom configuration files exist
	echo "Validating custom configuration source files..."
	missing_files=""

	if [ ! -f "$ASTROCORE_SOURCE" ]; then
		missing_files="$missing_files astrocore.lua"
	fi

	if [ ! -f "$NEOTREE_SOURCE" ]; then
		missing_files="$missing_files neo-tree.lua"
	fi

	if [ ! -f "$ASTROCOMMUNITY_SOURCE" ]; then
		missing_files="$missing_files community.lua"
	fi

	if [ -n "$missing_files" ]; then
		echo -e "\033[33m⚠\033[0m Missing custom configuration files:$missing_files"
		echo -e "\033[33m⚠\033[0m Skipping custom configuration installation"
		skip_custom_config=true
	else
		echo -e "\033[32m✓\033[0m All custom configuration files found"
		skip_custom_config=false
	fi

	# Only proceed with backup and copy if all files exist
	if [ "$skip_custom_config" = false ]; then

		# NOTE: Existing customizations are backed up with .bak extension
		#       (astrocore.lua.bak, neo-tree.lua.bak, community.lua.bak)
		if [ -f "$ASTROCORE_TARGET" ]; then
			mv "$ASTROCORE_TARGET" "$ASTROCORE_TARGET.bak" || {
				echo -e "\033[31m✗\033[0m Failed to backup existing astrocore.lua"
				exit 1
			}
			echo -e "\033[33m⚠\033[0m Backed up existing astrocore.lua to astrocore.lua.bak"
		fi

		if [ -f "$NEOTREE_TARGET" ]; then
			mv "$NEOTREE_TARGET" "$NEOTREE_TARGET.bak" || {
				echo -e "\033[31m✗\033[0m Failed to backup existing neo-tree.lua"
				exit 1
			}
			echo -e "\033[33m⚠\033[0m Backed up existing neo-tree.lua to neo-tree.lua.bak"
		fi

		if [ -f "$ASTROCOMMUNITY_TARGET" ]; then
			mv "$ASTROCOMMUNITY_TARGET" "$ASTROCOMMUNITY_TARGET.bak" || {
				echo -e "\033[31m✗\033[0m Failed to backup existing community.lua"
				exit 1
			}
			echo -e "\033[33m⚠\033[0m Backed up existing community.lua to community.lua.bak"
		fi

		# Copy custom configuration files
		cp "$ASTROCORE_SOURCE" "$ASTROCORE_TARGET" || {
			echo -e "\033[31m✗\033[0m Failed to copy custom astrocore.lua"
			exit 1
		}

		cp "$NEOTREE_SOURCE" "$NEOTREE_TARGET" || {
			echo -e "\033[31m✗\033[0m Failed to copy custom neo-tree.lua"
			exit 1
		}

		cp "$ASTROCOMMUNITY_SOURCE" "$ASTROCOMMUNITY_TARGET" || {
			echo -e "\033[31m✗\033[0m Failed to copy custom community.lua"
			exit 1
		}

		echo -e "\033[32m✓\033[0m Custom nvim configuration files installed successfully"
	fi

	# Run headless install

	echo "Running nvim headless install..."
	# 1. Install/Sync Plugins
	nvim --headless "+Lazy! sync" +qa &>/dev/null
	# 2. Sync Tree-sitter parsers (Synchronously)
	nvim --headless +TSUpdateSync +qa &>/dev/null
	# 3. Update/Install Mason Packages and AstroNvim core
	nvim --headless "+AstroUpdate" +qa &>/dev/null

	# Change default login shell to Bash on macOS if it isn't already active
	if [[ "$OSTYPE" == "darwin"* ]]; then
		current_shell=$(dscl . -read "$HOME" UserShell | awk '{print $2}')
		if [[ "$current_shell" != "/bin/bash" ]]; then
			echo -e "\033[32m✓\033[0m Changing your default shell to Bash..."
			echo "Please enter your password when prompted by system permissions:"
			chsh -s /bin/bash || {
				echo -e "\033[31m✗\033[0m Failed to change default shell to Bash"
			}
		else
			echo -e "\033[32m✓\033[0m Default shell is already set to Bash"
		fi
	fi

	# ==============================================================================
	# BASH PROFILE MAC INTEGRATION BRIDGE
	# ==============================================================================
	if [[ "$OSTYPE" == "darwin"* ]]; then
		BASH_PROF="$HOME/.bash_profile"
		SOURCE_CMD="if [ -f ~/.bashrc ]; then source ~/.bashrc; fi"

		if [ -f "$BASH_PROF" ]; then
			if ! grep -q "source.*\.bashrc" "$BASH_PROF" && ! grep -q "\.\s.*\.bashrc" "$BASH_PROF"; then
				# SAFE HIGH-PERMISSION APPEND: Pipes the command securely into the file via sudo tee
				echo -e "\n# Devbox: Dynamic login bridge initialization\n$SOURCE_CMD" | sudo tee -a "$BASH_PROF" > /dev/null
				echo -e "\033[32m✓\033[0m Appended .bashrc loader hook to existing .bash_profile"
			else
				echo -e "\033[32m✓\033[0m Existing .bashrc loader hook verified inside .bash_profile"
			fi
		else
			# SAFE HIGH-PERMISSION CREATE: Creates a fresh file safely via sudo tee
			echo -e "# Devbox: Dynamic login bridge initialization\n$SOURCE_CMD" | sudo tee "$BASH_PROF" > /dev/null
			echo -e "\033[32m✓\033[0m Created a clean .bash_profile loader hook"
		fi
	fi
	# ==============================================================================

	# Activate
  source "$HOME/devbox/bashrc/.bashrc"

	echo ""
	echo -e "\033[32m✓\033[0m Setup complete! :)"
	echo ""
	echo "------------------------------------------------------------------"
	echo -e "To apply all environmental changes to this active window, run:\n   \033[36msource ~/.bashrc\033[0m"
	echo "Or simply open a brand new tab/window pane inside iTerm2! if on MacOS"
	echo "------------------------------------------------------------------"
else
	echo -e "\033[33m⚠\033[0m trash command not found. Skipping stow operations. Bailing"
fi

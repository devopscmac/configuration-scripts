#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starship Installation Script ===${NC}"
echo "This script will install Starship prompt for zsh with support for:"
echo "  - Python virtual environments (with uv package manager)"
echo "  - Node.js environments"
echo "  - Git repositories"
echo ""

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    echo -e "${RED}Error: This script is designed for Ubuntu/Debian systems${NC}"
    exit 1
fi

# Check if zsh is installed
if ! command -v zsh &> /dev/null; then
    echo -e "${YELLOW}zsh is not installed. Installing zsh...${NC}"
    sudo apt update
    sudo apt install -y zsh
    echo -e "${GREEN}✓ zsh installed${NC}"
else
    echo -e "${GREEN}✓ zsh is already installed${NC}"
fi

# Install prerequisites
echo -e "${YELLOW}Installing prerequisites...${NC}"
sudo apt update
sudo apt install -y curl git

# Install uv (Python package manager)
echo -e "${YELLOW}Installing uv (Python package manager)...${NC}"
if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓ uv is already installed${NC}"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo -e "${GREEN}✓ uv installed${NC}"
fi

# Add uv to PATH in .zshrc if not already present
if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' "$ZSHRC"; then
    echo -e "${YELLOW}Adding uv to PATH in .zshrc...${NC}"
    echo '' >> "$ZSHRC"
    echo '# Add uv to PATH' >> "$ZSHRC"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$ZSHRC"
    echo -e "${GREEN}✓ uv added to PATH${NC}"
fi

# Add uv helper aliases
if ! grep -q '# uv aliases' "$ZSHRC"; then
    echo -e "${YELLOW}Adding uv helper aliases to .zshrc...${NC}"
    cat >> "$ZSHRC" << 'UVEOF'

# uv aliases for common operations
alias uv-init='uv venv && source .venv/bin/activate'
alias uv-activate='source .venv/bin/activate'
alias uv-sync='uv pip sync requirements.txt'
UVEOF
    echo -e "${GREEN}✓ uv aliases added${NC}"
fi

# Install Starship
echo -e "${YELLOW}Installing Starship...${NC}"
if command -v starship &> /dev/null; then
    echo -e "${YELLOW}Starship is already installed. Updating...${NC}"
fi

curl -sS https://starship.rs/install.sh | sh -s -- -y

echo -e "${GREEN}✓ Starship installed${NC}"

# Add Starship to .zshrc if not already present
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
    echo -e "${YELLOW}Created new .zshrc file${NC}"
fi

if ! grep -q 'eval "$(starship init zsh)"' "$ZSHRC"; then
    echo -e "${YELLOW}Adding Starship initialization to .zshrc...${NC}"
    echo '' >> "$ZSHRC"
    echo '# Initialize Starship prompt' >> "$ZSHRC"
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    echo -e "${GREEN}✓ Starship added to .zshrc${NC}"
else
    echo -e "${GREEN}✓ Starship already configured in .zshrc${NC}"
fi

# Create Starship configuration directory
CONFIG_DIR="$HOME/.config"
mkdir -p "$CONFIG_DIR"

# Create Starship configuration file
STARSHIP_CONFIG="$CONFIG_DIR/starship.toml"
echo -e "${YELLOW}Creating Starship configuration...${NC}"

cat > "$STARSHIP_CONFIG" << 'EOF'
# Starship Configuration
# Optimized for Python, Node.js, and Git development

# Timeout for commands (in milliseconds)
command_timeout = 1000

# Format of the prompt
format = """
[╭─](bold green)$username$hostname$directory$git_branch$git_status$python$custom$nodejs
[╰─](bold green)$character"""

# Prompt character
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

# Current directory
[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "

# Git branch
[git_branch]
symbol = " "
style = "bold purple"
format = "on [$symbol$branch]($style) "

# Git status
[git_status]
style = "bold yellow"
format = '([\[$all_status$ahead_behind\]]($style) )'
conflicted = "🏳"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
up_to_date = "✓"
untracked = "?${count}"
stashed = "$${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

# Python environment
[python]
symbol = " "
style = "yellow bold"
format = 'via [$symbol$pyenv_prefix($version )(\($virtualenv\) )]($style)'
pyenv_version_name = false
pyenv_prefix = ""
detect_extensions = ["py"]
detect_files = [
    "requirements.txt",
    "pyproject.toml",
    "Pipfile",
    "setup.py",
    "tox.ini",
    ".python-version",
    "uv.lock"
]
detect_folders = [".venv", "venv", "env"]

# UV (Python package manager)
[custom.uv]
command = "uv --version | awk '{print $2}'"
when = """ test -f pyproject.toml || test -f uv.lock """
symbol = "📦 "
style = "bold blue"
format = "[$symbol(uv $output )]($style)"

# Node.js environment
[nodejs]
symbol = " "
style = "bold green"
format = "via [$symbol($version )]($style)"
detect_extensions = ["js", "mjs", "cjs", "ts"]
detect_files = ["package.json", ".node-version", ".nvmrc"]
detect_folders = ["node_modules"]

# AWS
[aws]
symbol = "  "
format = 'on [$symbol($profile )(\($region\) )]($style)'
style = "bold yellow"
disabled = false

# Docker
[docker_context]
symbol = " "
format = "via [$symbol$context]($style) "
style = "blue bold"
only_with_files = true

# Kubernetes
[kubernetes]
symbol = "☸ "
format = 'on [$symbol$context( \($namespace\))]($style) '
style = "cyan bold"
disabled = false

# Terraform
[terraform]
symbol = "💠 "
format = "via [$symbol$workspace]($style) "
style = "bold 105"
disabled = false

# Username
[username]
style_user = "green bold"
style_root = "red bold"
format = "[$user]($style) "
disabled = false
show_always = false

# Hostname
[hostname]
ssh_only = true
format = "at [$hostname](bold red) "
disabled = false

# Time
[time]
disabled = true
format = '🕙[\[ $time \]]($style) '
time_format = "%T"

# Command duration
[cmd_duration]
min_time = 500
format = "took [$duration](bold yellow) "

# Line break
[line_break]
disabled = false
EOF

echo -e "${GREEN}✓ Starship configuration created at $STARSHIP_CONFIG${NC}"

# Install Nerd Font (optional but recommended)
echo ""
echo -e "${YELLOW}Would you like to install a Nerd Font for better icon support? (y/n)${NC}"
read -r install_font

if [[ $install_font =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installing FiraCode Nerd Font...${NC}"
    
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    cd "$FONT_DIR"
    curl -fLo "FiraCode Regular Nerd Font Complete.ttf" \
        https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
    
    # Refresh font cache
    fc-cache -fv
    
    echo -e "${GREEN}✓ FiraCode Nerd Font installed${NC}"
    echo -e "${YELLOW}Note: You may need to set your terminal to use 'FiraCode Nerd Font'${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "Installed components:"
echo "  ✓ Starship prompt"
echo "  ✓ uv (Python package manager)"
echo "  ✓ zsh integration"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. If you installed a Nerd Font, configure your terminal to use it"
echo "  3. Customize your prompt: edit ~/.config/starship.toml"
echo ""
echo "uv usage examples:"
echo "  uv venv                    # Create virtual environment"
echo "  uv pip install <package>   # Install package"
echo "  uv pip compile requirements.in -o requirements.txt"
echo "  uv-init                    # Alias: create venv and activate"
echo ""
echo "Optional: Make zsh your default shell:"
echo "  chsh -s \$(which zsh)"
echo ""
echo -e "${GREEN}Enjoy your new Starship prompt with uv!${NC}"

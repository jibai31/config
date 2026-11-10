# VS Code
cp /Users/jb/Library/Application\ Support/Code/User/settings.json vscode/
cp /Users/jb/Library/Application\ Support/Code/User/keybindings.json vscode/

# NeoVim
cp -R ~/.config/nvim nvim/

# Vim
cp ~/.vimrc vim/

# Espanso
cp ~/.espanso.yml espanso/

# Claude
cp -R ~/.claude/skills claude/skills/
rm -rf claude/skills/synced

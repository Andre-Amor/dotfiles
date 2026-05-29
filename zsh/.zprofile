# Login files (/etc/profile, macOS path_helper) clobber .zshenv's PATH edits.
# Re-source it here, after they run, to restore them.
source "$HOME/.zshenv"

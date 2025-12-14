#!/bin/bash
# Dock
defaults write com.apple.dock tilesize -int 36                   # Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock mineffect -string scale            # Change minimize/maximize window effect
defaults write com.apple.dock autohide -bool true                # Automatically hide and show the Dock
defaults write com.apple.dock static-only -bool true             # Only show open applications in the Dock
defaults write com.apple.dock show-recents -bool false           # Do not show recent applications in Dock
defaults write com.apple.dock persistent-apps -array             # Remove all apps from Dock
killall Dock

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true                 # Show all filename extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false      # Disable the warning when changing a file extension
defaults write com.apple.finder ShowPathbar -bool true                          # Show path bar
defaults write com.apple.finder ShowStatusBar -bool true                        # Show status bar
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"             # Use list view in all Finder windows by default
defaults write com.apple.finder _FXSortFoldersFirst -bool true                  # Keep folders on top when sorting by name
defaults write com.apple.finder QuitMenuItem -bool true                         # Show Quit Finder menu item
defaults write com.apple.finder NewWindowTarget PfHm                            # Set "New Finder windows show" to home folder
killall Finder

# Safari
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Keyboard
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true         # Use all F1, F2, etc. keys as standard function keys
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2                    # Enable full keyboard access for all controls. e.g. enable Tab in modal dialogs

# TextEdit
defaults write com.apple.TextEdit RichText -int 0           # Use plain text mode for new TextEdit documents

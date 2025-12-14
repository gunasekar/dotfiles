#!/usr/bin/env bash

##### functions
function setHostName {
    scutil --set ComputerName "$1"
    scutil --set LocalHostName "$1"
    scutil --set HostName "$1"
}

### brew configuration
function set-permissions-for-brew {
    sudo chown -R $(whoami) $(brew --prefix)/*
}

function brew-backup {
    brew bundle dump --no-vscode --force --global
}

function brew-restore {
    brew bundle --global
}

function brew-cleanup {
    brew bundle cleanup --global --force
}

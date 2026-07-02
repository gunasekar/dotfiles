#!/usr/bin/env bash


function n {
    if ! command -v nvim &>/dev/null; then
        echo "nvim not found. please install neovim"
        return 1
    fi
    nvim "${@:-.}"
}

# `agent` (~/.local/bin/agent, see bin/ package) is the same fzf picker used
# by nvim's right panel and Zed's agent.terminal_init_command — a real
# command rather than an alias so it also works from scripts and
# non-interactive shells. CLI installers (cursor-agent, grok, ...) also
# write to ~/.local/bin/agent and may clobber this symlink on install/update
# — if `agent` stops launching the picker, re-run install.sh (or `stow bin`
# from ~/.dotfiles) to restore it.

##### Go
if command -v brew &>/dev/null; then
    _GO_PREFIX="$(brew --prefix go 2>/dev/null)"
    if [[ -n "$_GO_PREFIX" && -d "$_GO_PREFIX" ]]; then
        export GOROOT="$_GO_PREFIX/libexec"
    fi
    unset _GO_PREFIX
fi
export GOPATH="$HOME/workspace/.go"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"
test -d "${GOPATH}" || mkdir "${GOPATH}"

function _go_build_linux {
    local arch=$1
    local name=$2

    if [ "$arch" = "" ]; then
        echo "Usage: go-build-linux <arch> [name]"
        echo "  arch: arm64 or amd64"
        echo "  name: optional output name (defaults to 'main')"
        return 1
    fi

    if [ "$name" = "" ]; then
        name="main"
    fi

    env GOOS=linux GOARCH="$arch" go build -o "$name-linux-$arch"
}

function go-build-linux-arm64 {
    _go_build_linux arm64 "$1"
}

function go-build-linux-amd64 {
    _go_build_linux amd64 "$1"
}

function go-test-coverage {
    go test -coverprofile=coverage.out
    go tool cover -html=coverage.out
}

function go-test-all {
    GOCACHE=off go test ./...
}

function add-repo-to-goprivate {
    repoToAdd=$1

    # Check if the string is present in the GOPRIVATE variable
    if ! echo "$GOPRIVATE" | grep -q "$repoToAdd"; then
        # check if GOPRIVATE is empty and add comma
        if [ -z "$GOPRIVATE" ]; then
            export GOPRIVATE="$repoToAdd"
        else
            export GOPRIVATE="${GOPRIVATE},$repoToAdd"
        fi
    fi
}

##### Java
if [ -d "/Applications/IntelliJ IDEA CE.app/Contents/MacOS" ]; then
    export PATH="$PATH:/Applications/IntelliJ IDEA CE.app/Contents/MacOS"
fi

jdk() {
      version=$1
      unset JAVA_HOME;
      export JAVA_HOME=$(/usr/libexec/java_home -v"$version");
      java -version
}

### Python — shims on PATH at startup; shell hooks load on first use
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then
    # shellcheck disable=SC2218  # pyenv binary, not the lazy-load function defined below
    eval "$(pyenv init --path)"

    _pyenv_lazy_load() {
        unset -f _pyenv_lazy_load pyenv python python3 pip pip3 pipx pipx3 2>/dev/null
        unalias python pip pipx 2>/dev/null
        eval "$(pyenv init -)"
        command -v pyenv-virtualenv-init &>/dev/null && eval "$(pyenv virtualenv-init -)"
        alias python=python3
        alias pip=pip3
        alias pipx=pipx3
    }

    # Unalias before defining wrappers — required when re-sourced and for zsh alias precedence.
    unalias python pip pipx 2>/dev/null
    unset -f pyenv python python3 pip pip3 pipx pipx3 2>/dev/null

    pyenv()  { _pyenv_lazy_load; pyenv "$@"; }
    python() { _pyenv_lazy_load; command python "$@"; }
    python3() { _pyenv_lazy_load; command python3 "$@"; }
    pip()    { _pyenv_lazy_load; command pip "$@"; }
    pip3()   { _pyenv_lazy_load; command pip3 "$@"; }
    pipx()   { _pyenv_lazy_load; command pipx "$@"; }
    pipx3()  { _pyenv_lazy_load; command pipx3 "$@"; }
else
    # No pyenv — fall back to system python3/pip3 with the documented aliases.
    command -v python3 &>/dev/null && alias python=python3
    command -v pip3 &>/dev/null && alias pip=pip3
fi

# nvm — lazy load on first node/npm/nvm use (supports ARM and Intel Macs)
if command -v brew &>/dev/null; then
    NVM_BREW_PREFIX="$(brew --prefix nvm 2>/dev/null)"
    if [[ -n "$NVM_BREW_PREFIX" && -s "$NVM_BREW_PREFIX/nvm.sh" ]]; then
        export NVM_DIR="$HOME/.nvm"

        _nvm_lazy_load() {
            unset -f _nvm_lazy_load nvm node npm npx 2>/dev/null
            \. "$NVM_BREW_PREFIX/nvm.sh"
            [[ -s "$NVM_BREW_PREFIX/etc/bash_completion.d/nvm" ]] && \
                \. "$NVM_BREW_PREFIX/etc/bash_completion.d/nvm"
        }

        nvm()  { _nvm_lazy_load; nvm "$@"; }
        node() { _nvm_lazy_load; node "$@"; }
        npm()  { _nvm_lazy_load; npm "$@"; }
        npx()  { _nvm_lazy_load; npx "$@"; }
    fi
fi

# Lazy tool aliases
command -v lazygit &>/dev/null && alias gitl='lazygit'
command -v lazydocker &>/dev/null && alias dockerl='lazydocker'

# direnv hook
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

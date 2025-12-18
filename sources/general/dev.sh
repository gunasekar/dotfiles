#!/usr/bin/env bash

function c {
    if ! command -v cursor &>/dev/null; then
        if ! command -v code &>/dev/null; then
            echo "no editors found. please install cursor or vscode"
        else
            code "${@:-.}"
        fi
    else
        cursor "${@:-.}"
    fi
}

function v {
    if ! command -v nvim &>/dev/null; then
        echo "nvim not found. please install neovim"
        return 1
    fi
    nvim "${@:-.}"
}

##### Go
if [ -d "$(brew --prefix go)" ]; then
    export GOROOT="$(brew --prefix go)/libexec"
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

    env GOOS=linux GOARCH=$arch go build -o $name-linux-$arch
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

### Python
export PYENV_ROOT="$HOME/.pyenv"
# Add pyenv to PATH
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# Initialize pyenv (handles both PATH setup and shell integration in v2.x+)
eval "$(pyenv init -)"
# Enable pyenv virtualenv if installed
if command -v pyenv-virtualenv-init > /dev/null; then
  eval "$(pyenv virtualenv-init -)"
fi
# Aliases for convenience
alias python=python3
alias pip=pip3
alias pipx=pipx3

### Setup llm keys for aider
function setup-llm-keys {
if command -v pass &>/dev/null; then
    if [ -z "$DEEPSEEK_API_KEY" ]; then
        if pass llm/deepseek > /dev/null 2>&1; then
            export DEEPSEEK_API_KEY=$(pass llm/deepseek)
        fi
    fi
    if [ -z "$GROQ_API_KEY" ]; then
        if pass llm/groq > /dev/null 2>&1; then
            export GROQ_API_KEY=$(pass llm/groq)
        fi
    fi
    if [ -z "$OPENROUTER_API_KEY" ]; then
        if pass llm/openrouter > /dev/null 2>&1; then
            export OPENROUTER_API_KEY=$(pass llm/openrouter)
        fi
    fi
fi
}


# nvm - Load if installed (supports both ARM and Intel Macs)
if command -v brew &>/dev/null; then
    NVM_BREW_PREFIX="$(brew --prefix nvm 2>/dev/null)"
    if [ -n "$NVM_BREW_PREFIX" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_BREW_PREFIX/nvm.sh" ] && \. "$NVM_BREW_PREFIX/nvm.sh"  # This loads nvm
        [ -s "$NVM_BREW_PREFIX/etc/bash_completion.d/nvm" ] && \. "$NVM_BREW_PREFIX/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
    fi
fi

# Added by Windsurf
if [ -d "$HOME/.codeium/windsurf" ]; then
    export PATH="$PATH:$HOME/.codeium/windsurf/bin"
fi

# Add Claude to PATH
export PATH="$PATH:$HOME/.claude/local"


# Added by Antigravity
if [ -d "$HOME/.antigravity/antigravity/bin" ]; then
    export PATH="$PATH:$HOME/.antigravity/antigravity/bin"
fi

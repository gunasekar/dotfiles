# brew shellenv - Detect Homebrew location automatically
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - Check both ARM (/opt/homebrew) and Intel (/usr/local) paths
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
else
    echo "Unsupported OS: $OSTYPE"
fi

### shell configuration
export LC_ALL=en_US.UTF-8
export ZSH_DISABLE_COMPFIX=true

# zsh key bindings
case $SHELL in
    */zsh)
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)
        ;;
        Darwin*)
        bindkey -e
        bindkey "^[[1;3C" forward-word    # Option + Right Arrow
        bindkey "^[[1;3D" backward-word   # Option + Left Arrow
        ;;
        CYGWIN*)
        ;;
        MINGW*)
        ;;
        *)
        echo "Unknown system";;
    esac
    ;;
esac

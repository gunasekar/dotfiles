#!/bin/bash

##### ssh related functions #####
function ssh-keygen-rsa {
    comment=$1
    if [ -z "$2" ]; then
        ssh-keygen -t rsa -b 4096 -C "$comment"
    else
        ssh-keygen -t rsa -b $2 -C "$comment"
    fi
}

function ssh-keygen-ed25519 {
    comment=$1
    ssh-keygen -t ed25519 -C "$comment"
}

function ssh-keygen-ecdsa {
    comment=$1
    ssh-keygen -t ecdsa -b 521 -C "$comment"
}

# DEPRECATED: DSA keys are no longer secure (max 1024 bits, considered weak)
# Use ssh-keygen-ed25519 or ssh-keygen-rsa instead
function ssh-keygen-dsa {
    echo "⚠️  ERROR: DSA keys are DEPRECATED and INSECURE (max 1024 bits)" >&2
    echo "DSA support has been removed from OpenSSH 7.0+ by default" >&2
    echo "" >&2
    echo "Please use one of these modern alternatives:" >&2
    echo "  • ssh-keygen-ed25519 (RECOMMENDED - fastest and most secure)" >&2
    echo "  • ssh-keygen-rsa (RSA 4096-bit for compatibility)" >&2
    return 1
}

function test-SSH-github {
    ssh -T git@github.com
}

function test-SSH-bitbucket {
    ssh -T git@bitbucket.org
}

function test-SSH-gitlab {
    ssh -T git@gitlab.com
}

##### sudo related functions #####
# WARNING: This function creates a MAJOR SECURITY RISK
# NOPASSWD: ALL gives unrestricted root access without password
# Only use in isolated development environments, NEVER in production
function set-sudo-wo-pwd {
    echo "⚠️  SECURITY WARNING ⚠️" >&2
    echo "This will configure passwordless sudo with FULL ROOT ACCESS" >&2
    echo "" >&2
    echo "Risks:" >&2
    echo "  • Any process running as your user can gain root access" >&2
    echo "  • Malware can execute commands as root silently" >&2
    echo "  • No audit trail of privileged operations" >&2
    echo "" >&2
    echo "Only proceed if:" >&2
    echo "  ✓ This is an isolated development VM" >&2
    echo "  ✗ NEVER on production systems" >&2
    echo "  ✗ NEVER on shared systems" >&2
    echo "  ✗ NEVER on systems with sensitive data" >&2
    echo "" >&2
    read -p "Type 'I UNDERSTAND THE RISK' to continue: " -r
    echo

    if [[ "$REPLY" != "I UNDERSTAND THE RISK" ]]; then
        echo "Cancelled - good choice for security!"
        return 1
    fi

    user=$(whoami)
    if command -v pbcopy &>/dev/null; then
        echo "$user    ALL=(ALL) NOPASSWD: ALL" | pbcopy
    else
        echo "$user    ALL=(ALL) NOPASSWD: ALL" | xclip -selection c
    fi

    echo "Configuration copied to clipboard. Opening visudo..."
    echo "Paste the line at the END of the file."
    sleep 2
    sudo visudo
}

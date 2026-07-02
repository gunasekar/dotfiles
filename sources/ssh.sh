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

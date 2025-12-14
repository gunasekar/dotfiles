#!/usr/bin/env bash

function enable-ubuntu-partners-repo {
    sudo sed -i.bak "/^# deb .*partner/ s/^# //" /etc/apt/sources.list
}

if command -v dpkg &>/dev/null; then
    # shellcheck disable=SC2139
    alias remove-unused-kernels="sudo apt-get purge $(dpkg -l linux-{image,headers}-"[0-9]*" | awk '/ii/{print $2}' | grep -ve "$(uname -r | sed -r 's/-[a-z]+//')")"
fi

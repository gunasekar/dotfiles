#!/usr/bin/env bash

function jenkins-follow {
    [[ $# -lt 2 || $# -gt 3 ]] && { echo "$0 <jenkinsServer> <jobName> <optional:buildID>"; return; }
    token=$(pass jenkins/$1)
    jcli job log --watch --jenkins $1 --token $token $2 $3 2>&1 | less +F
}

function jenkins-view {
    [[ $# -lt 2 || $# -gt 3 ]] && { echo "$0 <jenkinsServer> <jobName> <optional:buildID>"; return; }
    token=$(pass jenkins/$1)
    jcli job log --jenkins $1 --token $token $2 $3 | grep --color=never 'Current build\|Started by user\|Aborted by\|Checking out Revision\|Commit message\|Finished:'
}

function jenkins-trigger {
    [[ $# != 2 ]] && { echo "$0 <jenkinsServer> <jobName>"; return; }
    token=$(pass jenkins/$1)
    jcli job build --jenkins $1 --token $token $2
}

function jenkins-enable {
    [[ $# != 2 ]] && { echo "$0 <jenkinsServer> <jobName>"; return; }
    token=$(pass jenkins/$1)
    jcli job enable --jenkins $1 --token $token $2
}

function jenkins-disable {
    [[ $# != 2 ]] && { echo "$0 <jenkinsServer> <jobName>"; return; }
    token=$(pass jenkins/$1)
    jcli job disable --jenkins $1 --token $token $2
}

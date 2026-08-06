#!/usr/bin/env bash

##### functions
function setHostName {
  scutil --set ComputerName "$1"
  scutil --set LocalHostName "$1"
  scutil --set HostName "$1"
}

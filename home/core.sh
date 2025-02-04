#!/bin/env bash

function lu() {
  printf "%-20s %-6s %-6s %-25s %-20s\n" "User" "UID" "GID" "Home" "Shell"
  echo "----------------------------------------------------------------------------------------------"
  awk -F: '{ printf "%-20s %-6s %-6s %-25s %-20s\n", $1, $3, $4, $6, $7 }' /etc/passwd
}

function lg() {
  printf "%-20s %-6s %-30s\n" "Group" "GID" "Members"
  echo "----------------------------------------------------------------------------------------------"
  awk -F: '{ printf "%-20s %-6s %-30s\n", $1, $3, $4 }' /etc/group
}

mc() {
    mkdir -p $@ && cd ${@:$#}
}

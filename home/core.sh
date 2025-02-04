#!/bin/env sh

alias l='ls -alF --color=auto'
alias cl='clear'
alias nclisten='echo "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\nHello World" | nc -l -N 8080'
alias pythonweb='python3 -m http.server 8080'
alias ncsw='nc towel.blinkenlights.nl 23'

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

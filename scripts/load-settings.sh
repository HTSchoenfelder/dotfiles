#! /bin/bash

# dconf dump / > current_dconf.ini

cat ~/dotfiles/misc/dconf.ini | dconf load /

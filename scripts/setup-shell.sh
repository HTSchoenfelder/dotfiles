#! /bin/bash

sudo apt update
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
sudo apt install -y \
      zsh \
      tmux \
      ttf-mscorefonts-installer

# ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM_DEFAULT=~/.oh-my-zsh/custom
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autosuggestions
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/fast-syntax-highlighting
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-$ZSH_CUSTOM_DEFAULT}/plugins/zsh-autocomplete


# Nerd Font
font_name="Agave"
curl -L -o ~/Downloads/$font_name.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_name.zip"
mkdir -p  $HOME/.fonts
unzip -o ~/Downloads/$font_name.zip"-d $HOME/.fonts/$font_name/
fc-cache -fv

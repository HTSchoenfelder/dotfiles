{
  pkgs,
  pkgsStable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
          vim
          git
          stow
          stackit-cli
          fzf
          zoxide
          direnv
          starship
          eza
          yazi
          kubectl 
          direnv
          terraform
          zellij
          neovim
          nodejs
          bat
          gnumake
          zsh-autosuggestions
          zsh-fast-syntax-highlighting
          neofetch
          cowsay
          cloudfoundry-cli
          docker
          docker-buildx
          colima

          #Apps
          pkgsStable.kitty
          cyberduck
          obsidian
          utm
          vscode
          karabiner-elements
          # keepassxc
          # spotify
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerd-fonts._0xproto
    nerd-fonts.agave
    font-awesome
  ];
}

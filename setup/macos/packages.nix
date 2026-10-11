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
    starship
    eza
    yazi
    kubectl
    pkgsStable.direnv
    terraform
    zellij
    neovim
    lua-language-server
    typescript-language-server
    vscode-langservers-extracted
    tree-sitter
    stylua
    prettier
    (ruby.withPackages (rubyPackages: [
      rubyPackages."erb-formatter"
      rubyPackages.rubocop
      rubyPackages.solargraph
    ]))
    lazygit
    nodejs
    bat
    gnumake
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    fastfetch
    cowsay
    cloudfoundry-cli
    docker
    docker-buildx
    colima
    lua

    #Apps
    pkgsStable.kitty
    cyberduck
    obsidian
    utm
    vscode
    # keepassxc
    # spotify
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts._0xproto
    nerd-fonts.agave
    font-awesome
  ];
}

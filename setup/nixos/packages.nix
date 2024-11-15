{
  pkgs,
  stablePkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    home-manager
    git
    go
    terraform
    kubectl
    kubernetes-helm
    lazygit
    starship
    direnv
    neovim
    fzf
    curl
    bat
    ripgrep
    jq
    tldr
    tmux
    zellij
    zoxide
    htop
    btop
    nano
    stow
    keepassxc
    neofetch
    obsidian
    nautilus
    wget
    udiskie
    smartmontools
    dnsmasq
    wirelesstools
    cifs-utils
    waybar
    dunst
    kitty
    hyprpaper
    wl-clipboard
    yazi
    wtype
    wireplumber
    pavucontrol
    qpwgraph
    desktop-file-utils
    font-manager
    firefoxpwa
    vscode
    stablePkgs.synology-drive-client
    gparted
    colorls
    tofi
    wofi
    clipse
    stablePkgs.spotify
    wlogout
    usbutils
    playerctl
    mlocate
    libsForQt5.qt5ct
    libsForQt5.qt5.qtwayland
    catppuccin-cursors.mochaMauve
    libreoffice
    simple-scan
    system-config-printer
    terraform
    nodejs
    gcc
    clang
    dotnet-sdk_8
    nixfmt-rfc-style
    seahorse
    google-chrome
    nomacs
    gthumb
    geeqie
    synergy
    wev
    tree
    hyprshot
    libnotify
    hyprlock
    hypridle
    brightnessctl
    remmina
    azure-cli
    icu76
    nix-tree
    ansible
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    nerdfonts
    font-awesome
  ];
}

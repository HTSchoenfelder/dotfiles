{
  pkgs,
  pkgsStable,
  pkgsLatest,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pkgsLatest.vscode
    pkgsStable.spotify
    pkgsStable.hyprpaper
    pkgsStable.azure-cli
    synology-drive-client
    home-manager
    git
    go
    terraform
    kubectl
    kubernetes-helm
    lazygit
    starship
    direnv
    envsubst
    kustomize
    just
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
    dunst
    kitty
    wl-clipboard
    yazi
    wtype
    wireplumber
    pavucontrol
    qpwgraph
    desktop-file-utils
    font-manager
    firefoxpwa
    gparted
    tofi
    wofi
    clipse
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
    dotnetCorePackages.sdk_9_0
    nixfmt-rfc-style
    seahorse
    google-chrome
    gthumb
    synergy
    wev
    tree
    hyprshot
    libnotify
    hyprlock
    hypridle
    brightnessctl
    remmina
    icu76
    nix-tree
    ansible
    traceroute
    hey
    openssl
    hyprpicker
    k9s
    cmatrix
    eza
    nmap
    tcpdump
    iperf3
    kubectx
    strace
    fd
    ripgrep
    microsoft-edge
    linphone
    audacity
    usbview
    v4l-utils
    networkmanagerapplet
    qrencode
    zbar
    yubioath-flutter
    gimp
    cage
    lazydocker
    gnome-text-editor
    spotify-player
    gnome-calculator
    arduino-cli
    arduino-ide
    arduino-create-agent
    pdfsam-basic
    socat
    python313
    python313Packages.west
    python313Packages.pykwalify
    python313Packages.pykwalify
    python313Packages.ruamel-yaml
    python313Packages.pyocd
    python313Packages.cmsis-pack-manager
    cmake
    spice
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

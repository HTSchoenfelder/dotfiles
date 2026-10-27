local applications = {
  {
    key = "j",
    name = "Kitty / Zellij",
    bundleID = "net.kovidgoyal.kitty",
    newWindowShortcut = {modifiers = {"cmd"}, key = "n"},
    launchEnvironment = {START_ZELLIJ = "1"},
  },
  {
    key = "k",
    name = "Code",
    bundleID = "com.microsoft.VSCode",
    newWindowShortcut = {modifiers = {"cmd", "shift"}, key = "n"},
  },
  {
    key = "l",
    name = "Google Chrome",
    bundleID = "com.google.Chrome",
    newWindowShortcut = {modifiers = {"cmd"}, key = "n"},
  },
  {
    id = "chat",
    name = "Google Chat",
    bundleID = "com.google.Chrome.app.pommaclcbfghclhalboakcipcmmndhcj",
  },
  {
    id = "meet",
    name = "Google Meet",
    bundleID = "com.google.Chrome.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
  },
  {
    id = "gmail",
    name = "Gmail",
    bundleID = "com.google.Chrome.app.fmgjjmmmlfnkbppncabfkddbjimcfncm",
  },
  {
    id = "calendar",
    name = "Google Calendar",
    bundleID = "com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep",
  },
  {key = ";", name = "Obsidian", bundleID = "md.obsidian"},
  {key = "o", name = "KeePassXC", bundleID = "org.keepassxc.keepassxc"},
  {name = "Spotify", bundleID = "com.spotify.client"},
}

applications.groups = {
  {key = "i", name = "Chat / Meet", applications = {"chat", "meet"}},
  {key = "u", name = "Mail / Calendar", applications = {"gmail", "calendar"}},
}

return applications

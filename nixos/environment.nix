{ config, pkgs, ... }:

{
  environment = {
    # Environment variables
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      BROWSER = "brave";
    };

    # Session variables (Wayland support for Electron apps)
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # System-wide packages
    systemPackages = with pkgs; [
      kitty                # GPU-accelerated terminal emulator
      # Terminal & Search Utilities
      ripgrep              # Fast text search tool
      fd                   # Simple, fast alternative to 'find'
      fzf                  # Command-line fuzzy finder
      bat                  # Better 'cat' with syntax highlighting
      glow                 # Terminal markdown renderer
      tldr                 # Simplified help pages
      zoxide               # Smarter 'cd' command
      yazi                 # Terminal file manager
      superfile            # Modern terminal file manager
      television           # Smart fuzzy finder / launcher
      scooter              # Interactive terminal search tool

      # Development Languages & Runtimes
      python3              # Python programming language
      php                  # PHP scripting language
      phpPackages.composer # PHP dependency manager
      nodejs               # JavaScript runtime
      go                   # Go programming language
      sqlite               # Lightweight SQL database engine

      # Developer Tools & Utilities
      lazygit              # Terminal UI for git commands
      supabase-cli         # CLI for Supabase backend
      nixfmt               # Nix code formatter
      nixd                 # Nix language server
      claude-code          # Claude CLI tool
      podman-tui           # Terminal UI for Podman containers
      bitwarden-cli        # Password manager CLI

      # System, Hardware & Network
      intel-media-driver   # Hardware video acceleration for Intel
      cifs-utils           # Tools for mounting SMB/CIFS shares
      keyd                 # Keyboard remapping daemon
      kotofetch            # System info fetch script
      pavucontrol          # PulseAudio / PipeWire volume control
      weathr               # Terminal weather app
      adwaita-icon-theme   # Standard GTK icon theme

      # Desktop Applications
      obsidian             # Note-taking app
      blender              # 3D creation suite
      zed-editor           # Fast code editor
      qutebrowser          # Keyboard-focused browser
      vlc                  # Media player
      qbittorrent          # Torrent client
      vesktop              # Custom Discord desktop client
      noctalia-qs          # Quick settings / widget component
      matugen              # Material You color scheme generator
      ollama               # Local AI model runner
      xwayland             # X11 compatibility layer for Wayland
      brave                # Privacy-focused web browser
      nautilus

      # Gaming & Emulation
      steam                # Steam gaming platform
      lutris               # Open-source gaming launcher
      wine                 # Windows compatibility layer (32/64-bit)
      wineWow64Packages.stable # Stable Wine WOW64 package
      winetricks           # Helper script for Wine configuration
      protontricks         # Helper script for Proton configuration
      mangohud             # Performance overlay for gaming
      game-devices-udev-rules    # Udev rules for controllers and game devices
    ];
  };
}

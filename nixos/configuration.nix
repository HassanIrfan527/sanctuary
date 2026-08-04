{ config, pkgs, ... }:

{
  # 1. Include hardware settings (automatically generated during installation)
  imports = [
    ./hardware-configuration.nix
    ./services.nix
    ./programs.nix
    ./environment.nix
    ./users.nix
    ./security.nix
  ];

  system.stateVersion = "26.05";
nixpkgs.config.allowUnfree = true;

  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;

      enable32Bit = true;
    };
    cpu.intel.updateMicrocode = true;
  };


  # Bootloader setup (UEFI)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 3. Hostname and Network
  networking = {
    hostName = "citadel";
    networkmanager.enable = true;
    firewall.enable = true;

    nameservers = [
      "192.168.1.150" # Primary: Pi-hole
    ];
  };

  # 4. Time zone and Locale
  time.timeZone = "Asia/Karachi";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # 5. User Account


xdg.portal = {
  enable = true;

  extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
  ];
};

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};

  # Fonts
  fonts.packages = with pkgs; [
    jetbrains-mono
    fira-code
    noto-fonts
    noto-fonts-cjk-sans
noto-fonts-color-emoji
  ];

  # 7. Enable NixOS flakes & new CLI commands (recommended)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

}

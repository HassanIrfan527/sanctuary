{ config, pkgs, ... }:

{
  # 1. Include hardware settings (automatically generated during installation)
  imports = [
    ./hardware-configuration.nix
  ];

  # 2. Bootloader setup (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 3. Hostname and Network
  networking.hostName = "404mind";
  networking.networkmanager.enable = true;

  # 4. Time zone and Locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # 5. User Account
  users.users.alex = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # 'wheel' enables sudo access
    packages = with pkgs; [
      firefox
      git
    ];
  };

  # 6. System Packages (available to all users)
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
  ];

  # 7. Enable NixOS flakes & new CLI commands (recommended)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 8. State version (Do NOT change this after installation, even when upgrading!)
  system.stateVersion = "24.11"; 
}

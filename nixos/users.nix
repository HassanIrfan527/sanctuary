{config, pkgs, ...}:

{
  users.mutableUsers = true;
  users.users.dweller = {
    isNormalUser = true;
    description = "Dweller";
    initialPassword = "dweller";

    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
    ]; # 'wheel' enables sudo access
  };
}

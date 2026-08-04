{ config, pkgs, ... }:

{
  programs = {
    niri.enable = true;
    zsh.enable = true;
    git.enable = true;
    steam.enable = true;
    direnv.enable = true;
    gamemode.enable = true;

    neovim = {
      enable = true;

      defaultEditor = true;

      viAlias = true;
      vimAlias = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}

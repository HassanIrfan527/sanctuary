
{ config, pkgs, ... }:

{

    services = {
        flatpak.enable = true;
        timesyncd.enable = true;
        libinput.enable = true;
        displayManager.sddm = {
            enable = true;

        wayland.enable = true;
        };

        tailscale.enable = true;
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };
        openssh.enable = true;
        resolved = {
              enable = true;
              settings = {
                Resolve = {
                  FallbackDNS = [
                    "9.9.9.9"
                    "149.112.112.112"
                  ];
                };
              };
        };
        fwupd.enable = true;
        fstrim.enable = true;
        udisks2.enable = true;
        gvfs.enable = true;

      };
}

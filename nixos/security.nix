
{config, pkgs, ...}:

{

security = {
sudo.wheelNeedsPassword = true;
rtkit.enable = true;
polkit.enable = true;
};

}

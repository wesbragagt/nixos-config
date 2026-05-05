{ pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--ssh" ];
  };

  environment.systemPackages = with pkgs; [ tailscale ];
}

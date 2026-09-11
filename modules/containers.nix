{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings.dns_enabled = true;
    extraPackages = with pkgs; [ podman-compose ];
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  # Podman bridge traffic needs forwarding for containers to reach external
  # services.
  networking.firewall.trustedInterfaces = [ "podman0" ];
  networking.firewall.checkReversePath = "loose";
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
}

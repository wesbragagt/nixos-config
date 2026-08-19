{ pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    extraPackages = with pkgs; [ podman-compose ];
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
  # Podman bridge traffic needs forwarding for containers to reach external
  # services, including OAuth endpoints used by better-ccflare.
  networking.firewall.trustedInterfaces = [ "podman0" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Re-apply forwarding before better-ccflare starts. Some network activation
  # paths reset the kernel value after the general sysctl service runs.
  systemd.services.podman-ip-forward = {
    wantedBy = [ "podman-better-ccflare.service" ];
    before = [ "podman-better-ccflare.service" ];
    serviceConfig.Type = "oneshot";
    script = "${pkgs.procps}/bin/sysctl -w net.ipv4.ip_forward=1";
  };
}

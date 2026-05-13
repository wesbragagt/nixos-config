{ pkgs, ... }:
{
  # Tailscale MagicDNS updates DNS dynamically. Use systemd-resolved instead
  # of plain resolvconf so NetworkManager and Tailscale can coordinate DNS
  # state after link changes/resume, and keep public fallback resolvers
  # available when the Tailscale DNS proxy is temporarily unavailable.
  networking.networkmanager.dns = "systemd-resolved";

  services.resolved = {
    enable = true;
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
    extraSetFlags = [ "--ssh" ];
  };

  # The observed failure mode after suspend was: IP routing worked, but
  # /etc/resolv.conf pointed only at Tailscale's 100.100.100.100 resolver and
  # DNS recovered immediately after restarting tailscaled. Refresh tailscaled on
  # resume so its DNS proxy and resolver registration are rebuilt after wake.
  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl try-restart tailscaled.service
  '';

  environment.systemPackages = with pkgs; [ tailscale ];
}

{ ... }:

{
  systemd.services.caddy-local-root-export = {
    description = "Export Caddy local root certificate";
    wantedBy = [ "multi-user.target" ];
    after = [ "caddy.service" ];
    requires = [ "caddy.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      root_ca=/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
      install -m 0644 "$root_ca" /run/caddy-local-root.crt
    '';
  };
  services.caddy = {
    enable = true;

    virtualHosts."https://ccflare.localhost".extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:35550
    '';
  };
}

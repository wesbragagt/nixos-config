{ config, lib, ... }:

let
  cfg = config.services.better-ccflare;
in
{
  options.services.better-ccflare.enable = lib.mkEnableOption "better-ccflare";

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/better-ccflare 0700 root root -"
    ];

    virtualisation.oci-containers = {
      backend = "podman";

      containers.better-ccflare = {
        image = "ghcr.io/tombii/better-ccflare:3.5.59";
        autoStart = true;
        user = "0:0";
        ports = [ "127.0.0.1:35550:8080" ];
        volumes = [ "/var/lib/better-ccflare:/data" ];
        environment = {
          NODE_ENV = "production";
          BETTER_CCFLARE_DB_PATH = "/data/better-ccflare.db";
          XDG_CONFIG_HOME = "/data";
          PORT = "8080";
          LB_STRATEGY = "session";
          DATA_RETENTION_DAYS = "30";
          REQUEST_RETENTION_DAYS = "30";
        };
      };
    };
  };
}

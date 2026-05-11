{
  lib,
  pkgs,
  config,
  ...
}:
let
  repoSecretsFile = ../secrets/secrets.yaml;
  sopsHostKeyPath = config.wes.host.sopsHostKeyPath;
  hasSopsHostKey = sopsHostKeyPath != null;
in
{
  services.pcscd.enable = lib.mkDefault true;

  sops = {
    age = {
      sshKeyPaths = lib.optionals hasSopsHostKey [ sopsHostKeyPath ];
      plugins = [ pkgs.age-plugin-yubikey ];
    };
    defaultSopsFormat = "yaml";
  }
  // lib.optionalAttrs (hasSopsHostKey && builtins.pathExists repoSecretsFile) {
    defaultSopsFile = repoSecretsFile;
    secrets = {
      exa_api_key = {
        owner = "wesbragagt";
      };
      bw_client_id = {
        key = "bitwarden/client_id";
        owner = "wesbragagt";
      };
      bw_client_secret = {
        key = "bitwarden/client_secret";
        owner = "wesbragagt";
      };
      bw_scope = {
        key = "bitwarden/scope";
        owner = "wesbragagt";
      };
      bw_grant_type = {
        key = "bitwarden/grant_type";
        owner = "wesbragagt";
      };
    };
  };
}

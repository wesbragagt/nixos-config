{ lib, pkgs, config, ... }:
let
  repoSecretsFile = ../secrets/secrets.yaml;
in
{
  services.pcscd.enable = lib.mkDefault true;

  sops = {
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      plugins = [ pkgs.age-plugin-yubikey ];
    };
    defaultSopsFormat = "yaml";
  } // lib.optionalAttrs (builtins.pathExists repoSecretsFile) {
    defaultSopsFile = repoSecretsFile;
  };
}

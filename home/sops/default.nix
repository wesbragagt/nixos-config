{ lib, pkgs, config, ... }:
let
  repoSecretsFile = ../../secrets/secrets.yaml;
  sopsAgeKeyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sopsShellExport = ''
    if [[ -f "${sopsAgeKeyFile}" ]]; then
      export SOPS_AGE_KEY_FILE="${sopsAgeKeyFile}"
    fi
  '';
  sopsWithYubikey = pkgs.sops.withAgePlugins (plugins: [ plugins.age-plugin-yubikey ]);
  sopsUpdatekeysAll = pkgs.writeShellScriptBin "sops-updatekeys-all" (builtins.readFile ../../scripts/sops-updatekeys.sh);
in
{
  home.packages = with pkgs; [
    age
    age-plugin-yubikey
    ssh-to-age
    yubikey-manager
    sopsWithYubikey
    sopsUpdatekeysAll
  ];

  sops = {
    age = {
      keyFile = sopsAgeKeyFile;
      plugins = [ pkgs.age-plugin-yubikey ];
    };
    defaultSopsFormat = "yaml";
  } // lib.optionalAttrs (builtins.pathExists repoSecretsFile) {
    defaultSopsFile = repoSecretsFile;
  };

  programs.bash.initExtra = lib.mkAfter sopsShellExport;
  programs.zsh.initContent = lib.mkAfter sopsShellExport;

  home.activation.ensureSopsAgeKeyDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.config/sops/age"
    chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age"
    touch "$HOME/.config/sops/age/keys.txt"
    chmod 600 "$HOME/.config/sops/age/keys.txt"
  '';
}

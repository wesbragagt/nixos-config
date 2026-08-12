{ lib, pkgs, config, repoRoot, ... }:
let
  cfg = config.wes.pi;
  repoSkillEntries = builtins.attrNames (builtins.readDir ./config/skills);
  linkSkillCommands = lib.concatMapStringsSep "\n" (name: ''
    $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/skills/${name}"
    $DRY_RUN_CMD ln -s "${cfg.configRoot}/skills/${name}" "$HOME/.pi/agent/skills/${name}"
  '') repoSkillEntries;
in
{
  options.wes.pi = {
    enable = lib.mkEnableOption "repo-managed pi agent config";

    configRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/pi/config";
      description = "Repo-managed pi agent config root.";
    };

    packageName = lib.mkOption {
      type = lib.types.str;
      default = "@earendil-works/pi-coding-agent";
      description = "npm package providing the pi CLI.";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "0.83.0";
      description = "Pinned pi CLI version installed into the npm global prefix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.installPinnedPi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      export PATH="${pkgs.nodejs}/bin:$NPM_CONFIG_PREFIX/bin:$PATH"
      $DRY_RUN_CMD mkdir -p "$NPM_CONFIG_PREFIX/bin"

      current=""
      if [ -x "$NPM_CONFIG_PREFIX/bin/pi" ]; then
        current="$($NPM_CONFIG_PREFIX/bin/pi --version 2>/dev/null || true)"
      fi

      if [ "$current" != "${cfg.version}" ]; then
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm --prefix "$NPM_CONFIG_PREFIX" install -g "${cfg.packageName}@${cfg.version}"
      fi
    '';

    home.activation.linkPiConfig = lib.hm.dag.entryAfter [ "installPinnedPi" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent/skills"

      $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/agents"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/agents" "$HOME/.pi/agent/agents"

      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/settings.json" "$HOME/.pi/agent/settings.json"

      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/AGENTS.md"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"

      ${linkSkillCommands}
    '';
  };
}

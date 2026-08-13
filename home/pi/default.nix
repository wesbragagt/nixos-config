{ lib, pkgs, config, repoRoot, ... }:
let
  cfg = config.wes.pi;
  mkSkillLinks = import ../lib/mk-skill-links.nix { inherit lib; };
  repoSkillLinks = mkSkillLinks {
    inherit (config.lib.file) mkOutOfStoreSymlink;
    skillsRoot = cfg.skillsRoot;
    targetPrefix = ".pi/agent/skills";
  };
in
{
  options.wes.pi = {
    enable = lib.mkEnableOption "repo-managed pi agent config";

    configRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/pi/config";
      description = "Repo-managed pi agent config root.";
    };

    skillsRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/skills";
      description = "Shared skills source root, linked into ~/.pi/agent/skills.";
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
    home.file = repoSkillLinks;

    # Skills used to be linked by the activation script below. Drop those
    # unmanaged symlinks so home-manager can take the paths over without a
    # checkLinkTargets clobber error.
    home.activation.removeLegacyPiSkillLinks = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      if [ -d "$HOME/.pi/agent/skills" ]; then
        find "$HOME/.pi/agent/skills" -maxdepth 1 -type l -exec $DRY_RUN_CMD rm -f {} +
      fi
    '';

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
      $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent"

      $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/agents"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/agents" "$HOME/.pi/agent/agents"

      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/settings.json" "$HOME/.pi/agent/settings.json"

      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/AGENTS.md"
      $DRY_RUN_CMD ln -s "${cfg.configRoot}/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
    '';
  };
}

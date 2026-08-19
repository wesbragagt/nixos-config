{ lib, pkgs, config, repoRoot, ... }:
let
  cfg = config.wes.omp;
  bunPkg = pkgs.callPackage ../../pkgs/bun-bin-1_3_14 { };

  mkSkillLinks = import ../lib/mk-skill-links.nix { inherit lib; };
  repoSkillLinks = mkSkillLinks {
    inherit (config.lib.file) mkOutOfStoreSymlink;
    skillsRoot = cfg.skillsRoot;
    targetPrefix = ".omp/agent/skills";
  };

  agentsLink = lib.optionalAttrs (builtins.pathExists ./config/agents) {
    ".omp/agent/agents".source = config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/agents";
  };
in
{
  options.wes.omp = {
    enable = lib.mkEnableOption "repo-managed OMP (Oh My Pi) agent config";

    configRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/omp/config";
      description = "Repo-managed OMP agent config root.";
    };

    skillsRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/skills";
      description = "Shared skills source root, linked into ~/.omp/agent/skills.";
    };

    packageName = lib.mkOption {
      type = lib.types.str;
      default = "@oh-my-pi/pi-coding-agent";
      description = "npm package providing the omp CLI (installed via bun global).";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "17.3.5";
      description = "Pinned omp CLI version installed into the bun global prefix.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".omp/agent/config.yml".source =
        config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/config.yml";
      ".omp/agent/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/AGENTS.md";
    }
    // agentsLink
    // repoSkillLinks;

    # OMP writes runtime files (config.yml updates, dbs) into ~/.omp/agent.
    # Drop any pre-existing plain files so home-manager can take over the
    # mutable out-of-store symlinks without a checkLinkTargets clobber error.
    home.activation.removeLegacyOmpConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      for f in config.yml AGENTS.md; do
        target="$HOME/.omp/agent/$f"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
          $DRY_RUN_CMD rm -f "$target"
        fi
      done
    '';

    home.activation.installPinnedOmp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export BUN_INSTALL="$HOME/.bun"
      export PATH="${bunPkg}/bin:$BUN_INSTALL/bin:$PATH"
      $DRY_RUN_CMD mkdir -p "$BUN_INSTALL/bin"

      current=""
      if [ -x "$BUN_INSTALL/bin/omp" ]; then
        current="$("$BUN_INSTALL/bin/omp" --version 2>/dev/null | sed 's#^omp/##')"
      fi

      if [ "$current" != "${cfg.version}" ]; then
        $DRY_RUN_CMD ${bunPkg}/bin/bun install -g "${cfg.packageName}@${cfg.version}"
      fi
    '';
  };
}

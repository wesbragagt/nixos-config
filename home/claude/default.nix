{ lib, pkgs, config, repoRoot, ... }:
let
  cfg = config.wes.claudeCode;
  claudeCodePackage = pkgs.callPackage ../../pkgs/claude-code { };
in
{
  options.wes.claudeCode = {
    enable = lib.mkEnableOption "repo-managed Claude Code";

    package = lib.mkOption {
      type = lib.types.package;
      default = claudeCodePackage;
      defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/claude-code { }";
      description = "Claude Code package to install.";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        cc = "claude-code";
        claude = "claude-code";
      };
      description = "Shell aliases to expose for Claude Code.";
    };

    configRoot = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/claude/config";
      description = "Repo-managed Claude Code config root.";
    };

    sandbox = {
      enable = lib.mkEnableOption "future Claude Code sandbox support";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/agents";
    home.file.".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/skills";
    home.file.".claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/commands";
    home.file.".claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${cfg.configRoot}/rules";

    programs.bash.shellAliases = cfg.aliases;
    programs.zsh.shellAliases = cfg.aliases;
  };
}

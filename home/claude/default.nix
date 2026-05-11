{ lib, pkgs, config, repoRoot, ... }:
let
  cfg = config.wes.claudeCode;
in
{
  options.wes.claudeCode = {
    enable = lib.mkEnableOption "repo-managed Claude Code";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code;
      defaultText = lib.literalExpression "pkgs.claude-code";
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

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "${repoRoot}/home/claude/config";
      description = "Repo-managed Claude Code configuration directory to symlink to ~/.claude.";
    };

    sandbox = {
      enable = lib.mkEnableOption "future Claude Code sandbox support";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".claude".source = config.lib.file.mkOutOfStoreSymlink cfg.configDir;

    programs.bash.shellAliases = cfg.aliases;
    programs.zsh.shellAliases = cfg.aliases;
  };
}

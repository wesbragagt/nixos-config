# Shared ccflare pointer, read from config.yml so Claude Code and OMP
# route through the same endpoint, API key, and model list.
{ lib, repoRoot, ... }:
let
  configRoot = "${repoRoot}/home/ccflare";
  raw = builtins.readFile "${configRoot}/config.yml";
  trimmedLines = map lib.strings.trim (lib.splitString "\n" raw);

  valueOf =
    key:
    let
      prefix = "${key}:";
      matches = builtins.filter (l: lib.hasPrefix prefix l) trimmedLines;
    in
    if matches == [ ] then null else lib.strings.trim (lib.removePrefix prefix (builtins.head matches));

  modelsIndex = lib.lists.findFirstIndex (l: l == "models:") null trimmedLines;
  modelsListLines =
    if modelsIndex == null then
      [ ]
    else
      lib.sublist (modelsIndex + 1) (builtins.length trimmedLines - modelsIndex - 1) trimmedLines;
  models = map (l: lib.removePrefix "- " l) (builtins.filter (l: lib.hasPrefix "- " l) modelsListLines);
in
{
  options.wes.ccflare = {
    configRoot = lib.mkOption {
      type = lib.types.str;
      default = configRoot;
      description = "Directory holding the shared ccflare config.yml.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = valueOf "baseUrl";
      description = "ccflare base URL, read from config.yml.";
    };

    apiKey = lib.mkOption {
      type = lib.types.str;
      default = valueOf "apiKey";
      description = "ccflare API key, read from config.yml.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = models;
      description = "Model IDs exposed through ccflare, read from config.yml.";
    };
  };
}

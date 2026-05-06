{ config, ... }:
{
  _module.args.repoRoot = "${config.home.homeDirectory}/nixos-config";
}

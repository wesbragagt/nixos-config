{ lib, hostProfile ? { }, ... }:
let
  isHeadless = hostProfile.headless or false;
in
{
  imports = [
    ./packages
    ./npm
    ./bun
    ./shell
    ./git
    ./ssh
    ./yazi
  ]
  ++ lib.optionals (!isHeadless) [
    ./apps
  ];
}

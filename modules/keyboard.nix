{ pkgs, ... }:
let
  it = pkgs.interception-tools;
  c2e = pkgs.interception-tools-plugins.caps2esc;
in
{
  services.interception-tools = {
    enable = true;
    plugins = [ c2e ];
    udevmonConfig = ''
      - JOB: "${it}/bin/intercept -g $DEVNODE | ${c2e}/bin/caps2esc | ${it}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };
}

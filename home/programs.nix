{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wofi
    pavucontrol
    grim
    slurp
    wl-clipboard
    networkmanagerapplet
    iwgtk
  ];

  programs.chromium = {
    enable = true;
    commandLineArgs = [ "--ozone-platform=wayland" ];
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };
    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
    };
  };

  programs.foot = {
    enable = true;
    settings.main.font = "JetBrainsMono Nerd Font:size=12";
  };
}

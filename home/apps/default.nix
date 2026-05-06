{ pkgs, config, repoRoot, ... }:
let
  rofiColorsDir = "${repoRoot}/rofi/colors";
  rofiLaunchersDir = "${repoRoot}/rofi/launchers";
in
{
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
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
      };
      colors.alpha = 0.8;
    };
  };

  programs.obsidian = {
    enable = true;
    vaults."notes-live-sync" = {
      target = "notes-live-sync";
    };
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.foot}/bin/foot";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = "${config.xdg.configHome}/rofi/launchers/type-2/style-1.rasi";
  };

  home.file.".cache/nwg-dock-pinned".text = ''
    foot
    chromium-browser
    thunar
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
    };
  };

  xdg.configFile = {
    "rofi/colors".source = config.lib.file.mkOutOfStoreSymlink rofiColorsDir;
    "rofi/launchers".source = config.lib.file.mkOutOfStoreSymlink rofiLaunchersDir;
    "workmux/config.yaml".text = "nerdfont: true\n";
    "swappy/config".text = ''
      [Default]
      early_exit=true
      auto_save=true
      save_dir=$HOME/Screenshots
    '';
    "waypaper/config.ini".text = ''
      [Settings]
      language = en
      folder = /home/wesbragagt/Wallpapers
      monitors = All
      backend = swww
      fill = fill
      sort = name
      color = #ffffff
      subfolders = False
      show_hidden = False
      show_gifs_only = False
      number_of_columns = 3
      swww_transition_type = any
      swww_transition_step = 90
      swww_transition_angle = 0
      swww_transition_duration = 2
      swww_transition_fps = 60
      use_xdg_state = False
    '';
  };
}

{ pkgs, config, inputs, ... }:
{
  home.packages = with pkgs; [
    pavucontrol
    grim
    slurp
    wl-clipboard
    networkmanagerapplet
    iwgtk
    inputs.zen-browser.packages.${pkgs.system}.default
    bitwarden-desktop
    bitwarden-cli
    gh
    gtk3
    (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../scripts/rofi-freq.sh))
    nwg-dock-hyprland
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

  programs.bash = {
    enable = true;
    initExtra = ''
      rebuild() {
        sudo nixos-rebuild switch --impure --flake ~/nixos-config#"$(hostname)" "$@"
      }
    '';
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    terminal = "screen-256color";
    escapeTime = 10;
    historyLimit = 50000;
    baseIndex = 1;
    mouse = true;
  };
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "${pkgs.kitty}/bin/kitty";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
    };
    theme = "${config.xdg.configHome}/rofi/launchers/type-2/style-1.rasi";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github_key.pub";
        extraOptions = {
          IdentityAgent = "~/.bitwarden-ssh-agent.sock";
        };
      };
    };
  };

  xdg.configFile = {
    "rofi/launchers/type-2/style-1.rasi".source = ../rofi/launchers/type-2/style-1.rasi;
    "rofi/launchers/type-2/shared/colors.rasi".source = ../rofi/launchers/type-2/shared/colors.rasi;
    "rofi/launchers/type-2/shared/fonts.rasi".source = ../rofi/launchers/type-2/shared/fonts.rasi;
    "rofi/colors/catppuccin.rasi".source = ../rofi/colors/catppuccin.rasi;
  };

}

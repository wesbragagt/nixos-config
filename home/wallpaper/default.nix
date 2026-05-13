{ pkgs, ... }:
let
  wallpaperRandom = pkgs.writeShellApplication {
    name = "wallpaper-random";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.swww
    ];
    text = ''
      wallpaper_dir="$HOME/Wallpapers"

      if [[ ! -d "$wallpaper_dir" ]]; then
        exit 0
      fi

      mapfile -d $'\0' wallpapers < <(
        find "$wallpaper_dir" -type f \
          \( \
            -iname '*.avif' -o \
            -iname '*.bmp' -o \
            -iname '*.gif' -o \
            -iname '*.jpeg' -o \
            -iname '*.jpg' -o \
            -iname '*.png' -o \
            -iname '*.pnm' -o \
            -iname '*.svg' -o \
            -iname '*.tga' -o \
            -iname '*.tiff' -o \
            -iname '*.webp' \
          \) \
          -print0
      )

      if (( ''${#wallpapers[@]} == 0 )); then
        exit 0
      fi

      if ! swww query >/dev/null 2>&1; then
        exit 0
      fi

      wallpaper="''${wallpapers[RANDOM % ''${#wallpapers[@]}]}"

      exec swww img "$wallpaper" \
        --transition-type random \
        --transition-duration 2 \
        --transition-fps 60 \
        --transition-step 90
    '';
  };
in
{
  home.packages = [ wallpaperRandom ];

  systemd.user.services.wallpaper-random = {
    Unit = {
      Description = "Set a random wallpaper from ~/Wallpapers";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperRandom}/bin/wallpaper-random";
    };
  };

  systemd.user.timers.wallpaper-random = {
    Unit = {
      Description = "Cycle random wallpapers from ~/Wallpapers";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };

    Timer = {
      OnActiveSec = "30s";
      OnUnitActiveSec = "5min";
      Unit = "wallpaper-random.service";
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };
}

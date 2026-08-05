{
  pkgs,
  inputs,
  lib,
  hostProfile ? { },
  ...
}:
let
  isLaptop = hostProfile.isLaptop or false;
  hasWireless = hostProfile.hasWireless or false;
  unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  # Python wheels loaded via the Nix-managed interpreter use dlopen(), so they
  # need LD_LIBRARY_PATH directly; nix-ld alone only helps foreign executables.
  wrappedPython = pkgs.symlinkJoin {
    name = "python3-wrapped";
    paths = [ pkgs.python3 ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in "$out"/bin/python*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
          wrapProgram "$bin" --prefix LD_LIBRARY_PATH : /run/current-system/sw/share/nix-ld/lib
        fi
      done
    '';
  };
  roamShareAudio = pkgs.writeShellScriptBin "roam-share-audio" ''
    set -euo pipefail

    service="roam-share-audio.service"
    action="''${1:-status}"

    case "$action" in
      start|stop|restart|status)
        ${pkgs.systemd}/bin/systemctl --user "$action" "$service"
        ;;
      *)
        echo "Usage: roam-share-audio [start|stop|restart|status]" >&2
        exit 2
        ;;
    esac
  '';
  clipboardSelector = pkgs.writeShellScriptBin "clipboard-selector" ''
    set -euo pipefail

    export PATH=${
      lib.makeBinPath [
        pkgs.cliphist
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.rofi
        pkgs.wl-clipboard
      ]
    }:$PATH

    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/clipboard-selector"
    mkdir -p "$cache_dir"

    list_entries() {
      cliphist list | while IFS= read -r entry; do
        if grep -Eq '\[\[ binary data .* (png|jpe?g|gif|webp|bmp|tiff|svg)' <<<"$entry"; then
          id="''${entry%%$'\t'*}"
          format="$(grep -Eo '(png|jpe?g|gif|webp|bmp|tiff|svg)' <<<"$entry" | head -n1)"
          case "$format" in
            jpg|jpeg) mime="image/jpeg"; extension="jpg" ;;
            svg) mime="image/svg+xml"; extension="svg" ;;
            *) mime="image/$format"; extension="$format" ;;
          esac
          thumbnail="$cache_dir/$id.$extension"

          if [ ! -s "$thumbnail" ]; then
            printf '%s' "$id" | cliphist decode >"$thumbnail" || rm -f "$thumbnail"
          fi

          image_details="$(grep -Eo '[0-9]+ KiB [^]]+' <<<"$entry" | head -n1)"
          label="$id	🖼 $image_details"

          if [ -s "$thumbnail" ]; then
            printf '%s\0icon\x1f%s\n' "$label" "$thumbnail"
          else
            printf '%s\n' "$label"
          fi
        else
          printf '%s\n' "$entry"
        fi
      done
    }

    selection="$(list_entries | rofi -dmenu -i -show-icons -p clipboard -no-custom -theme-str 'element-icon { size: 96px; }')"
    [ -n "$selection" ] || exit 0

    id="''${selection%%$'\t'*}"

    if grep -Eq '^[0-9]+$' <<<"$id" && grep -Eq '🖼 .*(png|jpe?g|gif|webp|bmp|tiff|svg)' <<<"$selection"; then
      format="$(grep -Eo '(png|jpe?g|gif|webp|bmp|tiff|svg)' <<<"$selection" | head -n1)"
      case "$format" in
        jpg|jpeg) mime="image/jpeg" ;;
        svg) mime="image/svg+xml" ;;
        *) mime="image/$format" ;;
      esac
      printf '%s' "$id" | cliphist decode | wl-copy --type "$mime"
    else
      printf '%s\n' "$selection" | cliphist decode | wl-copy
    fi
  '';
in
{
  home.packages =
    with pkgs;
    [
      # wayland / audio
      pavucontrol
      roamShareAudio
      clipboardSelector
      wl-clipboard
      cliphist
      wlr-randr
      libnotify

      # screenshot / recording
      grim
      slurp
      swappy
      wf-recorder

      # cli tools
      inputs.exacli.packages.${pkgs.stdenv.hostPlatform.system}.default
      gh
      (pkgs.callPackage ../../pkgs/tuicr { })
      jq
      yq-go
      go
      fd
      sesh
      uv
      pnpm
      wrappedPython
      stow
      tldr
      (
        (pkgs.callPackage "${inputs.nur-combined}/repos/sikmir/pkgs/by-name/re/revdiff/package.nix" {
          buildGoModule = pkgs.buildGo126Module;
        }).overrideAttrs
        (_old: {
          allowGoReference = true;
        })
      )
      (pkgs.callPackage ../../pkgs/agent-browser { })
      (pkgs.callPackage ../../pkgs/excalidraw-cli { })

      # secrets / auth
      bitwarden-desktop
      libsecret

      # desktop / ui
      gtk3
      nwg-dock-hyprland
      rofi-calc
      waypaper
      swww
      slack
      unstable.signal-desktop
      (pkgs.callPackage ../../pkgs/roam { })
      (pkgs.callPackage ../../pkgs/openpencil { })
      (pkgs.callPackage ../../pkgs/openpencil-cli { })
      libreoffice-fresh

      # media
      playerctl
      mpv
      imv

      # data
      csvlens # interactive CSV viewer
      (pkgs.callPackage ../../pkgs/duckdb-bin-1_5_3 { }) # in-process analytical SQL
      harlequin # terminal database UI
      (symlinkJoin {
        name = "dbeaver-bin-x11";
        paths = [ dbeaver-bin ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/dbeaver" \
            --set GDK_BACKEND x11 \
            --set SWT_GTK3 1
        '';
      }) # desktop database client; force XWayland to avoid SWT dialog issues on Hyprland

      # git
      lazygit
      delta

      # markdown viewing
      glow

      # scripts
      (pkgs.writeShellScriptBin "rofi-bookmarks" (builtins.readFile ../../scripts/rofi-bookmarks.sh))
      (pkgs.writeShellScriptBin "edit-bookmarks" (builtins.readFile ../../scripts/edit-bookmarks.sh))
      (pkgs.writeShellScriptBin "rofi-freq" (builtins.readFile ../../scripts/rofi-freq.sh))
      (pkgs.writeShellScriptBin "file-fzf" (builtins.readFile ../../scripts/sf.sh))
      (pkgs.writeShellScriptBin "grep-fzf" (builtins.readFile ../../scripts/sg.sh))
      (pkgs.writeShellScriptBin "wf-record" (builtins.readFile ../../scripts/wf-recorder.sh))
      (pkgs.callPackage ../../pkgs/workmux { })
    ]
    ++ lib.optionals hasWireless [
      # network / Wi-Fi tray helpers
      networkmanagerapplet
      iwgtk
    ]
    ++ lib.optionals isLaptop [
      (pkgs.writeShellScriptBin "battery-estimate" (builtins.readFile ../../scripts/battery-estimate.sh))
    ];

  systemd.user.services.roam-share-audio = {
    Unit = {
      Description = "Roam desktop audio virtual microphone";
      After = [ "pipewire.service" ];
      Requires = [ "pipewire.service" ];
    };
    Service = {
      ExecStart = ''
        ${pkgs.pipewire}/bin/pw-loopback \
          --name roam-desktop-audio \
          --capture @DEFAULT_AUDIO_SINK@ \
          --playback-props='media.class=Audio/Source node.name=roam-desktop-audio node.description="Roam Desktop Audio"'
      '';
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

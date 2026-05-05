{ pkgs, ... }:
let
  sddmTheme = pkgs.catppuccin-sddm.override {
    flavor = "mocha";
    accent = "mauve";
    font = "Noto Sans";
    fontSize = "11";
    userIcon = true;
  };
in
{
  services.gnome.gnome-keyring.enable = true;

  services.displayManager = {
    defaultSession = "hyprland";

    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "catppuccin-mocha-mauve";
      extraPackages = [ sddmTheme ];
      settings = {
        Users = {
          RememberLastUser = true;
          RememberLastSession = true;
        };
        Theme = {
          CursorTheme = "capitaine-cursors";
          CursorSize = 24;
        };
      };
    };
  };

  environment.systemPackages = [ sddmTheme ];

  system.activationScripts.sddmDefaultUser = ''
    if [ ! -e /var/lib/sddm/state.conf ]; then
      install -o sddm -g sddm -m 0644 /dev/null /var/lib/sddm/state.conf
      cat > /var/lib/sddm/state.conf <<'EOF'
[Last]
User=wesbragagt
Session=hyprland.desktop
EOF
      chown sddm:sddm /var/lib/sddm/state.conf
    fi
  '';
}

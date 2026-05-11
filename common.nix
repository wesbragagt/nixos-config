{ config, pkgs, ... }:

{
  imports = [
    ./modules/host-profile.nix
    ./modules/graphics.nix
    ./modules/audio.nix
    ./modules/fonts.nix
    ./modules/hyprland.nix
    ./modules/login.nix
    ./modules/keyboard.nix
    ./modules/tailscale.nix
    ./modules/containers.nix
    ./modules/sops.nix
  ];

  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.wesbragagt = {
    isNormalUser = true;
    description = "wesbragagt";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "podman"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFOS29+SNkpKHCMcaonfqERiIr/xKPuxu4sVv5yyIG33 wesbragagt@mac"
    ];
  };

  programs.zsh.enable = true;

  nix.package = pkgs.nixVersions.stable;
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.optimise.automatic = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      chromium = prev.chromium.override { enableWideVine = true; };
    })
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
  ];

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  services.openssh.enable = true;
  security.sudo.wheelNeedsPassword = false;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%";
  };
}

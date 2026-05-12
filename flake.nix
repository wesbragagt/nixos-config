{
  description = "wesbragagt's NixOS + home-manager flake (multi-host)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    exacli = {
      url = "github:wesbragagt/exacli";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    chromium-webapps = {
      url = "github:chobbledotcom/nix-chromium-webapps";
    };
    kanagawa-yazi = {
      url = "github:dangooddd/kanagawa.yazi";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      defaultSystem = "x86_64-linux";

      defaultHostProfile = {
        isLaptop = false;
        hasWireless = false;
        graphics = "generic";
        swapAltSuper = true;
        hypridle = {
          lockTimeout = 300;
          dpmsTimeout = 330;
          suspendTimeout = null;
          suspendRequiresNoSsh = false;
        };
        sopsHostKeyPath = null;
        useHomeSopsSecrets = false;
      };

      mkHost =
        {
          name,
          system ? defaultSystem,
          hostProfile ? { },
        }:
        let
          resolvedHostProfile = (lib.recursiveUpdate defaultHostProfile hostProfile) // {
            inherit name;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            hostProfile = resolvedHostProfile;
          };
          modules = [
            (./hosts + "/${name}")
            inputs.sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              wes.host = lib.removeAttrs resolvedHostProfile [
                "name"
                "useHomeSopsSecrets"
              ];

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.extraSpecialArgs = {
                inherit inputs;
                hostProfile = resolvedHostProfile;
              };
              home-manager.users.wesbragagt = import ./home/wesbragagt.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        nixos-hp = mkHost {
          name = "nixos-hp";
          hostProfile = {
            isLaptop = true;
            hasWireless = true;
            graphics = "intel";
            hypridle = {
              lockTimeout = 300;
              dpmsTimeout = 330;
              suspendTimeout = 1800;
            };
            sopsHostKeyPath = "/etc/ssh/ssh_host_ed25519_key";
          };
        };

        icebox = mkHost {
          name = "icebox";
          hostProfile = {
            isLaptop = false;
            hasWireless = false;
            graphics = "amd";
            swapAltSuper = false;
            hypridle = {
              lockTimeout = 900;
              dpmsTimeout = 1200;
              suspendTimeout = 3600;
              suspendRequiresNoSsh = true;
            };
            sopsHostKeyPath = "/etc/ssh/ssh_host_ed25519_key";
          };
        };
      };

      # Standalone home-manager for non-NixOS Linux machines.
      # Apply with: nix run home-manager/master -- switch --flake .#wesbragagt
      homeConfigurations.wesbragagt = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${defaultSystem};
        extraSpecialArgs = {
          inherit inputs;
          hostProfile = defaultHostProfile // {
            name = "standalone";
            useHomeSopsSecrets = true;
          };
        };
        modules = [
          ./home/standalone-policy.nix
          ./home/wesbragagt.nix
        ];
      };
    };
}

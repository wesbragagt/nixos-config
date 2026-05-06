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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    exacli = {
      url = "github:wesbragagt/exacli";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    chromium-webapps = {
      url = "github:chobbledotcom/nix-chromium-webapps";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, zen-browser, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.nixos-hp = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos-hp
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.wesbragagt = import ./home/wesbragagt.nix;
          }
        ];
      };

      # Standalone home-manager for non-NixOS Linux machines.
      # Apply with: nix run home-manager/master -- switch --flake .#wesbragagt
      homeConfigurations.wesbragagt = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/wesbragagt.nix ];
      };
    };
}

---
title: Packaging Programs from Source and Writing Nix Modules
date: 2026-05-05
status: active
tags:
  - type/reference
  - nix
  - nixos
  - packaging
---

# Packaging Programs from Source and Writing Nix Modules

## stdenv.mkDerivation

`stdenv.mkDerivation` is the core function for building a package from source. It sets up a reproducible build environment and runs a standard sequence of phases.

```nix
{ stdenv, fetchFromGitHub, cmake, pkg-config, libfoo }:

stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.2.3";

  src = fetchFromGitHub {
    owner = "user";
    repo  = "my-tool";
    rev   = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs       = [ libfoo ];
}
```

## Fetching Sources

| Fetcher | Use when |
|---------|----------|
| `fetchFromGitHub { owner repo rev sha256 }` | GitHub repos |
| `fetchurl { url sha256 }` | Direct tarballs/files |
| `fetchgit { url rev sha256 }` | Arbitrary git repos |

To get the correct `sha256`, use a fake hash first — Nix will error and print the real one:

```nix
sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
# nix build will fail and print: got: sha256-<real hash>
```

Or use `nix-prefetch-url` / `nix-prefetch-github`.

## buildInputs vs nativeBuildInputs

- **`nativeBuildInputs`** — tools needed *during the build*, run on the build machine (compilers, `cmake`, `pkg-config`, `meson`, `makeWrapper`). Do not end up in the output.
- **`buildInputs`** — libraries/packages needed *at runtime* or linked against. End up in the output's closure.

```nix
nativeBuildInputs = [ cmake pkg-config ];   # build tools only
buildInputs       = [ openssl zlib ];        # linked libraries
```

## Build Phases

Phases run in this order. Override any by defining it as a string:

| Phase | Default behavior | Override key |
|-------|-----------------|--------------|
| `unpackPhase` | Extract `src` | `unpackPhase` |
| `patchPhase` | Apply `patches` | `patchPhase` |
| `configurePhase` | Run `./configure` | `configurePhase` |
| `buildPhase` | Run `make` | `buildPhase` |
| `checkPhase` | Run `make check` (skipped by default) | `checkPhase` |
| `installPhase` | Run `make install` | `installPhase` |
| `fixupPhase` | Strip binaries, patch shebangs | `fixupPhase` |

Custom install example:

```nix
installPhase = ''
  mkdir -p $out/bin
  cp my-tool $out/bin/my-tool
  chmod +x $out/bin/my-tool
'';
```

`$out` is the Nix store path for this package's outputs. Always install into `$out`.

## pkgs.callPackage

`callPackage` auto-injects dependencies by matching the function's parameter names against `pkgs` attributes. Store derivations in separate files and wire them in at a composition root.

**pkgs/my-tool/default.nix**:
```nix
{ stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.0.0";
  src = fetchFromGitHub { owner = "x"; repo = "my-tool"; rev = version; sha256 = "..."; };
  nativeBuildInputs = [ cmake ];
}
```

**flake.nix or overlay**:
```nix
my-tool = pkgs.callPackage ./pkgs/my-tool { };
```

Override a specific input by passing it explicitly:

```nix
my-tool = pkgs.callPackage ./pkgs/my-tool { stdenv = pkgs.clangStdenv; };
```

## Writing a NixOS / Home Manager Module

A module has two sections: `options` (the interface) and `config` (the implementation). Keep them in separate files from the derivation.

**modules/my-tool.nix**:
```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.my-tool;
in
{
  options.programs.my-tool = {
    enable = lib.mkEnableOption "my-tool";

    package = lib.mkOption {
      type        = lib.types.package;
      default     = pkgs.callPackage ../pkgs/my-tool { };
      description = "The my-tool package to use.";
    };

    extraArgs = lib.mkOption {
      type    = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
```

**home/wesbragagt.nix** — import and enable:
```nix
imports = [ ../modules/my-tool.nix ];

programs.my-tool = {
  enable    = true;
  extraArgs = [ "--verbose" ];
};
```

## End-to-End Example

Directory layout:
```
nixos-config/
  pkgs/
    battery-estimate/
      default.nix      # derivation
  modules/
    battery-estimate.nix  # module
  home/
    wesbragagt.nix     # enables the module
```

**pkgs/battery-estimate/default.nix**:
```nix
{ stdenv, fetchFromGitHub, bash }:

stdenv.mkDerivation rec {
  pname   = "battery-estimate";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner  = "user";
    repo   = "battery-estimate";
    rev    = "v${version}";
    sha256 = "sha256-...";
  };

  nativeBuildInputs = [ bash ];

  installPhase = ''
    mkdir -p $out/bin
    cp battery-estimate.sh $out/bin/battery-estimate
    chmod +x $out/bin/battery-estimate
  '';
}
```

**modules/battery-estimate.nix**:
```nix
{ config, lib, pkgs, ... }:

let cfg = config.programs.battery-estimate; in
{
  options.programs.battery-estimate.enable = lib.mkEnableOption "battery-estimate";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.callPackage ../pkgs/battery-estimate { } ];
  };
}
```

## Key Tips

- Run `nix build` with a bogus hash to let Nix tell you the correct one.
- Use `nix-shell -p nix-prefetch-github` to get hashes upfront.
- Prefer `nativeBuildInputs` for anything that only runs at build time — it keeps closures smaller.
- Keep derivations (`pkgs/`) and modules (`modules/`) separate; compose them at the flake/home level.
- Use `lib.mkIf` to guard `config` blocks — never put bare config at the top level of a module.

## Sources

- [Fundamentals of Stdenv — Nix Pills](https://nixos.org/guides/nix-pills/19-fundamentals-of-stdenv)
- [callPackage — nix.dev](https://nix.dev/tutorials/callpackage.html)
- [pkgs.callPackage — NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/nixpkgs/callpackage)
- [mkDerivation — nix-docs](https://blog.ielliott.io/nix-docs/mkDerivation.html)
- [Fetchers — nixpkgs manual](https://ryantm.github.io/nixpkgs/builders/fetchers/)
- [Home Manager options](https://home-manager.dev/manual/25.11/options.xhtml)

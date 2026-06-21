# Muvel for Nix

[Muvel](https://github.com/KimuSoft/muvel-public)을 NixOS와 macOS용으로 패키징한 flake입니다.

| System | Package |
| --- | --- |
| `x86_64-linux` | Debian 패키지 |
| `aarch64-darwin` | Apple Silicon DMG |
| `x86_64-darwin` | Intel DMG |

## Nix run

```console
nix run github:imnyang/muvel-nix
```

## NixOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    muvel.url = "github:imnyang/muvel-nix";
  };

  outputs = { nixpkgs, inputs, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ({ pkgs, ... }: {
          environment.systemPackages = [
            inputs.muvel.packages.${pkgs.stdenv.hostPlatform.system}.muvel
          ];
        })
      ];
    };
  };
}
```

## macOS

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    muvel.url = "github:imnyang/muvel-nix";
  };

  outputs = { nix-darwin, inputs, ... }: {
    darwinConfigurations.my-mac = nix-darwin.lib.darwinSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-darwin";
          environment.systemPackages = [
            inputs.muvel.packages.${pkgs.stdenv.hostPlatform.system}.muvel
          ];
        })
      ];
    };
  };
}
```

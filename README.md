# Bixby Studio for NixOS

Nix flake packaging Samsung Bixby Developer Studio for x86_64 Linux.

Samsung currently publishes Bixby Developer Studio 8.23.1-r24c.2843029 for Linux. This flake wraps the vendor application in an FHS environment with the legacy runtime libraries its Electron build expects.

## Run without installing

```sh
nix run github:lost-rob0t/bixby-studio
```

## Use as a flake input

```nix
{
  inputs.bixby-studio.url = "github:lost-rob0t/bixby-studio";

  outputs = { nixpkgs, bixby-studio, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Example package reference:
      packages.${system}.bixby-studio =
        bixby-studio.packages.${system}.default;
    };
}
```

For Home Manager, add the package rather than the flake input itself:

```nix
home.packages = [
  inputs.bixby-studio.packages.${pkgs.system}.default
];
```

## GPU acceleration

The launcher disables GPU acceleration by default because the old Electron runtime can be fragile against modern NixOS graphics stacks. To try native GPU acceleration:

```sh
BIXBY_STUDIO_ENABLE_GPU=1 nix run github:lost-rob0t/bixby-studio
```

## License

Bixby Developer Studio is proprietary Samsung/Viv Labs software. This repository only contains Nix packaging metadata; the application is fetched from Samsung's distribution infrastructure at build time.

{
  description = "Bixby Developer Studio packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Kept in the input graph for lock-file compatibility with the original
    # flake. The package no longer needs nixGL just to start.
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, flake-utils, nixgl }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        version = "8.23.1-r24c.2843029";

        bixbyStudioUnwrapped = pkgs.stdenvNoCC.mkDerivation {
          pname = "bixby-studio-unwrapped";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://bixby-studio.s3.amazonaws.com/stable-c4f5c975-1d91-4065-b661-633de7275e11/BixbyStudio-${version}-linux.rpm";
            hash = "sha256-wae96w06w8GyXOVKKHd1ddq0ANQab0XIqug2fyC1NrM=";
          };

          nativeBuildInputs = with pkgs; [ rpm cpio ];

          unpackPhase = ''
            runHook preUnpack
            rpm2cpio "$src" | cpio -idm
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -a ./. "$out/"
            runHook postInstall
          '';

          dontConfigure = true;
          dontBuild = true;
        };

        launcher = pkgs.writeShellScript "bixby-studio-launcher" ''
          set -euo pipefail

          candidates=(
            "${bixbyStudioUnwrapped}/opt/Bixby Studio/bixbystudio"
            "${bixbyStudioUnwrapped}/usr/opt/Bixby Studio/bixbystudio"
          )

          executable=""
          for candidate in "''${candidates[@]}"; do
            if [[ -x "$candidate" ]]; then
              executable="$candidate"
              break
            fi
          done

          if [[ -z "$executable" ]]; then
            echo "Bixby Studio executable was not found in the vendor package" >&2
            exit 1
          fi

          flags=(
            --no-sandbox
            --disable-dev-shm-usage
          )

          # GPU acceleration can be enabled explicitly once the host GL stack
          # is known to cooperate with this old Electron build.
          if [[ "''${BIXBY_STUDIO_ENABLE_GPU:-0}" != "1" ]]; then
            flags+=(--disable-gpu)
          fi

          exec "$executable" "''${flags[@]}" "$@"
        '';

        desktopItem = pkgs.makeDesktopItem {
          name = "bixby-studio";
          desktopName = "Bixby Studio";
          genericName = "Bixby Developer Studio";
          comment = "Develop and test Samsung Bixby capsules";
          exec = "bixby-studio %U";
          terminal = false;
          categories = [ "Development" "IDE" ];
          startupNotify = true;
        };

        bixbyStudio = pkgs.buildFHSEnv {
          name = "bixby-studio";

          targetPkgs = pkgs: with pkgs; [
            bixbyStudioUnwrapped

            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            dbus
            expat
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libGL
            libdrm
            libglvnd
            libnotify
            libsecret
            libuuid
            libxkbcommon
            mesa
            nspr
            nss
            openssl_1_1
            pango
            stdenv.cc.cc.lib
            systemd
            util-linux

            xorg.libX11
            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXinerama
            xorg.libXrandr
            xorg.libXrender
            xorg.libXScrnSaver
            xorg.libXtst
            xorg.libxcb
            xorg.libxshmfence
          ];

          runScript = launcher;

          extraInstallCommands = ''
            mkdir -p "$out/share/applications"
            cp ${desktopItem}/share/applications/bixby-studio.desktop \
              "$out/share/applications/bixby-studio.desktop"
          '';

          meta = with pkgs.lib; {
            description = "Samsung Bixby Developer Studio IDE";
            homepage = "https://bixbydevelopers.com/";
            license = licenses.unfree;
            mainProgram = "bixby-studio";
            platforms = [ "x86_64-linux" ];
          };
        };

        app = {
          type = "app";
          program = "${bixbyStudio}/bin/bixby-studio";
        };
      in
      {
        packages = {
          default = bixbyStudio;
          bixby-studio = bixbyStudio;
          unwrapped = bixbyStudioUnwrapped;
        };

        apps = {
          default = app;
          bixby-studio = app;
        };
      });
}

{
  description = "Bixby Studio";
  # TODO uses old ssl so there is that...
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixgl.url = "github:nix-community/nixGL";
  };

  outputs = { self, nixpkgs, flake-utils, nixgl }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nixglPkg = nixgl.packages.${system}.nixGLDefault;
      in
      {
        packages.default = pkgs.buildFHSUserEnv {
          name = "bixby-studio";
          targetPkgs = pkgs: (with pkgs; [
            # Extracted Bixby Studio
            (stdenv.mkDerivation rec {
              pname = "bixby-studio-extracted";
              version = "8.23.1-r24c.2843029";
              
              src = fetchurl {
                url = "https://bixby-studio.s3.amazonaws.com/stable-c4f5c975-1d91-4065-b661-633de7275e11/BixbyStudio-${version}-linux.rpm";
                sha256 = "sha256-wae96w06w8GyXOVKKHd1ddq0ANQab0XIqug2fyC1NrM=";
              };
              
              nativeBuildInputs = [ rpm cpio ];
              
              unpackPhase = ''
                rpm2cpio $src | cpio -idmv
              '';
              
              installPhase = ''
                mkdir -p $out
                cp -r ./* $out/
              '';
              
              dontConfigure = true;
              dontBuild = true;
            })
            # System libraries
            glib gvfs gsettings-desktop-schemas nss nspr gtk3 atk cairo pango gdk-pixbuf
            xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes
            xorg.libXrandr xorg.libxcb xorg.libXi xorg.libXScrnSaver xorg.libXtst
            xorg.libxshmfence xorg.libXcursor xorg.libXrender xorg.libXinerama
            alsa-lib cups dbus fontconfig freetype libdrm mesa libGL libGLU openssl_1_1
            vulkan-loader libglvnd systemd util-linux procps libuuid libsecret
            at-spi2-atk at-spi2-core expat libxkbcommon
          ]);
          
          runScript = pkgs.writeScript "bixby-studio-runner" ''
            #!/bin/bash
            export GIO_EXTRA_MODULES=""
            export LIBGL_DRIVERS_PATH="${pkgs.mesa.drivers}/lib/dri"
            export __EGL_VENDOR_LIBRARY_DIRS="${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d"
            cd /usr/opt/Bixby\ Studio 2>/dev/null || cd /opt/Bixby\ Studio
            exec ./bixbystudio --disable-gpu --disable-gpu-sandbox --no-sandbox --disable-dev-shm-usage --disable-extensions --no-zygote --disable-seccomp-filter-sandbox --disable-setuid-sandbox "$@"
          '';
        };

        packages.old = pkgs.stdenv.mkDerivation rec {
          pname = "bixby-studio";
          version = "8.23.1-r24c.2843029";

          src = pkgs.fetchurl {
            url = "https://bixby-studio.s3.amazonaws.com/stable-c4f5c975-1d91-4065-b661-633de7275e11/BixbyStudio-${version}-linux.rpm";
            sha256 = "sha256-wae96w06w8GyXOVKKHd1ddq0ANQab0XIqug2fyC1NrM=";
          };

          nativeBuildInputs = [ pkgs.rpm
                                    pkgs.cpio
                                    pkgs.autoPatchelfHook
                              ];
  buildInputs = [
    pkgs.glib
    pkgs.gvfs
    pkgs.gsettings-desktop-schemas
    pkgs.nss
    pkgs.gtk3
    pkgs.atk
    pkgs.cairo
    pkgs.pango
    pkgs.gdk-pixbuf
    pkgs.xorg.libX11
    pkgs.xorg.libXcomposite
    pkgs.xorg.libXdamage
    pkgs.xorg.libXext
    pkgs.xorg.libXfixes
    pkgs.xorg.libXrandr
    pkgs.xorg.libxcb
    pkgs.xorg.libXi
    pkgs.xorg.libXScrnSaver
    pkgs.xorg.libXtst
    pkgs.xorg.libxshmfence
    pkgs.xorg.libXcursor
    pkgs.xorg.libXrender
    pkgs.xorg.libXinerama
    pkgs.alsa-lib
    pkgs.cups
    pkgs.dbus
    pkgs.fontconfig
    pkgs.freetype
    pkgs.libdrm
    pkgs.mesa
    pkgs.libGL
    pkgs.libGLU
    pkgs.openssl_1_1
    pkgs.vulkan-loader
    pkgs.libglvnd
    # System libraries for Electron
    pkgs.systemd
    pkgs.util-linux
    pkgs.procps
    pkgs.libuuid
    pkgs.libsecret
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
  ];
  unpackPhase = ''
            rpm2cpio $src | cpio -idmv
          '';

          installPhase = ''
            mkdir -p $out
            cp -r ./* $out/
            mkdir -p $out/bin
            cat > $out/bin/bixbystudio << 'EOF'
#!/bin/sh
exec ${nixglPkg}/bin/nixGL "$out/opt/Bixby Studio/bixbystudio" "$@"
EOF
            chmod +x $out/bin/bixbystudio
          '';

          dontConfigure = true;
          dontBuild = true;

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath buildInputs}
      --set LIBGL_DRIVERS_PATH "${pkgs.mesa.drivers}/lib/dri"
      --set __EGL_VENDOR_LIBRARY_DIRS "${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d"
      --unset GIO_MODULE_DIR
      --set GIO_EXTRA_MODULES ""
      --add-flags "--disable-gpu --disable-gpu-sandbox --no-sandbox --disable-dev-shm-usage --disable-extensions --no-zygote --disable-seccomp-filter-sandbox --disable-setuid-sandbox"
    )
  '';

          meta = with pkgs.lib; {
            description = "Bixby Studio IDE";
            homepage = "https://bixbydevelopers.com/";
            license = licenses.unfree;
            platforms = [ "x86_64-linux" ];
          };
        };
      });
}

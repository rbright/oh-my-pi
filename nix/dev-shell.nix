{
  pkgs,
  bun,
  bun2nix,
  rustToolchain,
}:
let
  inherit (pkgs) lib;
  linuxLibraries = with pkgs; [
    libpulseaudio
    pipewire
    stdenv.cc.cc.lib
    zlib
  ];
in
pkgs.mkShell (
  {
    name = "omp-dev";

    packages =
      [ bun bun2nix rustToolchain ]
      ++ (with pkgs; [
        cargo-nextest
        rustPlatform.bindgenHook
        nixfmt
        typescript-language-server

        python312
        python312Packages.pip
        uv
        basedpyright

        bash
        # The pinned nixpkgs ships cacert 3.126, which still trusts the root above
        # the compromised eMudhra intermediates (https://emudhra.we-have-a-problem.com/).
        # cacert 3.131.1 drops it; remove this override once nixpkgs ships it.
        (cacert.override { blacklist = [ "emSign ECC Root CA - G3" ]; })
        curl
        fd
        git
        git-lfs
        imagemagick
        openssh
        ripgrep
        sqlite
        unzip

        cmake
        ninja
        pkg-config
        zig

        cairo
        giflib
        libjpeg
        librsvg
        openssl
        pango
        pcre2
        zlib
      ])
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxLibraries;

    PCRE2_SYS_STATIC = "1";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    LD_LIBRARY_PATH = lib.makeLibraryPath linuxLibraries;
  }
)

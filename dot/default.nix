{
  pkgs ? import <nixpkgs> { system = builtins.currentSystem; },
  fenix,
  system,
}:
let
  toolchain = fenix.packages.${system}.fromToolchainFile {
    file = ./rust-toolchain.toml;
    sha256 = "18blq77d227zfgqwadk3zanlwlxp3i23pqpc11ck0yqf20p6dlgv";
  };
in
(
  (pkgs.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  }).buildRustPackage
  {
    name = "dot";
    src = ./.;
    cargoLock.lockFile = ./Cargo.lock;
    nativeBuildInputs = with pkgs; [
      libgit2
      pkg-config
      openssl
    ];
  }
).overrideAttrs
  (old: {
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
  })

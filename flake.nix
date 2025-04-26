{
  description = "Xline";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    shelly.url = "github:CertainLach/shelly";
  };
  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.shelly.flakeModule ];
      systems = lib.systems.flakeExposed;
      perSystem =
        {
          pkgs,
          system,
          inputs',
          ...
        }:
        let
          rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain rust;
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
          };

          shelly.shells.default = {
            factory = craneLib.devShell;
            packages = with pkgs; [
              cargo-hakari
              cargo-edit
              rustPlatform.bindgenHook
              gdb
            ];

            environment.PROTOC = "${pkgs.protobuf}/bin/protoc";
          };
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}


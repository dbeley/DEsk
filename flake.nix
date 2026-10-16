{
  description = "DEsk — a skeuomorphic Wayland desktop for Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      # pkgs.desk, and the wlroots 0.18 it is built on. The module adds
      # this overlay itself (only while DEsk is enabled), so
      # programs.desk.package's default, pkgs.desk, resolves.
      overlay = import ./nix/overlay.nix;
    in
    {
      overlays.default = overlay;

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          desk = pkgs.callPackage ./nix/desk.nix {
            wlroots = pkgs.callPackage ./nix/wlroots-0.18.nix { };
          };
          default = self.packages.${system}.desk;
        }
      );

      nixosModules = {
        desk =
          { config, lib, ... }:
          {
            imports = [ ./nix/module.nix ];
            nixpkgs.overlays = lib.mkIf config.programs.desk.enable [ overlay ];
          };
        default = self.nixosModules.desk;
      };
    };
}

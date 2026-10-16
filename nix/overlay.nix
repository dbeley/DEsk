# The overlay behind the flake and the module: pkgs.desk, and the wlroots
# 0.18 it is built on. `nixosModules.desk` adds it for you; add it yourself
# when you import nix/module.nix without the flake, so that
# programs.desk.package's default, pkgs.desk, resolves.
final: prev: {
  wlroots_0_18 = final.callPackage ./wlroots-0.18.nix { };
  desk = final.callPackage ./desk.nix { wlroots = final.wlroots_0_18; };
}

# DEsk on NixOS

DEsk is a Wayland desktop, so on NixOS it is a session you pick at the
login screen, not a program you launch in one. The flake in the top of
this repository has what that takes:

- **`packages.desk`** -- DEsk built with Meson, as the installers build it.
- **`overlays.default`** -- `pkgs.desk`, for those not using the module.
- **`nixosModules.desk`** -- the part a package cannot do: put DEsk and
  the programs it runs on the system, offer the session at the login
  screen, give the screen lock its PAM service, and point the portals,
  dconf and Xwayland at DEsk.

Two things make this more than a one-line package. DEsk's compositor is
written against **wlroots 0.18**, which nixpkgs has removed (only 0.19 and
0.20 remain), so the flake builds 0.18.3 from its own release -- the same
release and the same Meson options the Debian/Ubuntu/Arch/Fedora
installers fetch (`nix/wlroots-0.18.nix`). And DEsk installs a PAM file
and an xdg-desktop-portal-wlr config to `/etc`, which a Nix build cannot
write; the module provides both the way NixOS wants them.

## With flakes

Add DEsk as an input and import the module:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    desk.url = "github:fyzugx/DEsk";
  };

  outputs = { nixpkgs, desk, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        desk.nixosModules.desk
        ./configuration.nix
      ];
    };
  };
}
```

Then turn it on, with whatever programs you want on the desk:

```nix
# configuration.nix
{ pkgs, ... }: {
  programs.desk.enable = true;

  # the terminal, browser, file manager and editor the desk opens, and the
  # programs Shell Settings' System tab rows open (all optional)
  programs.desk.extraPackages = with pkgs; [
    xfce4-terminal
    firefox
    thunar
    mousepad
  ];

  # a login screen to pick DEsk from, and DEsk as the default
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "desk";
}
```

```sh
sudo nixos-rebuild switch --flake .#myhost
```

Log out, and DEsk is in the session menu of the login screen (on SDDM,
often a list at the top left; on GDM, the gear by the password box).

## Trying it without logging out

Nest it in the session you are in, as a window (`desk-window` finds `desk`
beside it on the `PATH`):

```sh
nix shell github:fyzugx/DEsk -c desk-window
```

## Without flakes

Take the source, add the overlay, import the module:

```nix
# configuration.nix
let
  desk = builtins.fetchTarball
    "https://github.com/fyzugx/DEsk/archive/refs/heads/main.tar.gz";
in
{
  imports = [ "${desk}/nix/module.nix" ];
  nixpkgs.overlays = [ (import "${desk}/nix/overlay.nix") ];
  programs.desk.enable = true;
}
```

The overlay provides `pkgs.desk`, which `programs.desk.package` defaults
to. Importing `nix/module.nix` without the flake or the overlay means
setting `programs.desk.package` yourself.

## The package alone

`nix profile install github:fyzugx/DEsk` gives `desk` and the programs
that come with it (`desk-session`, `desk-settings`, `desk-index`,
`desk-window`, `desk-ctl`, `desk-report`, ...), and `desk-window` opens the
desk in a window. To have DEsk at the login screen without the module, do
what it does:

```nix
nixpkgs.overlays = [ (import "${desk}/nix/overlay.nix") ];
environment.systemPackages = [ pkgs.desk ];
services.displayManager.sessionPackages = [ pkgs.desk ];
security.pam.services.desk = { };
```

## Options

| Option | Default | |
| --- | --- | --- |
| `programs.desk.enable` | `false` | Install DEsk and offer it at the login screen. |
| `programs.desk.package` | `pkgs.desk` | The DEsk package (from the flake's overlay). |
| `programs.desk.extraPackages` | `[]` | Programs to add for a DEsk session (the terminal, browser, file manager, editor, and the programs Shell Settings opens). |

## What the module turns on

Along with `programs.desk.enable`, the module sets the rest of a desktop
with `lib.mkDefault` where another desktop may have set it:

- `environment.systemPackages` -- DEsk itself, and the programs DEsk runs
  itself: `grim` and `wl-clipboard` (the screenshot keys), `libnotify` (the
  letter saying where the picture went), `curl` (the weather at the front
  door), `xdg-user-dirs` and `xdg-utils`.
- `services.displayManager.sessionPackages` -- and the package carries
  `passthru.providedSessions = [ "desk" ]`, so the login screen lists it.
- `security.pam.services.desk` -- the screen lock's PAM service (the front
  door); without it, the lock falls back to `login`.
- `services.graphical-desktop.enable`, `programs.dconf.enable`,
  `programs.xwayland.enable`, `security.polkit.enable` -- the shared
  plumbing a desktop session and DEsk's own settings layer, X11 programs
  and password prompts need.
- `xdg.portal` -- `xdg-desktop-portal-wlr` for screenshots and screen
  sharing, `xdg-desktop-portal-gtk` for the rest, and DEsk's own
  `desk-portals.conf`. Screen sharing takes the first screen, as DEsk's
  config sets (`chooser_type = none`).
- `fonts.packages` -- Noto (including CJK and emoji), which the desk's
  seven languages are printed in.

## Notes

- The module does **not** install the recommended desktop programs the
  shell installers bring (Xfce Terminal, Firefox, Thunar, Mousepad...).
  Add what you want with `programs.desk.extraPackages`; a row of Shell
  Settings' System tab whose program is missing is printed faint, with the
  package to install. See the README's [As a desktop](../README.md#as-a-desktop).
- The URW base 35 and Klee One typefaces the desk prefers have no nixpkgs
  package; without them, fontconfig substitutes faces, as on other systems
  where they are not installed.
- To update, update the flake input (`nix flake update desk`, or the
  `desk.url` revision) and rebuild. Your settings and the traced room are
  kept, as everywhere else.

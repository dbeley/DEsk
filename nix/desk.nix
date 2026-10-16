# DEsk, built with Meson as the installers build it, for NixOS and Nix.
#
# The compositor is written against wlroots 0.18, which nixpkgs no longer
# packages, so it is built from nix/wlroots-0.18.nix and found through its
# pkg-config name (wlroots-0.18).
#
# DEsk installs one file to /etc/pam.d (the screen lock's service) and one
# to /etc/xdg/xdg-desktop-portal-wlr (screen sharing), which cannot be
# written in a Nix build. They are moved under $out/etc here; the NixOS
# module (nix/module.nix) provides both the way NixOS wants them, and a
# plain `nix profile install` still gets the files to copy into place.
{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  wayland-scanner,
  wlroots,
  wayland,
  wayland-protocols,
  cairo,
  fontconfig,
  pixman,
  libdrm,
  libxkbcommon,
  libGL,
  libgbm,
  libinput,
  systemd,
  libpulseaudio,
  linux-pam,
  libxcb,
  libxcb-wm,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "desk";
  version = "0.1.2";

  src = lib.cleanSource ../.;

  strictDeps = true;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    wayland-scanner
  ];

  buildInputs = [
    wlroots
    wayland
    wayland-protocols
    cairo
    fontconfig
    pixman
    libdrm
    libxkbcommon
    libGL # EGL and GLES2: the room traced on the GPU
    libgbm
    libinput # touchpad and mouse settings (Shell Settings)
    systemd # libsystemd: the post box and the tray
    libpulseaudio # the desk's sounds
    linux-pam # the screen lock
    libxcb # X11 programs through Xwayland
    libxcb-wm # xcb-icccm, xcb-ewmh
  ];

  # /etc cannot be written by a build: put both files under $out instead.
  postPatch = ''
    substituteInPlace meson.build \
      --replace-fail "install_dir: '/etc/pam.d'" "install_dir: 'etc/pam.d'" \
      --replace-fail "install_dir: '/etc/xdg/xdg-desktop-portal-wlr'" "install_dir: 'etc/xdg/xdg-desktop-portal-wlr'"
  '';

  # the desktop file the login screen lists, share/wayland-sessions/desk.desktop
  passthru.providedSessions = [ "desk" ];

  meta = {
    description = "A skeuomorphic Wayland desktop for Linux";
    longDescription = ''
      DEsk is a Wayland desktop in realistic skeuomorphism: windows are
      sheets of paper on a walnut desk, the dock is a drawer, apps are
      filed in binders, notifications arrive in a post box, and the system
      controls are a panel built into the back of the desk.
    '';
    homepage = "https://github.com/fyzugx/DEsk";
    license = lib.licenses.mit;
    mainProgram = "desk";
    platforms = lib.platforms.linux;
  };
})

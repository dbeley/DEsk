# wlroots 0.18, the line DEsk's compositor is written against.
#
# nixpkgs has removed wlroots 0.18 (wlroots_0_18 is now a throwing alias,
# and only 0.19 and 0.20 are packaged), so it is built here from the same
# release tarball the Debian/Ubuntu/Arch/Fedora installers fetch and check
# (scripts/install_arch.sh, SOURCES), with the same Meson options they pass:
# the DRM, libinput and X11 backends (X11 for running DEsk nested in an X
# session), the GLES2 renderer, the GBM allocator, session support and
# Xwayland. The Vulkan renderer, color management, libliftoff and xcb-errors
# are left out, as the installers leave them out.
{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  wayland-scanner,
  hwdata,
  wayland,
  wayland-protocols,
  libGL,
  libdrm,
  libgbm,
  libinput,
  libxkbcommon,
  pixman,
  libdisplay-info,
  libx11,
  libxcb,
  libxcb-render-util,
  libxcb-wm,
  xwayland,
  seatd,
  udev,
  libcap,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wlroots";
  version = "0.18.3";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/wlroots/wlroots/-/releases/0.18.3/downloads/wlroots-0.18.3.tar.gz";
    hash = "sha256-Fkp8i/n4riwfsA573bbwjK1+gbPrNVd7SEg7GsJloIc=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
    hwdata
  ];

  buildInputs = [
    wayland
    wayland-protocols
    libGL
    libdrm
    libgbm
    libinput
    libxkbcommon
    pixman
    libdisplay-info
    libx11
    libxcb
    libxcb-render-util
    libxcb-wm
    xwayland
    seatd
    udev
    libcap
  ];

  mesonFlags = [
    "-Dexamples=false"
    "-Dwerror=false"
    "-Dbackends=drm,libinput,x11"
    "-Drenderers=gles2"
    "-Dallocators=gbm"
    "-Dsession=enabled"
    "-Dxwayland=enabled"
    "-Dlibliftoff=disabled"
    "-Dcolor-management=disabled"
    "-Dxcb-errors=disabled"
    # where wlroots looks for cursor themes; the system profile on NixOS
    "-Dicon_directory=/run/current-system/sw/share/icons"
  ];

  meta = {
    description = "Modular Wayland compositor library (0.18 line, used by DEsk)";
    homepage = "https://gitlab.freedesktop.org/wlroots/wlroots";
    changelog = "https://gitlab.freedesktop.org/wlroots/wlroots/-/tags/${finalAttrs.version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    pkgConfigModules = [ "wlroots-0.18" ];
  };
})

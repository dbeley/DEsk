# NixOS module for DEsk. See docs/NIXOS.md.
#
# It does what a package cannot: puts DEsk and the programs it itself runs
# on the system, offers the session at the login screen, gives the screen
# lock its PAM service, and points the portals at DEsk's own.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.desk;

  # the programs DEsk itself runs at run time: grim and wl-clipboard for
  # the screenshot keys, libnotify for the letter that says where it went,
  # curl for the weather at the front door, xdg-user-dirs and xdg-utils for
  # ~/Pictures and opening files. The programs Shell Settings opens are
  # the user's to add, with programs.desk.extraPackages.
  runtimePackages = with pkgs; [
    curl
    grim
    wl-clipboard
    libnotify
    xdg-user-dirs
    xdg-utils
  ];
in
{
  options.programs.desk = {
    enable = lib.mkEnableOption "the DEsk Wayland desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.desk;
      defaultText = lib.literalExpression "pkgs.desk";
      description = ''
        The DEsk package to use. The default comes from the flake's
        overlay, which `nixosModules.desk` adds.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [ xfce4-terminal firefox thunar mousepad ]
      '';
      description = ''
        Programs to add to the system for a DEsk session: the terminal,
        browser, file manager and text editor the desk opens, and the
        programs Shell Settings' System tab rows open.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ] ++ runtimePackages ++ cfg.extraPackages;

    # the login screen lists DEsk's share/wayland-sessions/desk.desktop
    services.displayManager.sessionPackages = [ cfg.package ];

    # the screen lock (the front door) checks the password as login does
    security.pam.services.desk = { };

    # a whole desktop's worth of shared plumbing: the portals, dconf (DEsk's
    # layer of settings), Xwayland, polkit, sound. All mkDefault where
    # another desktop may have set them.
    services.graphical-desktop.enable = lib.mkDefault true;
    programs.dconf.enable = lib.mkDefault true;
    programs.xwayland.enable = lib.mkDefault true;
    security.polkit.enable = lib.mkDefault true;

    # screenshots and screen sharing take the wlr portal, everything else
    # the GTK one; DEsk's own desk-portals.conf names them. DEsk shares the
    # first screen (no layer-shell chooser), as its file sets.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      configPackages = [ cfg.package ];
      wlr = {
        enable = true;
        settings.screencast.chooser_type = "none";
      };
    };

    # the desk is printed in seven languages and draws the CJK and emoji
    # faces it needs
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
  };
}

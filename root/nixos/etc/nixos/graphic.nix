{ config, pkgs, lib, ... }:

{
  services.libinput.enable = true;

  # Wayland-first: disable X server; Niri will spawn Xwayland if needed
  services.xserver.enable = false;
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Display manager: SDDM on Wayland, autologin to liforra
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "liforra";

  # Ensure Niri session appears in SDDM
  services.xserver.displayManager.sessionPackages = [ pkgs.niri ];
  programs.niri.enable = true;

  # Portals for Wayland integration (screen share, file pickers, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  # Printing
  services.printing.enable = true;

  # Audio: PipeWire (PulseAudio compatibility through PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true; # enable if you need JACK
  };

  # GNOME keyring for libsecret-backed credentials
  services.gnome.gnome-keyring.enable = true;

  # Hardware acceleration
  hardware.opengl.enable = true;

  # GUI programs
  programs.firefox.enable = true;
  programs.steam.enable = true;

  # GUI/Wayland applications and utilities
  environment.systemPackages = with pkgs; [
    # Terminals and launchers
    kitty
    rofi-wayland

    # Wayland desktop utilities
    niri
    waybar
    wl-clipboard
    swaybg
    hyprlock
    xwayland-satellite
    nautilus # Required for Gnome Portals
    gnome-control-center

    kdePackages.dolphin
    vscodium
    # Other GUI apps from your original config
    kdePackages.kleopatra
  ];

  # Fonts (as in your original)
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.ubuntu
  ];

  # Session variables for kitty Wayland
  environment.sessionVariables = {
    KITTY_ENABLE_WAYLAND = "1";
  };
}

{ config, pkgs, lib, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-0f360ac3-b7ff-479d-8652-9a8270b2ea2d".device =
    "/dev/disk/by-uuid/0f360ac3-b7ff-479d-8652-9a8270b2ea2d";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Wayland-first, no X server. Xwayland is auto-started by Niri when needed.
  services.xserver.enable = false;
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  
  # Auto-login configuration
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "liforra";

  # Make sure Niri session is offered by SDDM
  services.xserver.displayManager.sessionPackages = [ pkgs.niri ];

  # Niri program integration + portals
  programs.niri.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  # Input
  services.libinput.enable = true;

  console.keyMap = "de";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # jack.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;

  programs.firefox.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.steam.enable = true;

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    config = {
      credential.helper = "libsecret";
      init.defaultBranch = "main";
      pull.rebase = "false";
    };
  };

  # Hardware acceleration (simplified for 25.05)
  hardware.opengl.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.noto
    nerd-fonts.ubuntu
    nerd-fonts.droid-sans-mono
  ];

  users.users.liforra = {
    isNormalUser = true;
    description = "Liforra";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = with pkgs; [ ];
  };

  environment.systemPackages = with pkgs; [
    niri
    rofi-wayland
    waybar
    wl-clipboard
    swaybg
    hyprlock
    xwayland-satellite

    git
    git-credential-manager
    neovim
    gcc
    tree
    tmux
    zellij
    ripgrep
    fzf
    cryptsetup
    file
    stow
    yazi
    fastfetch
    zoxide
    starship

    arch-install-scripts
  ];

  programs.starship.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      substituters = [ "https://cache.nixos.org" ];
      trusted-users = [ "root" "liforra" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  system.stateVersion = "25.05";
}

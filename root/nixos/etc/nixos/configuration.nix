# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-0f360ac3-b7ff-479d-8652-9a8270b2ea2d".device = "/dev/disk/by-uuid/0f360ac3-b7ff-479d-8652-9a8270b2ea2d";
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

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

  # Enable the X11 windowing system.
  # If you're going purely Wayland with Niri, you might want to disable X11
  # to reduce system bloat. However, some applications might still rely on it.
  # For now, let's keep it enabled as it was in your original config.
  services.xserver.enable = true;

  # We are moving away from Plasma 6 and enabling Niri.
  # Comment out or remove these lines if you don't want Plasma 6.
  # services.desktopManager.plasma6.enable = true;

  # Configure display manager for Wayland compositors like Niri.
  # SDDM is a good choice for both X11 and Wayland sessions.
  services.displayManager.sddm.enable = true;
  # Configure SDDM to offer Niri as a Wayland session.
  # The exact session name might vary, often it's 'niri'.
  # We'll make sure the `niri` package is installed and provides the session file.
  services.xserver.displayManager.sessionPackages = [
    pkgs.niri
  ];
  # For SDDM, you often need to define specific Wayland sessions.
  # This might require creating a custom .desktop file or relying on
  # the package to provide one. Nixpkgs usually handles this when you
  # list it in sessionPackages.
  # If Niri doesn't appear, you might need something like:
  # services.displayManager.sddm.extraConfig = ''
  #   [WaylandSession]
  #   command=niri
  # '';
  # But `sessionPackages` is the standard NixOS way.

  # Remove the invalid `services.wayland` option
  # services.wayland.windowManager.niri.enable = true; # THIS WAS THE ERROR

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true; # Keep this for now, X11 is still enabled

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.liforra = {
    isNormalUser = true;
    description = "Liforra";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = with pkgs; [
      # kdePackages.kate # Kate is a KDE application, you might prefer a Wayland-native editor or Neovim
    ];
  };

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "liforra";
  # Enable Gnome relying
  services.gnome.gnome-keyring.enable = true;
  # Install firefox.
  programs.firefox.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.steam.enable = true;
programs.git = {
  enable = true;
  package = pkgs.gitFull;
  config.credential.helper = "libsecret";
};
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.ubuntu
     ];
  environment.systemPackages = with pkgs; [
    # Wayland Utilities
    git-credential-manager
    wl-clipboard # Provides wl-copy and wl-paste
    git
    # Editors
    neovim # Modern Vim-like text editor
    gcc # Needed for neovim
    arch-install-scripts
    yazi
    stow
    # Terminal Emulators
    tree
    kitty # Fast, feature-rich, GPU-accelerated terminal emulator
    tmux # Terminal multiplexer (alternative to Zellij)
    zellij # Another terminal multiplexer, written in Rust
    cryptsetup
    file # Pretty Essential
    ripgrep 
    fzf
    swaybg
    hyprlock
    # Shell enhancements
    zoxide # A smarter cd command
    starship # The minimal, blazing-fast, and infinitely customizable prompt for any shell!
    fastfetch # Needed for nushell config
    # Ensure Niri itself is installed as a package
    kdePackages.kleopatra
    niri
    rofi # Needed for Niri Configuration
    waybar
    xwayland-satellite
];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}

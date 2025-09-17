{ config, pkgs, lib, ... }:

{





  # Network configuration (from graphic.nix, essential for servers)
  networking.networkmanager.enable = true; # or use systemd-networkd for servers
  networking.firewall.enable = true; # Critical for servers

  # Time and locales (from graphic.nix, useful for servers)
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

  # Console (from graphic.nix)
  console.keyMap = "de";

  # GNOME keyring (from graphic.nix, useful for credential storage even on servers)
  services.gnome.gnome-keyring.enable = true;









  # Boot + EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # LUKS device (from your original)
  boot.initrd.luks.devices."luks-0f360ac3-b7ff-479d-8652-9a8270b2ea2d".device =
    "/dev/disk/by-uuid/0f360ac3-b7ff-479d-8652-9a8270b2ea2d";

  # Allow unfree packages (needed for Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Nix settings and hygiene
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

  # CLI/dev and utilities (from your original)
  environment.systemPackages = with pkgs; [
    # Term multiplexers
    tmux
    zellij

    # Dev tools
    git
    git-credential-manager
    gcc
    neovim

    # Utilities
    tree
    ripgrep
    fzf
    cryptsetup
    file
    stow
    yazi
    fastfetch
    zoxide
    starship

    # Misc
    arch-install-scripts
  ];

  # Git with libsecret credential helper
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    config = {
      credential.helper = "libsecret";
      init.defaultBranch = "main";
      pull.rebase = "false";
    };
  };

  # GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Starship prompt
  programs.starship.enable = true;

  # Preserve your system state baseline
  system.stateVersion = "25.05";
}

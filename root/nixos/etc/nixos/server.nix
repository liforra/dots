{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
  ];

  # Network configuration (from graphic.nix, essential for servers)
  networking.hostName = "nixos"; # Change this for your server
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

  # Server-specific environment packages (minimal, from existing packages)
  environment.systemPackages = with pkgs; [
    # Keep git-credential-manager for server git operations
    git-credential-manager
  ];

  # Suggested server additions (uncomment as needed):
  
  # SSH daemon for remote access
  # services.openssh.enable = true;
  # services.openssh.settings = {
  #   PasswordAuthentication = false; # Use key-based auth
  #   PermitRootLogin = "no";
  # };
  
  # Fail2ban for security
  # services.fail2ban.enable = true;
  
  # Automatic updates for security
  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.allowReboot = true;
  
  # Docker/containers
  # virtualisation.docker.enable = true;
  # virtualisation.podman.enable = true;
  
  # Database services
  # services.postgresql.enable = true;
  # services.mysql.enable = true;
  # services.redis.servers."".enable = true;
  
  # Web servers
  # services.nginx.enable = true;
  # services.caddy.enable = true;
  
  # Backup solutions
  # services.restic.backups = { };
  # services.borgbackup.jobs = { };
  
  # Monitoring
  # services.prometheus.enable = true;
  # services.grafana.enable = true;
  # services.netdata.enable = true;
  
  # Log management
  # services.journald.extraConfig = ''
  #   SystemMaxUse=1G
  #   MaxRetentionSec=1month
  # '';
  
  # Network time synchronization (more critical on servers)
  # services.chrony.enable = true;
  
  # Mail server (if needed)
  # services.postfix.enable = true;
  
  # File sharing
  # services.samba.enable = true;
  # services.nfs.server.enable = true;
  
  # Reverse proxy / load balancing
  # services.haproxy.enable = true;
  
  # Certificate management
  # security.acme.acceptTerms = true;
  # security.acme.defaults.email = "admin@example.com";
  
  # Firewall specific ports (examples)
  # networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ];
  
  # Performance tuning for servers
  # boot.kernel.sysctl = {
  #   "vm.swappiness" = 10;
  #   "net.core.default_qdisc" = "fq";
  #   "net.ipv4.tcp_congestion_control" = "bbr";
  # };
  
  # Systemd service hardening (example)
  # systemd.services.myservice = {
  #   serviceConfig = {
  #     DynamicUser = true;
  #     NoNewPrivileges = true;
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #   };
  # };
}

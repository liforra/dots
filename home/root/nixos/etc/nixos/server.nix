{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
  ];



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

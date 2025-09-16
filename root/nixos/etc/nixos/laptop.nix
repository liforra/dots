{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./graphic.nix
  ];

  # Laptop-specific power management
  services.power-profiles-daemon.enable = true;
  powerManagement.powertop.enable = true;

  # Optional laptop utilities
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}

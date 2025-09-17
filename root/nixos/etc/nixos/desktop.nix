{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ./graphic.nix
  ];

  # Desktop-specific options can go here
  environment.systemPackages = with pkgs; [
    # Add desktop-only tools here if needed
  ];
}

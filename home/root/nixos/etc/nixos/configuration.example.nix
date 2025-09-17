{ config, pkgs, lib, ... }:
{
  networking.hostName = "Ididntedittheconfig";
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./graphic.nix
    ./cli.nix
    ./theme.nix
    # Choose exactly ONE of these per machine:
    # ./laptop.nix
    # ./desktop.nix
    # ./server.nix
  ];
}

{ config, pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.home-manager
  ];
nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

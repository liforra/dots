{ config, pkgs, lib, ... }:

{
  users.users.liforra = {
    isNormalUser = true;
    description = "Liforra";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = [ ];
  };
}

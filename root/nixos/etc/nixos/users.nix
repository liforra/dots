{ config, pkgs, lib, ... }:

{
  users.users.liforra = {
    isNormalUser = true;
    description = "Liforra";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = [ ];
  };
    users.users.shwooshy = {
    isNormalUser = true;
    description = "Shwooshy";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
    packages = [ ];
  };
    users.users.guest = {
    isNormalUser = true;
    description = "Guest User";
    extraGroups = [ "networkmanager" ];
    shell = pkgs.nushell;
    packages = [ ];
  };
}

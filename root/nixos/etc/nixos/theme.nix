{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
  ];
  nixpkgs.config.qt5 = {
    enable = true;
    platformTheme = "qt5ct"; 
      style = {
        package = pkgs.utterly-nord-plasma;
        name = "Utterly Nord Plasma";
      };
  };
  # Add themes, icons, cursors, GTK settings, font defaults here later.
  # Example (commented):
  # environment.systemPackages = with pkgs; [
  #   adw-gtk3
  #   gnome-themes-extra
  #   papirus-icon-theme
  # ];
  # fonts.fontconfig.defaultFonts = {
  #   monospace = [ "FiraCode Nerd Font" ];
  # };
}

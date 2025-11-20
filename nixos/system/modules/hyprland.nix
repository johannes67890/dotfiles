{ pkgs, ... }: {
	programs.hyprland = {
        enable = true;
		xwayland.enable = true;
    };
	# Hyprland & graphical session related configuration
	services.xserver = {
		enable = true;
		displayManager.gdm.enable = true;
		desktopManager.gnome.enable = true;
		displayManager.gdm.wayland = true;  # Enable Wayland in GDM
	};

	# Essential packages for Hyprland environment
	environment.systemPackages = with pkgs; [
      hyprpaper
      kitty
      libnotify
      mako
      qt5.qtwayland
      qt6.qtwayland
      swayidle
      swaylock-effects
      wlogout
      wl-clipboard
      wofi
      waybar
	];

	# Set default graphical session to Hyprland
	services.displayManager.defaultSession = "hyprland";
}

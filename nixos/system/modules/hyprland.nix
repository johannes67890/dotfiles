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
		waybar           # Status bar
		wofi             # Application launcher
		dunst            # Notifications
		grim             # Screenshot utility
		slurp            # Screen area selection
		wl-clipboard     # Clipboard utilities
	];

	# Set default graphical session to Hyprland
	services.displayManager.defaultSession = "hyprland";
}

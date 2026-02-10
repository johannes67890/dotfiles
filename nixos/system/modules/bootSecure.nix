{ lib, config, ... }: {
	# Bootloader & Secure Boot (Lanzaboote) configuration
	boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
	boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 5;   # only keep latest entry
  	};
	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};
}

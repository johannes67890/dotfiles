{ lib, config, ... }: {
	# Bootloader configuration
	boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
	boot.initrd.systemd.enable = false;
	boot.loader.systemd-boot = {
        enable = lib.mkForce true;
        configurationLimit = 5;   # only keep latest entry
  	};
}


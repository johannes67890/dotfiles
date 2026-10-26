{ lib, config, ... }: {
	# Bootloader configuration
	boot.initrd.systemd.enable = false;
	boot.loader.systemd-boot = {
        enable = lib.mkForce true;
        configurationLimit = 5;   # keep the last 5 boot entries
  	};
}


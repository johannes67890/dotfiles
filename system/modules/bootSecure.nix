{ lib, config, ... }: {
	# Bootloader & Secure Boot (Lanzaboote) configuration
	boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 5;   # keep the last 5 boot entries
  	};
	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};
}

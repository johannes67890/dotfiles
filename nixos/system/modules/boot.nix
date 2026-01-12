{ lib, config, ... }: {
	# Bootloader & Secure Boot (Lanzaboote) configuration
	
	boot.loader.systemd-boot = {
    enable = lib.mkForce false;
    configurationLimit = 5;   # only keep latest entry
  };
	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};
}

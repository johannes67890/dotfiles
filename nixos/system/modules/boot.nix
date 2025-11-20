{ lib, config, ... }: {
	# Bootloader & Secure Boot (Lanzaboote) configuration
	boot.loader.systemd-boot.enable = lib.mkForce false;

	boot.lanzaboote = {
		enable = true;
		pkiBundle = "/var/lib/sbctl";
	};
}

{ ... }: {
	# Generic hardware configuration for non-NVIDIA systems
	hardware.graphics.enable = true;
	hardware.bluetooth.enable = true;
	hardware.bluetooth.powerOnBoot = true;

	# touchscreen / firmware
	hardware.enableRedistributableFirmware = true;
	hardware.enableAllFirmware = true;
}

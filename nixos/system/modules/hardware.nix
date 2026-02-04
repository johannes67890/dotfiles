{ config, pkgs, ... }: {
	# Graphics stack and NVIDIA driver configuration
	hardware.graphics.enable = true;
	hardware.bluetooth.enable = true;
	hardware.bluetooth.powerOnBoot = true;

	# touchscreen
	hardware.enableRedistributableFirmware = true;
	hardware.enableAllFirmware = true;


	services.xserver.videoDrivers = [ "nvidia" ];

	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement.enable = true;          # Saves VRAM on suspend
		powerManagement.finegrained = false;    # Experimental fine-grained PM disabled
		nvidiaSettings = true;                  # Enables nvidia-settings tool
		open = false;                           # Use proprietary kernel module
		package = config.boot.kernelPackages.nvidiaPackages.stable;
	};
}

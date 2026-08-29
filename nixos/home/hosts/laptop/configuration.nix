{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Import your hardware configuration file
  imports = [
    ./hardware-configuration.nix
    ../../../system/config.nix
    ../../../system/modules/boot.nix
    ../../../system/modules/hardware-non-nvidia.nix
    ../../../system/modules/kde.nix
    ../../../system/modules/file-limits.nix
  ];

  boot.kernelParams = lib.mkForce [ ];

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      permittedInsecurePackages = [ "qtwebengine-5.15.19" ];
      packageOverrides = (
      pkgs: {

        # For patch ITU++
        # ITU++ uses TTLS Auth and MSCHAP2 inner auth
        wpa_supplicant = pkgs.wpa_supplicant.overrideAttrs (attrs: {
          patches = attrs.patches ++ [ ./patches/itu++.patch ];
        });
      }
    );
    };
  };

# prowlarr
services.prowlarr = {
  enable = true;
  openFirewall = true;
};

  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];
  # Networking configuration goes under `config.networking`
  networking.hostName = "jgjoLaptop";
  networking.networkmanager.enable = true;
  # networking.wireless.iwd.enable = false;
  # networking.networkmanager.wifi.backend = "wpa_supplicant";
  networking.networkmanager.wifi.powersave = true;

  # onedrive
  services.onedrive.enable = false;
  # power management
	services.thermald.enable = true;
  # touchpad 
  services.libinput.enable = true;
  # multi-touch gesture recognizer
  # if touche app cant see touchegg: "flatpak override --user --env=XDG_CONFIG_DIRS=/var/run/host/etc/xdg com.github.joseexposito.touche"
	
	  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    icu
  ];

  programs.zsh.enable = true;
  # User configuration goes under `config.users`
  users.users = {
    jgjo = {
      isNormalUser = true;
      shell = pkgs.zsh; # Use Zsh as login shell
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPZ/LKt2V0JEb06a34/ktDMWXF3p6+ENQp2uqBnlNc0 johannes@orager.dk"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1XdYAnbBOL/PYjWOz0PLwajQR2I8pnA52r/jhW2XTslPOvEVoFXzBs8f2M4EIfrubzrH6CE6rBoXgCHU0605ClxrExA/z74hsgwEI3hvTeSM9P1+h/eafr+yLh0/WyJQH1PPAmB8fp5S1j8UEKjWWofKQ8rHuac1ehL9mf99jdBboDHskTHFSen6uUxHDHW3za/caZMIzvzwvNNSs+sLgaLM+enU17B/lxNwSL86vWm+jLWKztUpKHGpJTDVU7OgMAhfXuqjywupF96XN+kSKAche9T+hhCPlNY2v52OGBNsU7i6mId4wr4lwDwj37ba6J6MFrSnumwRVEphX7UYKYjqOz9MrbbnXCR3BBApkoEEYftHkp+U+VrxVJsqaK+HmrmxiJorIdtYv/hy/UJZtmlxWeU35sdKZAgtoyD8TOz39S1r7H1Ah6qM2khpcDK58QnprRmZTIRcRFVn79VceZf2hiaS4TQXHYBHYeSx/FhATvQInoSMfQjLRYyad/23Vk6t40NLq9W+6Gd3KXzrRlq+79PBdQOd5RCiePxTD/xQSAsNV0NHSzhsggEvtPUlgXLx9B12zZjspu6V/0ofrLIzysF/XwuQnis6TIqoTpwZxjsMLgiy0UTiP+ROidb4Mzeq82KUaKVvh6Au5sFtO4eiQhQS9K2xdHO8CbhHTw== jgj@toolpack.one"
      ];
      extraGroups = ["wheel"];
    };
  };

  console.font = "Lat2-Terminus16";

  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      jgjo = import ./home.nix;
    };
  };
  
  # SSH settings go under `config.services`
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # State version goes under `config.system`
  system.stateVersion = "23.05";


  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };
  console.keyMap = "dk-latin1";

  fonts.packages = with pkgs; [ nerd-fonts.fira-code ];

  # Enable Docker daemon
  virtualisation.docker.enable = true;

  # Enable Wireshark (allows non-root packet capture)
  programs.wireshark.enable = true;
  users.extraGroups.wireshark.members = [ "jgjo" ];

  # Enable Flatpak
  services.flatpak.enable = true;
  services.fwupd.enable = true;
  # Enable sound (kept here as general system configuration)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}

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
    # Framework 13 Pro quirks (Intel Core Ultra Series 3); see the Framework NixOS guide
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
    ../../../system/config.nix
    ../../../system/modules/boot.nix
    ../../../system/modules/hardware-non-nvidia.nix
    ../../../system/modules/kde.nix
    ../../../system/modules/file-limits.nix
  ];

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
  networking.hostName = "fw";
  networking.networkmanager.enable = true;
  # networking.wireless.iwd.enable = false;
  # networking.networkmanager.wifi.backend = "wpa_supplicant";
  networking.networkmanager.wifi.powersave = true;

  # onedrive
  services.onedrive.enable = false;
  # power management
	services.thermald.enable = true;
  # fingerprint reader (Framework 13 uses a standard fprintd-supported sensor,
  # no proprietary TOD driver needed). Enroll with `fprintd-enroll`, check with
  # `fprintd-verify`.
  services.fprintd.enable = true;

  # enablePam defaults to true, which turns on fingerprint auth for *every* PAM
  # service, including ones that authorize in the background with no user
  # present. Upstream warns against that (nixpkgs#442117), so opt out of the
  # blanket default and enable it only where a human is clearly at the machine.
  services.fprintd.enablePam = false;

  security.pam.services = {
    # SDDM substacks `login`, so fingerprint here makes the login screen wait for
    # fprintd's 30s timeout before it checks the password. A fingerprint can't
    # unlock KWallet anyway, so keep the first login password-only.
    login.fprintAuth = false;
    sudo.fprintAuth = true;    # sudo
  };
  # Lock screen is already handled by the plasma6 module: it defines a separate
  # `kde-fingerprint` PAM service with fprintAuth = true, gated only on
  # services.fprintd.enable. It also force-disables fprintAuth on the plain
  # `kde` service, because fingerprint there can block password login
  # (nixpkgs#239770) -- so don't set security.pam.services.kde.fprintAuth here.
  # power button: a short press shouldn't power off. Inside a Plasma session
  # PowerDevil takes over the short press (see powerdevil in plasma.nix); this
  # covers the login screen and anywhere PowerDevil isn't running.
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };
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
    extraSpecialArgs = { inherit inputs; inherit (config.networking) hostName; };
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
  system.stateVersion = "26.05"; # set to the value the installer generated


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
  # Firmware updates: run `fwupdmgr update` (fwupd is enabled by nixos-hardware)
  # Enable sound (kept here as general system configuration)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}

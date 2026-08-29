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
    ../../../system/modules/bootSecure.nix
    ../../../system/modules/hardware.nix
    ../../../system/modules/kde.nix
    ../../../system/modules/file-limits.nix
  ];

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      permittedInsecurePackages = [ "qtwebengine-5.15.19" "electron-39.8.10" ];
    };
  };

  # Networking configuration goes under `config.networking`
  networking.hostName = "jgjo";
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.wifi.powersave = true;

  # onedrive
  services.onedrive.enable = true;

  networking.firewall.allowedTCPPorts = [ 8191 ]; # FlareSolverr's actual listen port
  services.flaresolverr.enable = true;
  
  programs.zsh.enable = true;
  # User configuration goes under `config.users`
  users.users = {
    jgjo = {
      isNormalUser = true;
      shell = pkgs.zsh; # Use Zsh as login shell
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2t6qXGciRsEuUQ8rzw5tgeIHRrjwm0DCUmx90bIEaRFQnvCrjAkzLFtcM3k7ZU/U9kRlIYJjzDdZubF0UQkqyGUSqjlNpA+Yz8MHqL6ZQTNxyrMIXr0bHgdSX885rXPYC4+/cDZlFLribMA/bgsKiM2I02VaXKMuDFpEApAOnQVrCXxEECsxmSSFhS6XoUBKAvGomqlgrj3eCygBtzLpVPSQXykk+xKiRlj/r/+v4FiLEUwdT7Lz3eoiOt1j6uhDaE3h0/EWjSbr98U2I93mMyVrDE9O7XXDMu44DVDyMG1bJRjC7XeqMf3AtgLdwmJonhwhR+INbde/mleX3a3GZkqsC3JV/1c3dVMtnLzadau7XF6XtuzbaVKrkv0SVFOiIjV1ZScPIYbMjYek1wnDDDXz3aB9b7pXTMPU+SwNU+VcEpGK+EbP7kkblzTYnPhRqptXnJYVoGnf4ZEDbxq4bvBuu8TLsuoUUzzyfwIVHH2K4cvIGGl698gEvjZ+zIofSgAvkfSrievnSKrbKmwAzExpbvvpAhYmVC/kRVVGMZDAXgx6aQJbiQGhKWsXgkVYa1K7x4V8S4Tql77H1D8StbfGD0ONZpffHRfuSHngIarAcP3Cf0xhGP9I0YhEC8Gd48iJC2UagXUo7iJ4QMGsmBa4SQU6OS2ckaozGOomDSQ== johannes@orager.dk"
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
 programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
    icu
  ];
  
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

  # Enable sound (kept here as general system configuration)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}

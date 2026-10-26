{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # Shared settings (users, locale, ssh, sound, docker, ...) live in
  # system/config.nix; this file holds only what is specific to this host.
  imports = [
    ./hardware-configuration.nix
    ../../../system/config.nix
    ../../../system/modules/bootSecure.nix
    ../../../system/modules/hardware.nix
    ../../../system/modules/kde.nix
    ../../../system/modules/file-limits.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-39.8.10" ];

  networking.hostName = "jgjo";
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  services.onedrive.enable = true;

  # Listens on 8191; reached from this machine only, so no firewall opening.
  services.flaresolverr.enable = true;

  users.users.jgjo.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2t6qXGciRsEuUQ8rzw5tgeIHRrjwm0DCUmx90bIEaRFQnvCrjAkzLFtcM3k7ZU/U9kRlIYJjzDdZubF0UQkqyGUSqjlNpA+Yz8MHqL6ZQTNxyrMIXr0bHgdSX885rXPYC4+/cDZlFLribMA/bgsKiM2I02VaXKMuDFpEApAOnQVrCXxEECsxmSSFhS6XoUBKAvGomqlgrj3eCygBtzLpVPSQXykk+xKiRlj/r/+v4FiLEUwdT7Lz3eoiOt1j6uhDaE3h0/EWjSbr98U2I93mMyVrDE9O7XXDMu44DVDyMG1bJRjC7XeqMf3AtgLdwmJonhwhR+INbde/mleX3a3GZkqsC3JV/1c3dVMtnLzadau7XF6XtuzbaVKrkv0SVFOiIjV1ZScPIYbMjYek1wnDDDXz3aB9b7pXTMPU+SwNU+VcEpGK+EbP7kkblzTYnPhRqptXnJYVoGnf4ZEDbxq4bvBuu8TLsuoUUzzyfwIVHH2K4cvIGGl698gEvjZ+zIofSgAvkfSrievnSKrbKmwAzExpbvvpAhYmVC/kRVVGMZDAXgx6aQJbiQGhKWsXgkVYa1K7x4V8S4Tql77H1D8StbfGD0ONZpffHRfuSHngIarAcP3Cf0xhGP9I0YhEC8Gd48iJC2UagXUo7iJ4QMGsmBa4SQU6OS2ckaozGOomDSQ== johannes@orager.dk"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1XdYAnbBOL/PYjWOz0PLwajQR2I8pnA52r/jhW2XTslPOvEVoFXzBs8f2M4EIfrubzrH6CE6rBoXgCHU0605ClxrExA/z74hsgwEI3hvTeSM9P1+h/eafr+yLh0/WyJQH1PPAmB8fp5S1j8UEKjWWofKQ8rHuac1ehL9mf99jdBboDHskTHFSen6uUxHDHW3za/caZMIzvzwvNNSs+sLgaLM+enU17B/lxNwSL86vWm+jLWKztUpKHGpJTDVU7OgMAhfXuqjywupF96XN+kSKAche9T+hhCPlNY2v52OGBNsU7i6mId4wr4lwDwj37ba6J6MFrSnumwRVEphX7UYKYjqOz9MrbbnXCR3BBApkoEEYftHkp+U+VrxVJsqaK+HmrmxiJorIdtYv/hy/UJZtmlxWeU35sdKZAgtoyD8TOz39S1r7H1Ah6qM2khpcDK58QnprRmZTIRcRFVn79VceZf2hiaS4TQXHYBHYeSx/FhATvQInoSMfQjLRYyad/23Vk6t40NLq9W+6Gd3KXzrRlq+79PBdQOd5RCiePxTD/xQSAsNV0NHSzhsggEvtPUlgXLx9B12zZjspu6V/0ofrLIzysF/XwuQnis6TIqoTpwZxjsMLgiy0UTiP+ROidb4Mzeq82KUaKVvh6Au5sFtO4eiQhQS9K2xdHO8CbhHTw== jgj@toolpack.one"
  ];

  home-manager.users.jgjo = import ./home.nix;

  system.stateVersion = "23.05";
}

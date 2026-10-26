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
    ../../../system/modules/boot.nix
    ../../../system/modules/hardware-non-nvidia.nix
    ../../../system/modules/kde.nix
    ../../../system/modules/file-limits.nix
    ../../../system/modules/itu-wifi.nix
  ];

  # Web UI on localhost:9696; port deliberately not opened on shared Wi-Fi.
  services.prowlarr.enable = true;

  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024; # 16GB
  }];

  networking.hostName = "jgjoLaptop";

  # power management
  services.thermald.enable = true;
  # touchpad
  services.libinput.enable = true;
  # multi-touch gesture recognizer
  # if touche app cant see touchegg: "flatpak override --user --env=XDG_CONFIG_DIRS=/var/run/host/etc/xdg com.github.joseexposito.touche"

  services.fwupd.enable = true;

  users.users.jgjo.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPZ/LKt2V0JEb06a34/ktDMWXF3p6+ENQp2uqBnlNc0 johannes@orager.dk"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1XdYAnbBOL/PYjWOz0PLwajQR2I8pnA52r/jhW2XTslPOvEVoFXzBs8f2M4EIfrubzrH6CE6rBoXgCHU0605ClxrExA/z74hsgwEI3hvTeSM9P1+h/eafr+yLh0/WyJQH1PPAmB8fp5S1j8UEKjWWofKQ8rHuac1ehL9mf99jdBboDHskTHFSen6uUxHDHW3za/caZMIzvzwvNNSs+sLgaLM+enU17B/lxNwSL86vWm+jLWKztUpKHGpJTDVU7OgMAhfXuqjywupF96XN+kSKAche9T+hhCPlNY2v52OGBNsU7i6mId4wr4lwDwj37ba6J6MFrSnumwRVEphX7UYKYjqOz9MrbbnXCR3BBApkoEEYftHkp+U+VrxVJsqaK+HmrmxiJorIdtYv/hy/UJZtmlxWeU35sdKZAgtoyD8TOz39S1r7H1Ah6qM2khpcDK58QnprRmZTIRcRFVn79VceZf2hiaS4TQXHYBHYeSx/FhATvQInoSMfQjLRYyad/23Vk6t40NLq9W+6Gd3KXzrRlq+79PBdQOd5RCiePxTD/xQSAsNV0NHSzhsggEvtPUlgXLx9B12zZjspu6V/0ofrLIzysF/XwuQnis6TIqoTpwZxjsMLgiy0UTiP+ROidb4Mzeq82KUaKVvh6Au5sFtO4eiQhQS9K2xdHO8CbhHTw== jgj@toolpack.one"
  ];

  home-manager.users.jgjo = import ./home.nix;

  system.stateVersion = "23.05";
}

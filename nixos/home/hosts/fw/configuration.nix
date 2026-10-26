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
    # Framework 13 Pro quirks (Intel Core Ultra Series 3); see the Framework NixOS guide
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
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

  networking.hostName = "fw";

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
  # udev autoloads this next to `button`; it signals init to power off on every
  # press (SIGRTMIN+4), bypassing logind and PowerDevil entirely
  boot.blacklistedKernelModules = [ "tiny_power_button" ];
  # touchpad
  services.libinput.enable = true;
  # multi-touch gesture recognizer
  # if touche app cant see touchegg: "flatpak override --user --env=XDG_CONFIG_DIRS=/var/run/host/etc/xdg com.github.joseexposito.touche"

  # Firmware updates: run `fwupdmgr update` (fwupd is enabled by nixos-hardware)

  users.users.jgjo.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPZ/LKt2V0JEb06a34/ktDMWXF3p6+ENQp2uqBnlNc0 johannes@orager.dk"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCi1XdYAnbBOL/PYjWOz0PLwajQR2I8pnA52r/jhW2XTslPOvEVoFXzBs8f2M4EIfrubzrH6CE6rBoXgCHU0605ClxrExA/z74hsgwEI3hvTeSM9P1+h/eafr+yLh0/WyJQH1PPAmB8fp5S1j8UEKjWWofKQ8rHuac1ehL9mf99jdBboDHskTHFSen6uUxHDHW3za/caZMIzvzwvNNSs+sLgaLM+enU17B/lxNwSL86vWm+jLWKztUpKHGpJTDVU7OgMAhfXuqjywupF96XN+kSKAche9T+hhCPlNY2v52OGBNsU7i6mId4wr4lwDwj37ba6J6MFrSnumwRVEphX7UYKYjqOz9MrbbnXCR3BBApkoEEYftHkp+U+VrxVJsqaK+HmrmxiJorIdtYv/hy/UJZtmlxWeU35sdKZAgtoyD8TOz39S1r7H1Ah6qM2khpcDK58QnprRmZTIRcRFVn79VceZf2hiaS4TQXHYBHYeSx/FhATvQInoSMfQjLRYyad/23Vk6t40NLq9W+6Gd3KXzrRlq+79PBdQOd5RCiePxTD/xQSAsNV0NHSzhsggEvtPUlgXLx9B12zZjspu6V/0ofrLIzysF/XwuQnis6TIqoTpwZxjsMLgiy0UTiP+ROidb4Mzeq82KUaKVvh6Au5sFtO4eiQhQS9K2xdHO8CbhHTw== jgj@toolpack.one"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuhSgtnu/KlLpBzh3cLznt/0+KeWBPlnJ4al7Oz+sA+ johannes@orager.dk"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKPA28tG6KmEQzjF8QcxeCah6fu92XMbkcvNVw/lZNsthfoJpIb0m7GRnGJ3LUe/FvfiEQ8hI0tqNOs6xH8pefF0Ew6895nZfwN0s83vtimVnmprezUpUgks2o+oTcjPM3NKtpqz6Pym7qeq1xtuN0wle7qKd5Wv0vMMqYuNYe4OKdS+U+NRgiYEc74F2Pc6FT4GU3vPkdlOBoZkjh/0TbGYVBvoW/q/+BoKHFRzp0qa1I/Zr5FLb6VAO4o4BEh6qJWURnWE7I4fyr6rOU0yOkwx9RwALCgdKEXVHKTEyaEodtIxOESIr5FJXelBhHi9OxqlU4f6okBksibJaoPEO7yobuRQ3+r0PUviuhC8j/Ev/cTRtODIZAvK2CPY6PPRwDspQeuRbWQkJHcmK45LUgPZvh0E6jv8uCNxZO55pk8pAf9p67ovHmJ7q6hJQROrku5jOc45SKMx1jFfT/VqHagE8DbwKXbQrsFlqzptR4lG14skJF1R/8YK3GDhQmiUMNrJqUwxMZxdVrxV+2gfC2aylnY/77z0c8h5PeUKBuXReI9c+n+z69HGEiCL9fVAHuA5VU5fSAYtkDsKjRlV42qZ9hUf8hOqnKJ/sh3gxtIXLp/zLMxQaliulgaMQ3sjEM52rxzSaSh9lUaoLRfsg6t6jARbYGxTNW5+lvP2g8sw== jgj@toolpack.one"
  ];

  home-manager.users.jgjo = import ./home.nix;

  system.stateVersion = "26.05"; # set to the value the installer generated
}

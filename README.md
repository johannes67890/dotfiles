# ⚡ NixOS + Home Manager Dotfiles

Opinionated, reproducible NixOS with Plasma 6, Home Manager, Plasma Manager and Secure Boot (Lanzaboote).

- System: [`nixosConfigurations.jgjo`](flake.nix)
- Home: applied by each system through home-manager ([`home/shared`](home/shared), per-host `home/hosts/<host>/home.nix`)
- Modules: [`system/modules`](system/modules)
- Plasma config: [`home/config/kde/plasma.nix`](home/config/kde/plasma.nix)

## TL;DR

```sh
# Switch system (host: jgjo)
sudo nixos-rebuild switch --flake .#jgjo

# Update inputs, then rebuild
nix flake update
sudo nixos-rebuild switch --flake .#jgjo

# Garbage collect
nix-collect-garbage

# Garbage collect all old gens
nix-collect-garbage -d
```

## Avaliable hosts
```sh
jgjo #desktop
```

```sh
surface #Surface Laptop 3
```

```sh
fw #Framework Laptop 13 Pro
```

## Repo layout

```
flake.nix
home/
  hosts/<host>/{configuration.nix,hardware-configuration.nix,home.nix}
  shared/{home.nix,config.nix,packages.nix}
  config/kde/plasma.nix
system/
  config.nix
  modules/{boot.nix,bootSecure.nix,hardware.nix,hardware-non-nvidia.nix,kde.nix,file-limits.nix,itu-wifi.nix}
pkgs/azure-functions-core-tools/
```

- Main entrypoint: [`home/hosts/main/configuration.nix`](home/hosts/main/configuration.nix)
- Plasma setup: [`home/config/kde/plasma.nix`](home/config/kde/plasma.nix)
- Secure boot: Lanzaboote via [`system/modules/bootSecure.nix`](system/modules/bootSecure.nix)
- Normal boot: systemd-boot via [`system/modules/boot.nix`](system/modules/boot.nix)

## Boot entries and GC

- Keep boot menu lean via `configurationLimit` in [`system/modules/boot.nix`](system/modules/boot.nix).
- Automatic store GC weekly, deleting paths older than 30 days is configured in [`system/config.nix`](system/config.nix).

Run now:

```sh
sudo nix-collect-garbage --delete-older-than 30d
```

Want only the latest boot entry? Set this and rebuild:

```nix
# system/modules/boot.nix
boot.loader.systemd-boot.configurationLimit = 1;
```

## Plasma

- Panels, widgets, and shortcuts are managed with Plasma Manager in [`home/config/kde/plasma.nix`](home/config/kde/plasma.nix).
- KWin tweaks and tiling rules live in the same file.

Restart shell quickly:

```sh
systemctl --user restart plasma-plasmashell.service plasma-kglobalaccel.service
```

## Development

```sh
# Format nix files
nix fmt

# Search packages
nix search nixpkgs firefox

# Check every host still evaluates (run before committing shared changes)
nix flake check --no-build

# Build without switching
nix build .#nixosConfigurations.jgjo.config.system.build.toplevel

# Debug build failures
sudo nixos-rebuild switch --flake .#jgjo --show-trace
```

## Notes

- Unfree allowed in [`system/config.nix`](system/config.nix).
- NVIDIA and Wayland-ready in [`system/modules/hardware.nix`](system/modules/hardware.nix) and [`system/modules/kde.nix`](system/modules/kde.nix).

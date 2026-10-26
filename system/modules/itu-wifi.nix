{ ... }: {
  # ITU++ (TTLS + MSCHAPv2) needs legacy TLS renegotiation, which OpenSSL 3
  # refuses by default; the patch allows it. Only matters on wpa_supplicant hosts.
  nixpkgs.config.packageOverrides = pkgs: {
    wpa_supplicant = pkgs.wpa_supplicant.overrideAttrs (attrs: {
      patches = attrs.patches ++ [ ./patches/itu++.patch ];
    });
  };
}

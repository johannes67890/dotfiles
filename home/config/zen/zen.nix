# Zen Browser (https://github.com/0xc000022070/zen-browser-flake), the default
# browser on every host. Close Zen before switching if you add spaces/pins/shortcuts.
{ pkgs, ... }:
{
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    # lets KeePassXC-Browser talk to the KeePassXC app
    nativeMessagingHosts = [ pkgs.keepassxc ];

    # policies.json, enforced: https://mozilla.github.io/policy-templates/
    policies = {
      DisableAppUpdate = true; # updates come from the flake
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false; # KeePassXC does that

      # Extensions, installed and kept on every start. Add one as
      # "<extension id>" = "<slug from addons.mozilla.org/firefox/addon/<slug>>";
      # the id is on about:debugging#/runtime/this-firefox once it is installed by hand.
      ExtensionSettings = builtins.mapAttrs (_: slug: {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        installation_mode = "force_installed";
      }) {
        "uBlock0@raymondhill.net" = "ublock-origin";
        "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
      };
    };

    # prefs.js defaults you can still change in the browser (about:config)
    profiles.default.settings = {
      "zen.welcome-screen.seen" = true;
    };
  };
}

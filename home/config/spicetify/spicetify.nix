# Spotify themed with Spicetify: the "text" theme in black & white, after
# https://github.com/43PR/dotfiles (.config/spicetify). Installs Spotify itself,
# so don't add pkgs.spotify anywhere else.
{ pkgs, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.text // {
      # Their tweaks on top of upstream user.css (appended, so these win).
      additionalCss = ''
        :root {
          --font-size-lyrics: 24px;
          --display-header-image: block;
          --display-tracklist-image: block;
          --border-radius: 4px;
          --border-style: dashed;
        }
        .spotify__container--is-desktop.spotify__os--is-linux .Root__globalNav {
          margin: 1px 0 0;
        }
        .encore-dark-theme,
        .encore-dark-theme .encore-base-set {
          --background-highlight: #000000;
          --background-press: #000000;
          --background-elevated-press: #000000;
          --background-tinted-base: #000000;
          --background-tinted-highlight: #000000;
          --background-tinted-press: #000000;
        }
        /* hover: white outline instead of grey fill */
        .main-trackList-trackListRow:focus-within,
        .main-trackList-trackListRow:hover,
        .main-contextMenu-menuItemButton:hover,
        .main-contextMenu-menuItemButton:not([aria-checked="true"]):focus,
        .main-card-card:hover,
        .main-card-card[data-context-menu-open="true"] {
          background-color: var(--spice-main) !important;
          border: 1px solid #ffffff !important;
        }
        [class*="listRow-isInteractive"]:hover,
        [class*="listRow-isInteractive"]:hover::after {
          background-color: var(--spice-main) !important;
        }
        /* panes keep their dim border on hover */
        .Root__globalNav:hover,
        .main-yourLibraryX-entryPoints:hover,
        .Root__main-view:hover,
        .main-nowPlayingBar-container:hover,
        .Root__right-sidebar:has(aside:not(:empty)):hover {
          border-color: var(--spice-border-inactive);
        }
        .player-controls__buttons,
        .main-nowPlayingBar-extraControls {
          opacity: 0.7;
        }
      '';
    };

    # "Monochrome" from their color.ini
    customColorScheme = {
      accent = "FFFFFF";
      accent-active = "555555";
      accent-inactive = "121212";
      banner = "FFFFFF";
      border-active = "333333";
      border-inactive = "121212";
      header = "535353";
      highlight = "999999";
      main = "000000";
      notification = "FFFFFF";
      notification-error = "e22134";
      subtext = "FFFFFF";
      text = "FFFFFF";
    };
  };
}

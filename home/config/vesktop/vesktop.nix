# Discord via Vesktop, themed with system24 in the same black & white as Spotify.
{ ... }:
{
  programs.vesktop = {
    enable = true;
    # Discord's 940px minimum is wider than half the screen, so a tiled window spills over its neighbour.
    settings.disableMinSize = true;
    # Keep options changed in the app (same for vencord below); only the values set here are forced.
    mutableSettings = true;
    vencord = {
      themes.system24 = ./system24.theme.css;
      settings.enabledThemes = [ "system24.css" ];
      mutableSettings = true;
    };
  };
}

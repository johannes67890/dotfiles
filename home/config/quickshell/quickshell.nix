# Quick settings menu (search, Claude, system stats, media, network, tools, ...) in 43PR's Quickshell style.
# Runs as a user service; Alt+F toggles it (hotkey in kde/plasma.nix).
{ pkgs, ... }:
let
  # Claude answers -> Qt rich text with highlighted code blocks (called by menu/services/Claude.qml).
  renderMdUnchecked = pkgs.writers.writePython3Bin "quickshell-md" {
    libraries = with pkgs.python3Packages; [ markdown pygments ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./render-md.py);
  # The build fails if the renderer ever outputs a tag that would make Qt load a URL again.
  renderMd = pkgs.runCommand "quickshell-md" { } ''
    html=$(${renderMdUnchecked}/bin/quickshell-md '<table background="http://x/a"><tr><td>t</td></tr></table> <span style="background-image:url(http://x/b)">s</span> ![i](http://x/c) <img src="http://x/d">')
    if printf '%s' "$html" | grep -qiE '<(img|[a-z]+[^>]*(background|url\())'; then
      echo "quickshell-md let a URL-loading tag through: $html" >&2
      exit 1
    fi
    mkdir -p $out/bin
    ln -s ${renderMdUnchecked}/bin/quickshell-md $out/bin/quickshell-md
  '';
  # Mail from Thunderbird's local cache, as JSON (menu/services/Mail.qml). The build checks it on a tiny profile:
  # deleted mail skipped, read state and encoded headers right, HTML bodies turned into text with no URLs left.
  mailUnchecked = pkgs.writers.writePython3Bin "quickshell-mail" {
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./mail.py);
  mail = pkgs.runCommand "quickshell-mail" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir -p profile/ImapMail/x
    printf '%s\n' 'user_pref("mail.server.server1.type", "imap");' 'user_pref("mail.server.server1.name", "test@example.com");' \
      'user_pref("mail.server.server1.directory-rel", "[ProfD]ImapMail/x");' > profile/prefs.js
    printf 'From - x\r\nX-Mozilla-Status: 0001\r\nFrom: Old <old@example.com>\r\nSubject: Read one\r\nDate: Mon, 01 Jan 2024 09:00:00 +0000\r\nMessage-ID: <1@x>\r\n\r\nbody\r\n'  > profile/ImapMail/x/INBOX
    printf 'From - x\r\nX-Mozilla-Status: 0009\r\nFrom: Gone <gone@example.com>\r\nSubject: Deleted\r\nDate: Mon, 01 Jan 2024 10:00:00 +0000\r\nMessage-ID: <2@x>\r\n\r\nbody\r\n' >> profile/ImapMail/x/INBOX
    printf 'From - x\r\nX-Mozilla-Status: 0000\r\nFrom: =?utf-8?q?S=C3=B8ren?= <s@example.com>\r\nSubject: =?utf-8?q?Hej_=C3=B8?=\r\nDate: Mon, 01 Jan 2024 11:00:00 +0000\r\nMessage-ID: <3@x>\r\n\r\n>From body\r\n' >> profile/ImapMail/x/INBOX
    printf 'From - x\r\nX-Mozilla-Status: 0001\r\nFrom: Shop <shop@example.com>\r\nSubject: Order\r\nDate: Mon, 01 Jan 2024 08:00:00 +0000\r\nMessage-ID: <4@x>\r\nContent-Type: multipart/mixed; boundary="B"\r\n\r\n--B\r\nContent-Type: text/html\r\n\r\n<p>Hi&nbsp;there</p><img src="http://track/x.gif"><script>x()</script>\r\n--B\r\nContent-Type: application/pdf\r\nContent-Disposition: attachment; filename="invoice.pdf"\r\n\r\nJVBERi0=\r\n--B--\r\n' >> profile/ImapMail/x/INBOX
    ${mailUnchecked}/bin/quickshell-mail --profile profile > list.json
    ${mailUnchecked}/bin/quickshell-mail --profile profile --body test@example.com 4@x > body.json
    jq -e '[.messages[] | [.from, .subject, .unread]] == [["Søren", "Hej ø", true], ["Old", "Read one", false], ["Shop", "Order", false]] and .accounts[0].unread == 1' list.json \
      && jq -e '.body == "Hi there" and .attachments == ["invoice.pdf"]' body.json \
      || { echo "quickshell-mail check failed:"; cat list.json body.json; exit 1; }
    mkdir -p $out/bin
    ln -s ${mailUnchecked}/bin/quickshell-mail $out/bin/quickshell-mail
  '';
in
{
  home.packages = [ renderMd mail pkgs.libqalculate ]; # libqalculate: qalc for the search's calculator
  programs.quickshell = {
    enable = true;
    configs.menu = ./menu;
    activeConfig = "menu";
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };
}

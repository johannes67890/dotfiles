{ config, pkgs, inputs, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  
  home = {
    username = "jgjo";
    homeDirectory = "/home/jgjo";
    stateVersion = "24.11";
  };

  # Add user-level packages
  home.packages = with pkgs; [
    terminus_font
    terminus_font_ttf
    lazygit    
    wget
    curl
    btop
    git
    vim
    zsh
    vscode
    firefox
    grimblast
  ];

  fonts.fontconfig.enable = true;
  
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "Terminus";
          style = "Regular";
        };
        size = 12;
      };
    };
  };
  
  programs.home-manager.enable = true;
  programs.kitty.enable = true;
  programs.neovim.enable = true;
  programs.zsh.enable = true;
  programs.tmux.enable = true;

  programs.git = {
    enable = true;
    userName = "johannes67890";
    userEmail = "johannes@orager.dk";
  };

  # Add Hyprland configuration via home-manager
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = ",preferred,auto,auto";
      
      exec-once = [
        "waybar"
        "dunst"
      ];
      
      "$mod" = "SUPER";
      
      bind = [
        "$mod, Return, exec, kitty"
        "$mod, R, exec, wofi --show drun"
        "$mod, Q, killactive"
        "$mod, E, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen, 0"
        
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
      ];
      
      input = {
        kb_layout = "dk";
        follow_mouse = 1;
      };
      
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 8;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
      };
      
      animations = {
        enabled = true;
      };
    };
  };

  # Keep waybar configuration
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
      target = "graphical-session.target";
    };
    style = ''
             * {
               font-family: "JetBrainsMono Nerd Font";
               font-size: 12pt;
               font-weight: bold;
               border-radius: 8px;
               transition-property: background-color;
               transition-duration: 0.5s;
             }
             @keyframes blink_red {
               to {
                 background-color: rgb(242, 143, 173);
                 color: rgb(26, 24, 38);
               }
             }
             .warning, .critical, .urgent {
               animation-name: blink_red;
               animation-duration: 1s;
               animation-timing-function: linear;
               animation-iteration-count: infinite;
               animation-direction: alternate;
             }
             window#waybar {
               background-color: transparent;
             }
             window > box {
               margin-left: 5px;
               margin-right: 5px;
               margin-top: 5px;
               background-color: #1e1e2a;
               padding: 3px;
               padding-left:8px;
               border: 2px none #33ccff;
             }
       #workspaces {
               padding-left: 0px;
               padding-right: 4px;
             }
       #workspaces button {
               padding-top: 5px;
               padding-bottom: 5px;
               padding-left: 6px;
               padding-right: 6px;
             }
       #workspaces button.active {
               background-color: rgb(181, 232, 224);
               color: rgb(26, 24, 38);
             }
       #workspaces button.urgent {
               color: rgb(26, 24, 38);
             }
       #workspaces button:hover {
               background-color: rgb(248, 189, 150);
               color: rgb(26, 24, 38);
             }
             tooltip {
               background: rgb(48, 45, 65);
             }
             tooltip label {
               color: rgb(217, 224, 238);
             }
       #custom-launcher {
               font-size: 20px;
               padding-left: 8px;
               padding-right: 6px;
               color: #7ebae4;
             }
       #mode, #clock, #memory, #temperature,#cpu,#mpd, #custom-wall, #temperature, #backlight, #pulseaudio, #network, #battery, #custom-powermenu, #custom-cava-internal {
               padding-left: 10px;
               padding-right: 10px;
             }
             /* #mode { */
             /* 	margin-left: 10px; */
             /* 	background-color: rgb(248, 189, 150); */
             /*     color: rgb(26, 24, 38); */
             /* } */
       #memory {
               color: rgb(181, 232, 224);
             }
       #cpu {
               color: rgb(245, 194, 231);
             }
       #clock {
               color: rgb(217, 224, 238);
             }
      /* #idle_inhibitor {
               color: rgb(221, 182, 242);
             }*/
       #custom-wall {
               color: #33ccff;
          }
       #temperature {
               color: rgb(150, 205, 251);
             }
       #backlight {
               color: rgb(248, 189, 150);
             }
       #pulseaudio {
               color: rgb(245, 224, 220);
             }
       #network {
               color: #ABE9B3;
             }
       #network.disconnected {
               color: rgb(255, 255, 255);
             }
       #custom-powermenu {
               color: rgb(242, 143, 173);
               padding-right: 8px;
             }
       #tray {
               padding-right: 8px;
               padding-left: 10px;
             }
       #mpd.paused {
               color: #414868;
               font-style: italic;
             }
       #mpd.stopped {
               background: transparent;
             }
       #mpd {
               color: #c0caf5;
             }
       #custom-cava-internal{
               font-family: "Hack Nerd Font" ;
               color: #33ccff;
             }
        '';
    settings = [{
      "layer" = "top";
      "position" = "top";
      modules-left = [
        "custom/launcher"
        "temperature"
        "mpd"
        "custom/cava-internal"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "pulseaudio"
        "backlight"
        "memory"
        "cpu"
        "network"
        "custom/powermenu"
        "tray"
      ];
      "custom/launcher" = {
        "format" = " ";
        "on-click" = "pkill rofi || rofi2";
        "on-click-middle" = "exec default_wall";
        "on-click-right" = "exec wallpaper_random";
        "tooltip" = false;
      };
      "custom/cava-internal" = {
        "exec" = "sleep 1s && cava-internal";
        "tooltip" = false;
      };
      "pulseaudio" = {
        "scroll-step" = 1;
        "format" = "{icon} {volume}%";
        "format-muted" = "󰖁 Muted";
        "format-icons" = {
          "default" = [ "" "" "" ];
        };
        "on-click" = "pamixer -t";
        "tooltip" = false;
      };
      "clock" = {
        "interval" = 1;
        "format" = "{:%I:%M %p  %A %b %d}";
        "tooltip" = true;
        "tooltip-format"= "{=%A; %d %B %Y}\n<tt>{calendar}</tt>";
      };
      "memory" = {
        "interval" = 1;
        "format" = "󰻠 {percentage}%";
        "states" = {
          "warning" = 85;
        };
      };
      "cpu" = {
        "interval" = 1;
        "format" = "󰍛 {usage}%";
      };
      "mpd" = {
        "max-length" = 25;
        "format" = "<span foreground='#bb9af7'></span> {title}";
        "format-paused" = " {title}";
        "format-stopped" = "<span foreground='#bb9af7'></span>";
        "format-disconnected" = "";
        "on-click" = "mpc --quiet toggle";
        "on-click-right" = "mpc update; mpc ls | mpc add";
        "on-click-middle" = "kitty --class='ncmpcpp' ncmpcpp ";
        "on-scroll-up" = "mpc --quiet prev";
        "on-scroll-down" = "mpc --quiet next";
        "smooth-scrolling-threshold" = 5;
        "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
      };
      "network" = {
        "format-disconnected" = "󰯡 Disconnected";
        "format-ethernet" = "󰒢 Connected!";
        "format-linked" = "󰖪 {essid} (No IP)";
        "format-wifi" = "󰖩 {essid}";
        "interval" = 1;
        "tooltip" = false;
      };
      "custom/powermenu" = {
        "format" = "";
        "on-click" = "pkill rofi || ~/.config/rofi/powermenu/type-3/powermenu.sh";
        "tooltip" = false;
      };
      "tray" = {
        "icon-size" = 15;
        "spacing" = 5;
      };
    }];
  };
}

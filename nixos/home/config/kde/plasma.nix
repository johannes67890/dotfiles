# qdbus org.kde.KWin /KWin reconfigure
# systemctl --user restart plasma-plasmashell.service plasma-kglobalaccel.service
{ inputs, config, lib, pkgs, ... }:
{
  programs.plasma = let
    wallpaper = "${inputs.self}/home/assets/wallpaper/space.png";
  in {
    enable = true;
   
      workspace = {
        lookAndFeel = "org.kde.breezedark.desktop";
        cursor = {
          size = 24;
        };
        iconTheme = "Win11-black-dark";
        wallpaper = wallpaper;
      };
    
    input.mice = [
      # Home pc mouse settings
      {
        name = "Finalmouse UltralightX dongle Mouse";
        vendorId = "13853";
        productId = "256";
        enable = true;
        acceleration = 0;
        accelerationProfile = "none"; 
      }
    ];

    fonts = {
      # Use a UI font for general/menu/toolbar/window title
      general = { family = "Noto Sans"; pointSize = 10; };
      menu = { family = "Noto Sans"; pointSize = 10; };
      toolbar = { family = "Noto Sans"; pointSize = 10; };
      windowTitle = { family = "Noto Sans"; pointSize = 10; };
      small = { family = "Noto Sans"; pointSize = 9; };

      # Keep monospace for terminals/editors
      fixedWidth = { family = "JetBrains Mono"; pointSize = 11; };
    };

    krunner = {
      historyBehavior = "enableSuggestions"; 
      position = "center";
      shortcuts.launch = [ "Alt+F" "Alt+Space" ]; 
    };

    kscreenlocker = {
        lockOnResume = true;
        lockOnStartup = false;
      appearance = {
        wallpaper = wallpaper;
      };
    };

    panels = [
      # Windows-like panel at the bottom
        {   
        height= 40;
        location = "bottom";
        screen = 0;

        widgets = [
          # Left spacer (expands)
          {
            name = "org.kde.plasma.panelspacer";
            config = { General = { expanding = true; length = 0; }; };
          }
          # Or you can configure the widgets by adding the widget-specific options for it.
          # See modules/widgets for supported widgets and options for these widgets.
          # For example:
          {
            kickoff = {
              sortAlphabetically = true;
            };
          }
          # Adding configuration to the widgets can also for example be used to
          # pin apps to the task-manager, which this example illustrates by
          # pinning dolphin and konsole to the task-manager by default with widget-specific options.
          {
            name = "org.kde.plasma.icontasks";
            config = {
              General = {
                # Merge pinned launchers with running tasks
                separateLaunchers = false;
                # find launchers with:
                # ls /run/current-system/sw/share/applications | sort
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:com.google.Chrome.desktop"
                  "applications:code.desktop"
                  "applications:obsidian.desktop"
                  "applications:postman.desktop"
                  "applications:veracrypt.desktop"
                ];
              };
            };
          }

          {
            name = "org.kde.plasma.panelspacer";
            config = { General = { expanding = true; length = 0; }; };
          }

          {
            systemTray.items = {
              # We explicitly show bluetooth and battery
              shown = [
                "org.kde.plasma.battery"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.volume"
              ];
              # And explicitly hide networkmanagement and volume
              hidden = [
                "org.kde.plasma.applicationstatus"
                "org.kde.plasma.networkmanagement"
              ];
            };
          }
        ];
        hiding = "normalpanel";
      }

      {
        location = "top"; 
        height = 26;
        screen = 0;

        # Find widgets with:
        # ls /run/current-system/sw/share/plasma/plasmoids | sort
        # ls ~/.local/share/plasma/plasmoids | sort
        widgets = [
          # virtual desktop switcher
          {
            name = "org.kde.plasma.plasm6desktopindicator";
            config = {
              General = {
                desktopWrapOn = true;
                dotSizeCustom = 15;
                spacingHorizontal = 12;
                spacingVertical = 8;
                showAddDesktop = true;
              };
            };
          }
          # Default
          # {
          #   name = "org.kde.plasma.pager";
          #   config = {
          #     General = {
          #       showOnlyCurrentScreen = false;
                
          #     };
          #   };
          # }
          
          # spacer
          {
            name = "org.kde.plasma.panelspacer";
            config = { General = { expanding = true; length = 0; }; };
          }

          # clock
          {
            name = "org.kde.plasma.digitalclock";
            config = {
              General = {
                showDate = true;
                showSeconds = false;
              };
              calendar = {
                firstDayOfWeek = "monday";
              };
              time = {
                format = "24h";
              };
            };
          }


          # spacer
          {
            name = "org.kde.plasma.panelspacer";
            config = { General = { expanding = false; length = 10; }; };
          }

          # weather
          { name = "org.kde.plasma.weather"; }
          # spacer
          {
            name = "org.kde.plasma.panelspacer";
            config = { General = { expanding = true; length = 0; }; };
          }

          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.colorpicker"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.systemmonitor.net"
                "org.kde.plasma.networkmanagement"
              ];
              hidden = [ 
                "org.kde.plasma.battery"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.volume"
                "org.kde.plasma.applicationstatus"
               ];
            };
          }
        ];  
          hiding = "normalpanel";
      }
          
 
    ];

    powerdevil = {
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend = {
          action = "shutDown";
          idleTimeout = 1000;
        };
        turnOffDisplay = {
          idleTimeout = 1000;
          idleTimeoutWhenLocked = "immediately";
        };
      };
      battery = {
        powerButtonAction = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
      };
      lowBattery = {
        whenLaptopLidClosed = "hibernate";
      };
    };

    kwin = {
      edgeBarrier = 0; # Disables the edge-barriers introduced in plasma 6.1
    };

    shortcuts = {
      "KDE Keyboard Layout Switcher" = {
        "Switch keyboard layout to Danish" = [ ];
        "Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
        "Switch to Next Keyboard Layout" = "Meta+Alt+K";
      };

      kaccess = {
        "Toggle Screen Reader On and Off" = "Meta+Alt+S";
      };

      kmix = {
        decrease_microphone_volume = "Microphone Volume Down";
        decrease_volume = "Volume Down";
        decrease_volume_small = "Shift+Volume Down";
        increase_microphone_volume = "Microphone Volume Up";
        increase_volume = "Volume Up";
        increase_volume_small = "Shift+Volume Up";
        mic_mute = ["Microphone Mute" "Meta+Volume Mute"];
        mute = "Volume Mute";
      };

      ksmserver = {
        "Halt Without Confirmation" = [ ];
        "Lock Session" = ["Meta+L" "Screensaver"];
        "Log Out" = "Ctrl+Alt+Del";
        "Log Out Without Confirmation" = [ ];
        LogOut = [ ];
        Reboot = [ ];
        "Reboot Without Confirmation" = [ ];
        "Shut Down" = [ ];
      };

      kwin = {
        "Activate Window Demanding Attention" = "Meta+Ctrl+A";
        "Cycle Overview" = [ ];
        "Cycle Overview Opposite" = [ ];
        "Decrease Opacity" = [ ];
        "Edit Tiles" = "Meta+T";
        Expose = "Ctrl+F9";
        ExposeAll = ["Ctrl+F10" "Launch (C)"];
        ExposeClass = "Ctrl+F7";
        ExposeClassCurrentDesktop = [ ];
        "Grid View" = "Meta+G";
        "Increase Opacity" = [ ];
        "Kill Window" = "Meta+Ctrl+Esc";
        "Move Tablet to Next Output" = [ ];
        MoveMouseToCenter = "Meta+F6";
        MoveMouseToFocus = "Meta+F5";
        MoveZoomDown = [ ];
        MoveZoomLeft = [ ];
        MoveZoomRight = [ ];
        MoveZoomUp = [ ];
        Overview = "Meta+W";
        PoloniumCycleEngine = "Meta+|";
        PoloniumFocusAbove = "Meta+K";
        PoloniumFocusBelow = "Meta+J";
        PoloniumFocusLeft = "Meta+H";
        PoloniumFocusRight = [ ];
        PoloniumInsertAbove = "Meta+Shift+K";
        PoloniumInsertBelow = "Meta+Shift+J";
        PoloniumInsertLeft = "Meta+Shift+H";
        PoloniumInsertRight = "Meta+Shift+L";
        PoloniumOpenSettings = "Meta+\\\\,none";
        PoloniumResizeAbove = "Meta+Ctrl+K";
        PoloniumResizeBelow = "Meta+Ctrl+J";
        PoloniumResizeLeft = "Meta+Ctrl+H";
        PoloniumResizeRight = "Meta+Ctrl+L";
        PoloniumRetileWindow = "Meta+Shift+Space";
        PoloniumSwitchBTree = [ ];
        PoloniumSwitchHalf = [ ];
        PoloniumSwitchKwin = [ ];
        PoloniumSwitchMonocle = [ ];
        PoloniumSwitchThreeColumn = [ ];
        "Setup Window Shortcut" = [ ];
        "Show Desktop" = "Meta+D";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch Window Down" = "Meta+Alt+Down";
        "Switch Window Left" = "Meta+Alt+Left";
        "Switch Window Right" = "Meta+Alt+Right";
        "Switch Window Up" = "Meta+Alt+Up";
        "Switch to Desktop 1" = "Ctrl+F1";
        "Switch to Desktop 2" = "Ctrl+F2";
        "Switch to Desktop 3" = "Ctrl+F3";
        "Switch to Desktop 4" = "Ctrl+F4";
        "Switch to Next Desktop" = [ ];
        "Switch to Next Screen" = [ ];
        "Switch to Previous Desktop" = [ ];
        "Switch to Previous Screen" = [ ];
        "Switch to Screen 0" = [ ];
        "Switch to Screen 1" = [ ];
        "Switch to Screen 2" = [ ];
        "Toggle Night Color" = [ ];
        "Toggle Window Raise/Lower" = [ ];
        "Walk Through Windows" = ["Meta+Tab" "Alt+Tab"];
        "Walk Through Windows (Reverse)" = ["Meta+Shift+Tab" "Alt+Shift+Tab"];
        "Walk Through Windows Alternative" = [ ];
        "Walk Through Windows Alternative (Reverse)" = [ ];
        "Walk Through Windows of Current Application" = ["Meta+`" "Alt+`"];
        "Walk Through Windows of Current Application (Reverse)" = ["Meta+~" "Alt+~"];
        "Walk Through Windows of Current Application Alternative" = [ ];
        "Walk Through Windows of Current Application Alternative (Reverse)" = [ ];
        "Window Above Other Windows" = [ ];
        "Window Below Other Windows" = [ ];
        "Window Close" = ["Alt+F4" "Alt+Del"];
        "Window Custom Quick Tile Bottom" = [ ];
        "Window Custom Quick Tile Left" = [ ];
        "Window Custom Quick Tile Right" = [ ];
        "Window Custom Quick Tile Top" = [ ];
        "Window Fullscreen" = [ ];
        "Window Grow Horizontal" = [ ];
        "Window Grow Vertical" = [ ];
        "Window Lower" = [ ];
        "Window Maximize" = ["Meta+Return" "Meta+PgUp"];
        "Window Maximize Horizontal" = [ ];
        "Window Maximize Vertical" = [ ];
        "Window Minimize" = ["Meta+Backspace" "Meta+PgDown"];
        "Window Move" = [ ];
        "Window Move Center" = [ ];
        "Window No Border" = [ ];
        "Window On All Desktops" = [ ];
        "Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
        "Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
        "Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
        "Window One Screen Down" = [ ];
        "Window One Screen Up" = [ ];
        "Window One Screen to the Left" = [ ];
        "Window One Screen to the Right" = [ ];
        "Window Operations Menu" = "Alt+F3";
        "Window Pack Down" = [ ];
        "Window Pack Left" = [ ];
        "Window Pack Right" = [ ];
        "Window Pack Up" = [ ];
        "Window Quick Tile Bottom" = "Meta+Down";
        "Window Quick Tile Bottom Left" = [ ];
        "Window Quick Tile Bottom Right" = [ ];
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Window Quick Tile Top" = "Meta+Up";
        "Window Quick Tile Top Left" = [ ];
        "Window Quick Tile Top Right" = [ ];
        "Window Raise" = [ ];
        "Window Resize" = [ ];
        "Window Shrink Horizontal" = [ ];
        "Window Shrink Vertical" = [ ];
        "Window to Desktop 1" = [ ];
        "Window to Next Desktop" = [ ];
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Desktop" = [ ];
        "Window to Previous Screen" = "Meta+Shift+Left";
        "Window to Screen 0" = [ ];
        "Window to Screen 1" = [ ];
        "Window to Screen 2" = [ ];
        disableInputCapture = "Meta+Shift+Esc";
        view_actual_size = "Meta+0";
        view_zoom_in = ["Meta++" "Meta+="];
        view_zoom_out = "Meta+-";
      };

      mediacontrol = {
        mediavolumedown = [ ];
        mediavolumeup = [ ];
        nextmedia = "Media Next";
        pausemedia = "Media Pause";
        playmedia = [ ];
        playpausemedia = "Media Play";
        previousmedia = "Media Previous";
        stopmedia = "Media Stop";
      };

      plasmashell = {
        "Slideshow Wallpaper Next Image" = [ ];
        "activate application launcher" = ["Meta" "Alt+F1"];
        "activate task manager entry 1" = "Meta+1";
        "activate task manager entry 2" = "Meta+2";
        "activate task manager entry 3" = "Meta+3";
        "activate task manager entry 4" = "Meta+4";
        "activate task manager entry 5" = "Meta+5";
        "activate task manager entry 6" = "Meta+6";
        "activate task manager entry 7" = "Meta+7";
        "activate task manager entry 8" = "Meta+8";
        "activate task manager entry 9" = "Meta+9";
        clear-history = [ ];
        clipboard_action = "Meta+Ctrl+X";
        cycle-panels = "Meta+Alt+P";
        cycleNextAction = [ ];
        cyclePrevAction = [ ];
        edit_clipboard = [ ];
        "manage activities" = "Meta+Q";
        "next activity" = "Meta+A";
        "previous activity" = "Meta+Shift+A";
        repeat_action = [ ];
        "show dashboard" = "Ctrl+F12";
        show-barcode = [ ];
        show-on-mouse-pos = "Meta+V";
        "switch to next activity" = [ ];
        "switch to previous activity" = [ ];
        "toggle do not disturb" = [ ];
      };

      "services/org.kde.krunner.desktop" = {
        _launch = ["Search" "Alt+F2" "Alt+F" "Alt+Space"];
      };

      "services/plasma-manager-commands.desktop" = {
        launch-konsole = "Alt+T";
      };
    };
    configFile = {
      baloofilerc = {
        General = {
          dbVersion = 2;
          "exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
          "exclude filters version" = 9;
        };
      };

      dolphinrc = {
        DetailsMode = {
          IconSize = 32;
          PreviewSize = 32;
        };
        General = {
          ViewPropsTimestamp = "2026,1,10,17,2,1.024";
        };
        IconsMode = {
          PreviewSize = 48;
        };
        "KFileDialog Settings" = {
          "Places Icons Auto-resize" = false;
          "Places Icons Static Size" = 22;
        };
      };

      kactivitymanagerdrc = {
        activities = {
          "6b8b2169-b3af-4129-9b28-e8cebcccef4c" = "Default";
        };
        main = {
          currentActivity = "6b8b2169-b3af-4129-9b28-e8cebcccef4c";
        };
      };

      kcminputrc = {
        "Libinput/Default" = {
          PointerAcceleration = "0";
          PointerAccelerationProfile = "flat";
        };
      };

      kded5rc = {
        Module-browserintegrationreminder = { autoload = false; };
        Module-device_automounter = { autoload = false; };
      };

      kdeglobals = {
        General = {
          UseSystemBell = true;
          # Removed hardcoded JetBrains Mono UI font; let programs.plasma.fonts control it
          # Optionally force 96 DPI so apps don’t upscale fonts
          forceFontDPI = 96;
          widgetStyle = "org.kde.breeze";
        };
        Icons = { Theme = "Win11-black-dark"; };
        KDE = {
          AnimationDurationFactor = 0.5;
          SingleClick = true;
        };
        "KFileDialog Settings" = {
          "Allow Expansion" = false;
          "Automatically select filename extension" = true;
          "Breadcrumb Navigation" = true;
          "Decoration position" = 2;
          "Show Full Path" = false;
          "Show Inline Previews" = true;
          "Show Preview" = false;
          "Show Speedbar" = true;
          "Show hidden files" = false;
          "Sort by" = "Name";
          "Sort directories first" = true;
          "Sort hidden files last" = false;
          "Sort reversed" = false;
          "Speedbar Width" = 165;
          "View Style" = "DetailTree";
        };
        WM = {
          activeBackground = "39,44,49";
          activeBlend = "252,252,252";
          activeForeground = "252,252,252";
          inactiveBackground = "32,36,40";
          inactiveBlend = "161,169,177";
          inactiveForeground = "161,169,177";
        };
      };

      krunnerrc = {
        General = { FreeFloating = true; };
        Plugins = {
          baloosearchEnabled = true;
          krunner_keysEnabled = true;
        };
        "Plugins/Favorites" = {
          plugins = "krunner_sessions,krunner_powerdevil,krunner_services,krunner_systemsettings,krunner_placesrunner";
        };
      };

      kscreenlockerrc = {
        Daemon = {
          LockOnResume = true;
          Timeout = 10;
        };
        "Greeter/Wallpaper/org.kde.potd/General" = { Provider = "bing"; };
        "Greeter/Wallpaper/org.kde.image/General" = {
          Image = wallpaper;
          PreviewImage = wallpaper;
        };
      };

      kwalletrc = { Wallet = { "First Use" = false; }; };

      kwinrc = {
        Desktops = {
          Number = 2;
          Rows = 1;
        };
        EdgeBarrier = {
          CornerBarrier = false;
          EdgeBarrier = 0;
        };
        "Effect-overview" = { BorderActivate = 0; };
        "Effect-zoom" = {
          PixelGridZoom = 12;
          ZoomFactor = 1.25;
        };
        Plugins = {
          poloniumEnabled = true;
          shakecursorEnabled = false;
        };
        Tiling = { padding = 4; };

        Windows = {
          ElectricBorderDelay = 125;
          Placement = "ZeroCornered";
        };
        Xwayland = { Scale = 1; };
        "org.kde.kdecoration2" = { ButtonsOnLeft = "SF"; };
      };

      kwinrulesrc = {
        "1" = {
          Description = "Dolphin";
          maximizehoriz = true;
          maximizehorizrule = 3;
          maximizevert = true;
          maximizevertrule = 3;
          # Allow titlebar and buttons for Dolphin
          noborder = false;
          noborderrule = 0;
          types = 1;
          wmclass = "dolphin";
          wmclasscomplete = true;
          wmclassmatch = 2;
        };
        General = {
          count = 1;
          rules = 1;
        };
      };

      kxkbrc = { Layout = { LayoutList = "dk"; Use = true; }; };

      plasma-localerc = { Formats = { LANG = "en_DK.UTF-8"; }; };

      plasmarc = {
        Theme = { name = "breeze-dark"; };
        Wallpapers = { usersWallpapers = wallpaper; };
      };

      spectaclerc = {
        ImageSave = { translatedScreenshotsFolder = "Screenshots"; };
        VideoSave = { translatedScreencastsFolder = "Screencasts"; };
      };
    };
    dataFile = {

    };
  };
}


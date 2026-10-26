{...}: {
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_queued_events" = 32768;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "65536";
    }
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "524288";
    }
  ];

  systemd.user.settings.Manager.DefaultLimitNOFILE = "65536:524288";
}

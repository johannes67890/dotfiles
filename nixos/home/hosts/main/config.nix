let configDir = ../../config;
in
{
  home.file = {
      ".config/kdee".source = "${configDir}/kde";
  };
}
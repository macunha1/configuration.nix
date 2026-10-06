{
  lib,
  ...
}:

with builtins;
with lib;
let
  pathIn = home: subpath: if subpath == "" then home else "${home}/${subpath}";

  shellHomes = {
    configHome = "$XDG_CONFIG_HOME";
    cacheHome = "$XDG_CACHE_HOME";
    dataHome = "$XDG_DATA_HOME";
    stateHome = "$XDG_STATE_HOME";
    binHome = "$XDG_BIN_HOME";
  };

  mkPathHelpers = homes: {
    inherit (homes)
      configHome
      cacheHome
      dataHome
      stateHome
      binHome
      ;

    config = pathIn homes.configHome;
    cache = pathIn homes.cacheHome;
    data = pathIn homes.dataHome;
    state = pathIn homes.stateHome;
    bin = pathIn homes.binHome;
  };
in
rec {
  dotFilesDir = toString ../.;
  configDir = "${dotFilesDir}/config";

  xdgPaths =
    {
      config,
      isDarwin ? false,
    }:
    let
      homeDirectory =
        if isDarwin then
          config.home.homeDirectory
        else
          attrByPath [
            "users"
            "users"
            config.user.name
            "home"
          ] "/home/${config.user.name}" config;

      concreteHomes =
        if isDarwin then
          {
            inherit (config.xdg)
              configHome
              cacheHome
              dataHome
              stateHome
              ;
            binHome = "${homeDirectory}/.local/bin";
          }
        else
          {
            configHome = "${homeDirectory}/.config";
            cacheHome = "${homeDirectory}/.cache";
            dataHome = "${homeDirectory}/.local/share";
            stateHome = "${homeDirectory}/.local/state";
            binHome = "${homeDirectory}/.local/bin";
          };
    in
    {
      shell = mkPathHelpers shellHomes;
      concrete = mkPathHelpers concreteHomes;
    };
}

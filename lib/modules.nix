{ lib, ... }:

let
  inherit (builtins)
    attrValues
    readDir
    pathExists
    concatLists
    ;
  inherit (lib)
    id
    mapAttrsToList
    filterAttrs
    hasPrefix
    hasSuffix
    nameValuePair
    removeSuffix
    optionalAttrs
    ;

  mapFilterAttrs =
    pred: f: attrs:
    filterAttrs pred (lib.mapAttrs' f attrs);
in
rec {
  mapModules =
    dir: fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n)) (
      n: v:
      let
        path = "${toString dir}/${n}";
      in
      if v == "directory" && pathExists "${path}/default.nix" then
        nameValuePair n (fn path)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n then
        nameValuePair (removeSuffix ".nix" n) (fn path)
      else
        nameValuePair "" null
    ) (readDir dir);

  mapModulesRec =
    dir: fn:
    mapFilterAttrs (n: v: v != null && !(hasPrefix "_" n)) (
      n: v:
      let
        path = "${toString dir}/${n}";
      in
      if v == "directory" then
        nameValuePair n (mapModulesRec path fn)
      else if v == "regular" && n != "default.nix" && hasSuffix ".nix" n then
        nameValuePair (removeSuffix ".nix" n) (fn path)
      else
        nameValuePair "" null
    ) (readDir dir);

  mapModulesRec' =
    dir: fn:
    let
      dirs = mapAttrsToList (k: _: "${dir}/${k}") (
        filterAttrs (n: v: v == "directory" && !(hasPrefix "_" n)) (readDir dir)
      );
      files = attrValues (mapModules dir id);
      paths = files ++ concatLists (map (d: mapModulesRec' d id) dirs);
    in
    map fn paths;

  platformPackages =
    {
      isDarwin,
      packages,
    }:
    optionalAttrs (!isDarwin) { user.packages = packages; }
    // optionalAttrs isDarwin { home.packages = packages; };

  platformEnv =
    {
      config,
      isDarwin,
      envVars,
      shellExports ? null,
      darwinTarget ? "session",
    }:
    optionalAttrs (!isDarwin) { env = envVars; }
    // optionalAttrs isDarwin (
      if darwinTarget == "zsh" then
        lib.mkIf config.modules.shell.zsh.enable {
          modules.shell.zsh.env =
            if shellExports == null then
              throw "platformEnv with darwinTarget = \"zsh\" requires shellExports"
            else
              shellExports envVars;
        }
      else if darwinTarget == "session" then
        {
          home.sessionVariables = envVars;
        }
      else if darwinTarget == "both" then
        {
          home.sessionVariables = envVars;
        }
        // lib.mkIf config.modules.shell.zsh.enable {
          modules.shell.zsh.env =
            if shellExports == null then
              throw "platformEnv with darwinTarget = \"both\" requires shellExports"
            else
              shellExports envVars;
        }
      else
        throw "Unsupported Darwin environment target: ${darwinTarget}"
    );

  platformPath =
    {
      config,
      isDarwin,
      paths,
      darwinTarget ? "session",
    }:
    let
      zshPathExports = lib.concatStringsSep "\n" (
        map (path: ''export PATH="${toString path}:$PATH"'') paths
      );
    in
    optionalAttrs (!isDarwin) { env.PATH = paths; }
    // optionalAttrs isDarwin (
      if darwinTarget == "zsh" then
        lib.mkIf config.modules.shell.zsh.enable {
          modules.shell.zsh.env = zshPathExports;
        }
      else if darwinTarget == "session" then
        {
          home.sessionPath = paths;
        }
      else if darwinTarget == "both" then
        {
          home.sessionPath = paths;
        }
        // lib.mkIf config.modules.shell.zsh.enable {
          modules.shell.zsh.env = zshPathExports;
        }
      else
        throw "Unsupported Darwin PATH target: ${darwinTarget}"
    );
}

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

  platformTargets = {
    session = {
      darwinSession = true;
      zsh = false;
    };
    zsh = {
      darwinSession = false;
      zsh = true;
    };
    both = {
      darwinSession = true;
      zsh = true;
    };
  };

  resolvePlatformTarget =
    target: platformTargets.${target} or (throw "Unsupported platform target: ${target}");
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
      target ? "session",
    }:
    let
      resolvedTarget = resolvePlatformTarget target;
    in
    lib.mkMerge [
      (optionalAttrs (!isDarwin) { env = envVars; })

      (optionalAttrs (isDarwin && resolvedTarget.darwinSession) {
        home.sessionVariables = envVars;
      })

      (lib.mkIf (resolvedTarget.zsh && config.modules.shell.zsh.enable) {
        modules.shell.zsh.env =
          if shellExports == null then
            throw "platformEnv with a ZSH target requires shellExports"
          else
            shellExports envVars;
      })
    ];

  platformPath =
    {
      config,
      isDarwin,
      paths,
      target ? "session",
    }:
    let
      zshPathExports = lib.concatStringsSep "\n" (
        map (path: ''export PATH="${toString path}:$PATH"'') paths
      );
      resolvedTarget = resolvePlatformTarget target;
    in
    lib.mkMerge [
      (optionalAttrs (!isDarwin) { env.PATH = paths; })

      (optionalAttrs (isDarwin && resolvedTarget.darwinSession) {
        home.sessionPath = paths;
      })

      (lib.mkIf (resolvedTarget.zsh && config.modules.shell.zsh.enable) {
        modules.shell.zsh.env = zshPathExports;
      })
    ];
}

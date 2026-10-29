# modules/browser/firefox.nix -- https://www.firefox.org/
#

{
  config,
  lib,
  ...
}:
with lib;
let
  inherit (lib.my or (import ../../../lib/modules/browser/search-engines.nix { inherit lib; }))
    browserSearchEngines
    ;

  searchEngine = browserSearchEngines.${config.modules.desktop.browsers.firefox.config.searchEngine};

  # Firefox rejects custom engines whose names match its built-in engines.
  firefoxSearchEngineName = "${config.modules.desktop.browsers.firefox.config.searchEngine} (Nix)";
in
{
  options.modules.desktop.browsers.firefox = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    config.searchEngine = mkOption {
      type = types.enum (attrNames browserSearchEngines);
      default = "DuckDuckGo";
      description = "Default search engine for Firefox.";
    };
  };

  config = mkIf config.modules.desktop.browsers.firefox.enable {
    programs.firefox = {
      enable = true;
      policies.SearchEngines = {
        Default = firefoxSearchEngineName;
        Add = [
          {
            Name = firefoxSearchEngineName;
            Alias = searchEngine.keyword;
            URLTemplate = searchEngine.searchURL;
          }
        ];
      };
    };
  };
}

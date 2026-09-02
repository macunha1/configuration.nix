# modules/browser/chromium.nix -- https://www.chromium.org/
#
# Open-source project that Google acquired to create Google Chrome, although it
# requires as much RAM as the commercial version Chromium provides a fast engine
# and GPU processing capabilities which are IMHO big selling points in
# comparison to Firefox.

{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.modules.desktop.browsers.chromium = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.browsers.chromium.enable {
    fonts.packages = [ pkgs.source-code-pro ];

    programs.chromium = {
      enable = true;
      extraOpts = {
        DefaultZoomFactor = 1.25;
        DefaultFontSize = 20;
        DefaultFixedFontSize = 16;
        PasswordManagerEnabled = false;

        # Disable Chromium AI features for a Google-free setup. Individual
        # features can be enabled on demand if desired.
        AIModeSettings = 1;
        AutofillPredictionSettings = 2;
        AutomatedPasswordChangeSettings = 2;
        BuiltInAIAPIsEnabled = false;
        ChromeSuggestionsSettings = 1;
        CreateThemesSettings = 2;
        DevToolsGenAiSettings = 2;
        GeminiActOnWebSettings = 1;
        GeminiSettings = 1;
        GeminiSparkSettings = 1;
        GenAILocalFoundationalModelSettings = 1;
        HelpMeWriteSettings = 2;
        HistorySearchSettings = 2;
        SearchContentSharingSettings = 1;
        SmartTabSharingSettings = 1;
        TabCompareSettings = 2;
        ThirdPartyAiChatSettings = 1;
        TranslatorAPIAllowed = false;
        VoiceTypingSettings = 2;
      };
      initialPrefs = {
        webkit.webprefs = {
          standard_font_family = "Source Code Pro";
          sans_serif_font_family = "Source Code Pro";
          serif_font_family = "Source Code Pro";
          fixed_font_family = "Source Code Pro";
          default_font_size = 20;
          default_fixed_font_size = 16;
        };
      };
    };

    user.packages = with pkgs; [ chromium ];

    home-manager.users.${config.user.name}.programs.chromium = {
      enable = true;
      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "kioklelcojgbjoljlilalgdcppkiioge" # Void Theme
      ];
    };
  };
}

# modules/browser/chromium.nix -- https://www.chromium.org/
#
# Open-source project that Google acquired to create Google Chrome, although it
# requires as much RAM as the commercial version Chromium provides a fast engine
# and GPU processing capabilities which are IMHO big selling points in
# comparison to Firefox.

{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (lib.my or (import ../../../lib/modules/browser/search-engines.nix { inherit lib; }))
    browserSearchEngines
    ;

  searchEngine = browserSearchEngines.${config.modules.desktop.browsers.chromium.config.searchEngine};

  chromiumPackage = pkgs.chromium.override {
    # Stop federated sign-in prompts, Google Autofill crowdsourcing and remote
    # optimization hints in both desktop and command-line launches.
    commandLineArgs = "--disable-features=FedCm,AutofillServerCommunication,OptimizationHints";
  };
in
{
  options.modules.desktop.browsers.chromium = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    config.searchEngine = mkOption {
      type = types.enum (attrNames browserSearchEngines);
      default = "DuckDuckGo";
      description = "Default search engine for Chromium.";
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

        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = config.modules.desktop.browsers.chromium.config.searchEngine;
        DefaultSearchProviderKeyword = searchEngine.keyword;
        DefaultSearchProviderSearchURL = searchEngine.searchURL;

        # Block saving/filling every Autofill category on every site. Keep the
        # legacy switches for paths that still consult the global preferences.
        PasswordManagerEnabled = false;
        PasswordManagerPasskeysEnabled = false;
        PasswordLeakDetectionEnabled = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        AutofillSettings = [
          {
            url_pattern = "*";
            blocked_types = [ "all" ];
          }
        ];
        PaymentMethodQueryEnabled = false;
        BrowserSignin = 0;
        SyncDisabled = true;

        # Keep typed text, page contents and diagnostics out of Google services.
        MetricsReportingEnabled = false;
        UrlKeyedAnonymizedDataCollectionEnabled = false;
        UserFeedbackAllowed = false;
        FeedbackSurveysEnabled = false;
        WebRtcEventLogCollectionAllowed = false;
        SearchSuggestEnabled = false;
        SpellCheckServiceEnabled = false;
        TranslateEnabled = false;
        AlternateErrorPagesEnabled = false;
        NetworkPredictionOptions = 2;
        BrowserNetworkTimeQueriesEnabled = false;
        DnsOverHttpsMode = "off"; # Use the host's configured resolver.
        DefaultGeolocationSetting = 2;

        # Disable Google search/shopping surfaces, Cast and background activity.
        GoogleSearchSidePanelEnabled = false;
        ShoppingListEnabled = false;
        NTPCardsVisible = false;
        PromotionsEnabled = false;
        EnableMediaRouter = false;
        BackgroundModeEnabled = false;

        # Keep standard phishing/malware protection, without enhanced protection,
        # real-time lookups or uploading suspicious downloads to Google.
        SafeBrowsingProtectionLevel = 1;
        SafeBrowsingProxiedRealTimeChecksAllowed = false;
        SafeBrowsingDeepScanningEnabled = false;
        SafeBrowsingSurveysEnabled = false;

        # Disable AI features individually: GenAiDefaultSettings is cloud-only
        # and is ignored when supplied through local Linux policy files.
        AIModeSettings = 1;
        AutofillGenAiSettings = 2;
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

    user.packages = [ chromiumPackage ];

    home-manager.users.${config.user.name}.programs.chromium = {
      enable = true;
      package = chromiumPackage;
      extensions = [
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
        "kioklelcojgbjoljlilalgdcppkiioge" # Void Theme
      ];
    };
  };
}

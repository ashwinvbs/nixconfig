{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.programs.chromium.enable {
    # TODO: emit unmaintained warning
    environment.systemPackages = with pkgs;
      [
        # programs.chromium.enable = true only enables policy o.0 :| ???
        google-chrome
      ];
    nixpkgs.config = lib.mkDefault {
      allowUnfree = true;
    };

    programs.chromium.extraOpts = {
      # TODO: Default Search Provider

      # Extensions
      "ExtensionInstallBlocklist" = [ "*" ];
      "ExtensionInstallForcelist" = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "apjcbfpjihpedihablmalmbbhjpklbdf" # AdGuard AdBlocker
      ];

      # TODO: Generative AI

      # Google Cast
      "EnableMediaRouter" = false;

      # TODO: Legacy Browser Support - use for freetube

      # Miscellaneous
      "AdvancedProtectionAllowed" = false;
      "AllowDinosaurEasterEgg" = false;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "BackgroundModeEnabled" = true;
      "BlockThirdPartyCookies" = true;
      "BrowserLabsEnabled" = false;
      "BrowserNetworkTimeQueriesEnabled" = false;
      "GoogleSearchSidePanelEnabled" = false;
      "HideWebStoreIcon" = true;
      "IntensiveWakeUpThrottlingEnabled" = true;
      "MetricsReportingEnabled" = false;
      "PaymentMethodQueryEnabled" = false;
      "ProfilePickerOnStartupAvailability" = 1;
      "PromotionsEnabled" = false;
      "RemoteDebuggingAllowed" = false;
      "SharedClipboardEnabled" = false;
      "ShoppingListEnabled" = false;
      "ShowAppsShortcutInBookmarkBar" = false;
      "ShowFullUrlsInAddressBar" = true;
      "SpellCheckServiceEnabled" = false;
      "UrlKeyedAnonymizedDataCollectionEnabled" = false;

      # Password manager
      "PasswordManagerEnabled" = false;

      # Printing
      "CloudPrintProxyEnabled" = false;

      # Privacy Sandbox policies
      "PrivacySandboxAdMeasurementEnabled" = false;
      "PrivacySandboxAdTopicsEnabled" = false;
      "PrivacySandboxPromptEnabled" = false;
      "PrivacySandboxSiteEnabledAdsEnabled" = false;

      # Related Website Sets
      "RelatedWebsiteSetsEnabled" = false;

      # Remote access
      "RemoteAccessHostAllowRemoteAccessConnections" = false;
      "RemoteAccessHostAllowRemoteSupportConnections" = false;

      # Safe Browsing
      "SafeBrowsingDeepScanningEnabled" = false;
      "SafeBrowsingExtendedReportingEnabled" = false;
      "SafeBrowsingProtectionLevel" = 1;
      "SafeBrowsingSurveysEnabled" = false;

      # Startup, Home page and New Tab page
      "HomepageIsNewTabPage" = true;
      "ShowHomeButton" = false;
    };
  };
}

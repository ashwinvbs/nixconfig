{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium
  ];
  nixpkgs.config = {
    allowUnfree = true;
    chromium.enableWideVine = true;
  }
  programs.chromium = {
    enable = true;
    extraOpts = {
      ## Extensions
      "ExtensionInstallForcelist" = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "apjcbfpjihpedihablmalmbbhjpklbdf" # AdGuard AdBlocker
      ];

      ## Miscellaneous
      "AdvancedProtectionAllowed" = false;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "BrowserSignin" = 0;
      # Need to see if this can be changed to user specific directory.
      "DiskCacheDir" = "/tmp/browsercache";
      "HideWebStoreIcon" = true;
      "MetricsReportingEnabled" = false;
      "PaymentMethodQueryEnabled" = false;
      "ProfilePickerOnStartupAvailability" = 1;
      "RemoteDebuggingAllowed" = false;
      # TODO: Enable RoamingProfileSupport rather than using yadm for bookrmarks
      "SharedClipboardEnabled" = false;
      "ShowAppsShortcutInBookmarkBar" = false;
      "SpellCheckServiceEnabled" = false;
      # TODO: Remove this when RoamingProfileSupport is enabled
      "SyncDisabled" = true;

      ## Password manager
      "PasswordManagerEnabled" = false;

      ## Printing
      "CloudPrintProxyEnabled" = false;

      ## Remote access
      "RemoteAccessHostAllowRemoteAccessConnections" = false;
      "RemoteAccessHostAllowRemoteSupportConnections" = false;

      ## Startup, Home page and New Tab page
      "ShowHomeButton" = false;
    };
  };
}

{ config, lib, pkgs, ... }:

{
  config.programs.firefox = {
    languagePacks = [ "en-US" ];
    policies = {
      "DisableFirefoxStudies" = true;
      "DisablePocket" = true;
      "DisableTelemetry" = true;
      "DNSOverHTTPS" = {
        "Enabled" = false;
        "Locked" = true;
      };
      "EncryptedMediaExtensions" = { "Enabled" = true; };
      "ExtensionSettings" = {
        "*" = {
          "blocked_install_message" =
            "Extension installation blocked, contact administrator!";
          "installation_mode" = "blocked";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          "installation_mode" = "force_installed";
          "install_url" =
            "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          "installation_mode" = "force_installed";
          "install_url" =
            "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
      "FirefoxHome" = {
        "Pocket" = false;
        "SponsoredPocket" = false;
        "SponsoredTopSites" = false;
      };
      "FirefoxSuggest" = {
        "WebSuggestions" = false;
        "SponsoredSuggestions" = false;
        "ImproveSuggest" = false;
      };
      "OfferToSaveLogins" = false;
      "UserMessaging" = {
        "ExtensionRecommendations" = false;
        "FeatureRecommendations" = false;
      };
    };
    preferences = { "browser.cache.disk.enable" = false; };
  };
}

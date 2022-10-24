{ config, pkgs, ... }:

{
  # Replace the default browser with ungoogled-chromium.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    ungoogled-chromium
  ];
  nixpkgs.config.chromium.enableWideVine = true;
  programs.chromium = {
    extraOpts = {
      "BrowserSignin" = 0;
      "PasswordManagerEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "AutofillAddressEnabled" = false;
    };
    # TODO: Add extensions here.
  };
}

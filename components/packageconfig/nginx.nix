{ config, ... }:
{
  config.services.nginx = {
    # Enable recommended security settings
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
  };
}

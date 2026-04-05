{ ... }:

{
  services.blocky = {
    settings = {
      ports.dns = 53; # Ensure Blocky is on the standard port

      # Use dns over https by default.
      upstreams.groups.default = [
        "https://1.1.1.1/dns-query"
        "https://1.0.0.1/dns-query"
      ];
      # Bootstrap using dns over tls
      bootstrapDns = [
        "tcp-tls:1.1.1.1:853"
        "tcp-tls:1.0.0.1:853"
      ];
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    # This probably needs a corresponding impermanence configuration
    (lib.mkIf config.services.printing.enable {
      services.printing.drivers = [ pkgs.hplipWithPlugin ];
    })

    (lib.mkIf config.hardware.sane.enable {
      hardware.sane.brscan5.enable = true;
    })
  ];
}

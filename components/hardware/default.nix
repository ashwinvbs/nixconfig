{
  config,
  ...
}:

{
  imports = [
    ./amdgpu.nix
    ./eficonfig.nix
    ./intelgpu.nix
    ./print_and_scan.nix
    ./rpi4.nix
  ];

  config = {
    services = {
      # Firmware management service
      fwupd.enable = true;

      # SSD management service
      fstrim.enable = true;
    };

    swapDevices = [
      {
        device = "/dev/disk/by-partlabel/swap";
        randomEncryption.enable = true;
      }
    ];
  };
}

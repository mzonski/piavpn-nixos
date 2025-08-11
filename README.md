# piavpn-nixos

A NixOS flake to install Private Internet Access VPN GUI Client

## ⚠️ Important Notice

**Currently only WireGuard protocol is supported.** OpenVPN support is not yet implemented, but contributions to add OpenVPN support are very much appreciated! 🙏

## Usage

### Using the NixOS module

Import the module in your NixOS configuration:

```nix
{
  imports = [
    inputs.piavpn.nixosModules.piavpn
  ];

  # Enable PIA VPN service
  services.piavpn.enable = true;

  # Required for VPN functionality
  networking.networkmanager.enable = true;
  
  # Add your user to the required groups
  users.users.your-username.extraGroups = [ "piavpn" "piahnsd" ];
}
```

### Complete example configuration

```nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    piavpn = {
      url = "github:mzonski/piavpn-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, piavpn }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        piavpn.nixosModules.piavpn
        {
          services.piavpn.enable = true;
          networking.networkmanager.enable = true;
          users.users.your-username.extraGroups = [ "piavpn" "piahnsd" ];
        }
      ];
    };
  };
}
```

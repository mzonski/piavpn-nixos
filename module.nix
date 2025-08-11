{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption mkIf types;
  inherit (import ./utils.nix) callPiaWithDeps;
  cfg = config.services.pia;
  pkg = cfg.package;
in
{
  options.services.pia = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the Private Internet Access VPN service.";
    };
    package = mkOption {
      type = types.package;
      default = callPiaWithDeps pkgs;
      description = "Set PIA package to be used";
    };
  };

  config = mkIf cfg.enable ({
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "services.pia requires networking.networkmanager to be enabled";
      }
    ];

    environment.systemPackages = [
      pkg
    ];

    systemd.services.piavpn = {
      description = "Private Internet Access VPN Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkg.piaOptDir}/bin/pia-daemon-wrapped";
        Restart = "on-failure";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${pkg.piaOptDir} 0755 root root -"
      "d ${pkg.piaOptDir}/etc 0755 root ${pkg.groupName} -"
      "d ${pkg.piaOptDir}/etc/cgroup 0755 root ${pkg.groupName} -"
      "d ${pkg.piaOptDir}/var 0755 root ${pkg.groupName} -"
      "d ${pkg.piaOptDir}/var/crashes 0755 root ${pkg.groupName} -"
      "L+ ${pkg.piaOptDir}/bin - - - - ${pkg + pkg.piaOptDir}/bin"
      "L+ ${pkg.piaOptDir}/lib - - - - ${pkg + pkg.piaOptDir}/lib"
      "L+ ${pkg.piaOptDir}/plugins - - - - ${pkg + pkg.piaOptDir}/plugins"
      "L+ ${pkg.piaOptDir}/qml - - - - ${pkg + pkg.piaOptDir}/qml"
      "L+ ${pkg.piaOptDir}/share - - - - ${pkg + pkg.piaOptDir}/share"
      "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
    ];

    networking = {
      wireguard.enable = true;
      networkmanager = {
        enable = true;
        unmanaged = [ "interface-name:wgpia*" ];
      };
      nftables.enable = true;
    };

    users.groups = {
      piavpn = { };
      piahnsd = { };
    };

    environment.etc."apport/blacklist.d/piavpn".text = ''
      /opt/piavpn/bin/pia-client
      /opt/piavpn/bin/pia-daemon
    '';

    security.wrappers = {
      "pia-unbound" = {
        source = "${pkg}/opt/piavpn/bin/pia-unbound";
        capabilities = "cap_net_bind_service+ep";
        owner = "root";
        group = "root";
      };
    };
  });
}

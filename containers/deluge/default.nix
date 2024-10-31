{
  config,
  vars,
  lib,
  ...
}:
let
  cfg = config.services.delugevpn;
  directories = [
    cfg.mounts.downloads.complete
    cfg.mounts.downloads.incomplete
    cfg.mounts.config
  ];
in
{
  options.services.delugevpn = {
    enable = lib.mkEnableOption "Deluge torrent client (with optional Gluetun sidecar)";
    gluetun.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable Gluetun (killswitch VPN gateway)";
    };
    gluetun.wireguardCredentialsFile = lib.mkOption {
      default = true;
      type = lib.types.path;
      description = "Path to a file with Wireguard credentials";
      example = lib.literalExpression ''
        pkgs.writeText "wireguard-credentials.txt" '''
          WIREGUARD_PRIVATE_KEY="S2LcRErkNuP-nmpsvNNKx5ZDQ-uYvTfNGD4isRA6g1s="
          WIREGUARD_PUBLIC_KEY="Bwsx9VtrmLysyy9Au0xpbeNjYsHBCocBGc5uqydqK0w="
          WIREGUARD_ADDRESSES="172.18.91.3/32"
          VPN_ENDPOINT_IP="142.250.185.238"
          VPN_ENDPOINT_PORT="51820"
        '''
      '';
    };
    mounts.config = lib.mkOption {
      default = "/var/opt/deluge";
      type = lib.types.path;
      description = ''
        Path to Deluge configs
      '';
    };
    mounts.downloads.complete = lib.mkOption {
      default = lib.types.null;
      type = lib.types.path;
      description = ''
        Path to the completed downloads
      '';
    };
    mounts.downloads.incomplete = lib.mkOption {
      default = lib.types.null;
      type = lib.types.path;
      description = ''
        Path to the incomplete downloads
      '';
    };
    user = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        User to run the Deluge and Gluetun containers as
      '';
      apply = old: builtins.toString config.users.users."${old}".uid;
    };
    group = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        User to run the Deluge and Gluetun containers as
      '';
      apply = old: builtins.toString config.users.groups."${old}".gid;
    };
    timeZone = lib.mkOption {
      default = "Europe/Berlin";
      type = lib.types.str;
      description = ''
        Time zone to be used inside the Deluge and Gluetun containers
      '';
    };
    baseDomainName = lib.mkOption {
      default = null;
      type = lib.types.str;
      description = ''
        Base domain name to be used for Traefik reverse proxy (e.g. deluge.baseDomainName)
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = map (x: "d ${x} 0775 ${cfg.user} ${cfg.group} - -") directories;
    virtualisation.oci-containers = {
      containers = {
        deluge = {
          image = "linuxserver/deluge:latest";
          autoStart = true;
          dependsOn = lib.lists.optionals (cfg.gluetun.enable) [ "gluetun" ];
          extraOptions =
            [
              "--pull=newer"
              "-l=homepage.group=Arr"
              "-l=homepage.name=Deluge"
              "-l=homepage.icon=deluge.svg"
              "-l=homepage.href=https://deluge.${vars.domainName}"
              "-l=homepage.description=Torrent client"
              "-l=homepage.widget.type=deluge"
              "-l=homepage.widget.password=''"
              ''-l=homepage.widget.url=http://${if cfg.gluetun.enable then "gluetun" else "deluge"}:8112''
            ]
            ++ lib.lists.optional (cfg.gluetun.enable) "--network=container:gluetun"
            ++ lib.lists.optionals (!cfg.gluetun.enable) [
              "-l=traefik.enable=true"
              "-l=traefik.http.routers.deluge.rule=Host(`deluge.${cfg.baseDomainName}`)"
              "-l=traefik.http.routers.deluge.service=deluge"
              "-l=traefik.http.services.deluge.loadbalancer.server.port=8112"
            ];
          volumes = [
            "${cfg.mounts.downloads.complete}:/data/completed"
            "${cfg.mounts.downloads.incomplete}:/data/incomplete"
            "${cfg.mounts.config}:/config"
          ];
          environment = {
            TZ = cfg.timeZone;
            PUID = cfg.user;
            GUID = cfg.group;
          };
        };
        gluetun = lib.mkIf cfg.gluetun.enable {
          image = "qmcgaw/gluetun:latest";
          autoStart = true;
          extraOptions = [
            "--pull=newer"
            "--cap-add=NET_ADMIN"
            "-l=traefik.enable=true"
            "-l=traefik.http.routers.deluge.rule=Host(`deluge.${cfg.baseDomainName}`)"
            "-l=traefik.http.routers.deluge.service=deluge"
            "-l=traefik.http.services.deluge.loadbalancer.server.port=8112"
            "--device=/dev/net/tun:/dev/net/tun"
            "-l=homepage.group=Arr"
            "-l=homepage.name=Gluetun"
            "-l=homepage.icon=gluetun.svg"
            "-l=homepage.href=https://deluge.${cfg.baseDomainName}"
            "-l=homepage.description=VPN killswitch"
            "-l=homepage.widget.type=gluetun"
            "-l=homepage.widget.url=http://gluetun:8000"
          ];
          #ports = [ "127.0.0.1:8083:8000" ];
          environmentFiles = [ cfg.gluetun.wireguardCredentialsFile ];
          environment = {
            VPN_TYPE = "wireguard";
            VPN_SERVICE_PROVIDER = "custom";
          };
        };
      };
    };
  };
}

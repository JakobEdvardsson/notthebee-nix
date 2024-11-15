{
  config,
  vars,
  lib,
  ...
}:
let
  cfg = config.homelab.services.calibre-web;
  directories = [
    cfg.mounts.library
    cfg.mounts.config
    cfg.calibre-web.mounts.config
  ];
in
{
  options.homelab.services.calibre = {
    enable = lib.mkEnableOption "Self-hosted book server";
    calibre-web.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enable Calibre-Web";
    };
    calibre-web.mounts.config = lib.mkOption {
      default = "${config.homelab.mounts.config}/calibre-web";
      type = lib.types.path;
      description = ''
        Path to Calibre-web configs
      '';
    };
    mounts.config = lib.mkOption {
      default = "${config.homelab.mounts.config}/calibre";
      type = lib.types.path;
      description = ''
        Path to Calibre configs
      '';
    };
    mounts.library = lib.mkOption {
      default = "${config.homelab.mounts.fast}/Media/Calibre";
      type = lib.types.path;
      description = ''
        Path to the Calibre library
      '';
    };

    user = lib.mkOption {
      default = config.homelab.user;
      type = lib.types.str;
      description = ''
        User to run Calibre and Calibre-Web as
      '';
    };
    group = lib.mkOption {
      default = config.homelab.group;
      type = lib.types.str;
      description = ''
        User to run Calibre and Calibre-Web as
      '';
    };
    timeZone = lib.mkOption {
      default = config.homelab.timeZone;
      type = lib.types.str;
      description = ''
        Time zone to be used inside the Calibre and Calibre-Web containers
      '';
    };
    baseDomainName = lib.mkOption {
      default = config.homelab.baseDomainName;
      type = lib.types.str;
      description = ''
        Base domain name to be used for Traefik reverse proxy (e.g. calibre.baseDomainName)
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = map (x: "d ${x} 0775 ${cfg.user} ${cfg.group} - -") directories;
    virtualisation.oci-containers = {
      containers = {
        calibre = {
          image = "lscr.io/linuxserver/calibre:latest";
          autoStart = true;
          extraOptions = [
            "--pull=newer"
            "-l=homepage.group=Media"
            "-l=homepage.name=Calibre"
            "-l=homepage.icon=calibre.svg"
            "-l=homepage.href=https://calibreserver.${vars.domainName}"
            "-l=homepage.description=eBook server"
            "-l=traefik.enable=true"
            "-l=traefik.http.routers.calibre.rule=Host(`calibreserver.${cfg.baseDomainName}`)"
            "-l=traefik.http.routers.calibre.service=calibre"
            "-l=traefik.http.services.calibre.loadbalancer.server.port=8080"
          ];
          volumes = [
            "${cfg.mounts.config}:/config"
            "${cfg.mounts.library}:/library"
          ];
          environment = {
            TZ = cfg.timeZone;
            PUID = cfg.user;
            GUID = cfg.group;
          };
        };

        calibre-web = {
          image = "lscr.io/linuxserver/calibre-web:latest";
          autoStart = true;
          extraOptions = [
            "--pull=newer"
            "-l=homepage.group=Media"
            "-l=homepage.name=Calibre-Web"
            "-l=homepage.icon=calibre-web.svg"
            "-l=homepage.href=https://calibre.${vars.domainName}"
            "-l=homepage.description=eBook management frontend"
            "-l=traefik.enable=true"
            "-l=traefik.http.routers.calibre-web.rule=Host(`calibre.${cfg.baseDomainName}`)"
            "-l=traefik.http.routers.calibre-web.service=calibre-web"
            "-l=traefik.http.services.calibre-web.loadbalancer.server.port=8083"
          ];
          volumes = [
            "${cfg.calibre-web.mounts.config}:/config"
            "${cfg.mounts.library}:/library"
          ];
          environment = {
            TZ = cfg.timeZone;
            PUID = cfg.user;
            GUID = cfg.group;
          };
        };
      };
    };
  };
}

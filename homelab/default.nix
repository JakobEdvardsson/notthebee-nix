{ lib, config, ... }:
{
  options.homelab = {
    enable = lib.mkEnableOption "The homelab services and configuration variables";
    mounts.slow = lib.mkOption {
      default = "/mnt/mergerfs_slow";
      type = lib.types.path;
      description = ''
        Path to the 'slow' tier mount
      '';
    };
    mounts.fast = lib.mkOption {
      default = "/mnt/cache";
      type = lib.types.path;
      description = ''
        Path to the 'fast' tier mount
      '';
    };
    mounts.config = lib.mkOption {
      default = "/persist/opt/services";
      type = lib.types.path;
      description = ''
        Path to the service configuration files
      '';
    };
    mounts.merged = lib.mkOption {
      default = "/mnt/user";
      type = lib.types.path;
      description = ''
        Path to the merged tier mount
      '';
    };
    user = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        User to run the homelab services as
      '';
      apply = old: builtins.toString config.users.users."${old}".uid;
    };
    group = lib.mkOption {
      default = "share";
      type = lib.types.str;
      description = ''
        Group to run the homelab services as
      '';
      apply = old: builtins.toString config.users.groups."${old}".gid;
    };
    timeZone = lib.mkOption {
      default = "Europe/Berlin";
      type = lib.types.str;
      description = ''
        Time zone to be used for the homelab services
      '';
    };
    baseDomainName = lib.mkOption {
      default = "";
      type = lib.types.str;
      description = ''
        Base domain name to be used to access the homelab services via Traefik reverse proxy
      '';
    };
  };
  imports = [
    ./arr
    ./audiobookshelf
    ./calibre-web
    ./deluge
    ./traefik
    ./jellyfin
    ./paperless-ngx
    ./homepage
    ./networks
  ];
}

{ inputs, config, ... }:
{
  homelab = {
    enable = true;
    baseDomainName = "goose.party";
    timeZone = "Europe/Berlin";
    mounts = {
      config = "/persist/opt/services";
      slow = "/mnt/mergerfs_slow";
      fast = "/mnt/cache";
      merged = "/mnt/user";
    };
    services = {
      arr = {
        enable = true;
        recyclarr = {
          configPath = inputs.recyclarr-configs;
        };
        sonarr = {
          apiKeyFile = config.age.secrets.sonarrApiKey.path;
        };
        radarr = {
          apiKeyFile = config.age.secrets.radarrApiKey.path;
        };
      };
      delugevpn = {
        enable = true;
        gluetun = {
          enable = true;
          wireguardCredentialsFile = config.age.secrets.wireguardCredentials.path;
        };
      };
    };
  };
}

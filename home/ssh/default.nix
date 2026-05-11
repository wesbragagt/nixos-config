{ config, ... }:
{
  sops.secrets."github/ssh_key_pub" = {
    path = "${config.home.homeDirectory}/.ssh/github_key.pub";
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        # Public key stub used to select the matching Bitwarden-managed agent key.
        identityFile = config.sops.secrets."github/ssh_key_pub".path;
        identityAgent = "~/.bitwarden-ssh-agent.sock";
        identitiesOnly = true;
      };
    };
  };
}

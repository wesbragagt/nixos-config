{ ... }:
{
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };

  home.file.".ssh/github_key.pub" = {
    source = ./github_key.pub;
    force = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        # Public key stub used to select the matching Bitwarden-managed agent key.
        identityFile = "~/.ssh/github_key.pub";
        identityAgent = "~/.bitwarden-ssh-agent.sock";
        identitiesOnly = true;
      };
    };
  };
}

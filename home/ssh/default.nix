{ ... }:
{
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

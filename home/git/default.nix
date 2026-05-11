{ config, ... }:
{
  sops.secrets."github/ssh_sign_key_pub" = {
    path = "${config.home.homeDirectory}/.ssh/github_sign_key.pub";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "wesbragagt";
        email = "40429790+wesbragagt@users.noreply.github.com";
        signingKey = config.sops.secrets."github/ssh_sign_key_pub".path;
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.lazygit = {
    enable = true;
    settings.git.pagers = [
      { pager = "delta --dark --paging=never --line-numbers"; }
    ];
  };
}

{ ... }:
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "wesbragagt";
      email = "40429790+wesbragagt@users.noreply.github.com";
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

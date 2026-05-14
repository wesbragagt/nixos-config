{ pkgs, ... }:
let
  gitSshSign = pkgs.writeShellScriptBin "git-ssh-sign" ''
    export SSH_AUTH_SOCK="''${SSH_AUTH_SOCK:-$HOME/.bitwarden-ssh-agent.sock}"
    exec ${pkgs.openssh}/bin/ssh-keygen "$@"
  '';
in
{
  home.file.".ssh/github_sign_key.pub".source = ../ssh/github_sign_key.pub;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "wesbragagt";
        email = "40429790+wesbragagt@users.noreply.github.com";
        signingKey = "~/.ssh/github_sign_key.pub";
      };
      gpg.format = "ssh";
      gpg.ssh.program = "${gitSshSign}/bin/git-ssh-sign";
      commit.gpgsign = true;
      tag.gpgsign = true;
      # configure to use --rebase by default
      pull.rebase = true;
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

{ inputs, ... }:
{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    theme.flavor.dark = "kanagawa";
    flavors.kanagawa = inputs.kanagawa-yazi;
  };
}

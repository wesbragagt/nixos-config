{ ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "wesbragagt";
      };
      initial_session = {
        command = "Hyprland";
        user = "wesbragagt";
      };
    };
  };
}

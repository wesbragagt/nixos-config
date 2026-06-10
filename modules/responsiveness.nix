{ lib, pkgs, ... }:

{
  # The current icebox workload is memory-pressure bound, not just CPU-bound:
  # journalctl shows global kernel OOM events after zram swap reached 0 free.
  # Make userspace kill runaway desktop/dev processes before the kernel has to.
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
    settings.OOM = {
      DefaultMemoryPressureLimit = "60%";
      DefaultMemoryPressureDurationSec = "20s";
    };
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 10;
    freeMemKillThreshold = 5;
    freeSwapThreshold = 20;
    freeSwapKillThreshold = 10;
    enableNotifications = true;
    reportInterval = 60;
    extraArgs = [
      "--prefer"
      "(^|/)(chrome|chromium|slack|Roam|claude\\.exe|node|bun|java)$"
      "--avoid"
      "(^|/)(Hyprland|waybar|systemd|sshd|tmux|zsh)$"
    ];
  };

  # Keep CPU/IO-heavy background work from starving the compositor and shell.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-cpp;
    settings = {
      apply_cgroup = false;
      cgroup_load = false;
      cgroup_realtime_workaround = lib.mkForce false;
    };
  };

  # zram is still the right swap backend for this desktop: it avoids disk-swap
  # thrashing, but earlyoom above now reacts before this compressed swap fills.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    # Prefer reclaiming cache over entering deep swap pressure; with zram only,
    # going all the way to full swap produced the observed freezes/OOM storms.
    "vm.swappiness" = 30;
    "vm.vfs_cache_pressure" = 50;
  };

  # /tmp on tmpfs is useful, but 50% of 64 GiB lets temp files consume too much
  # RAM during data/dev workloads. Cap it lower so pressure control has headroom.
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  # Nix builds should yield to interactive desktop work when the machine is hot.
  systemd.services.nix-daemon.serviceConfig = {
    CPUWeight = 50;
    IOWeight = 50;
    Nice = 5;
  };
}

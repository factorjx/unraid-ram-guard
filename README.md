# RAM Guard — Unraid plugin

Monitors RAM usage. When usage stays above the stop threshold, RAM Guard stops the Docker container that uses the most memory:

| RAM usage | What happens |
|---|---|
| ≥ 90% (warning threshold) | Unraid notification listing the largest containers |
| ≥ 95% for more than 15 s (stop threshold) | `docker stop` on the largest container, plus a notification |
| still ≥ 95% after 120 s | the next largest container is stopped |

All thresholds and intervals can be changed in the settings.

## Installation

1. In Unraid, go to **Plugins → Install Plugin** and paste this URL:

   ```
   https://raw.githubusercontent.com/factorjx/unraid-ram-guard/main/ram.guard.plg
   ```

   Click **Install**. The same over SSH:
   `plugin install https://raw.githubusercontent.com/factorjx/unraid-ram-guard/main/ram.guard.plg`
2. Settings: **Settings → User Utilities → RAM Guard**.

The plugin is saved to `/boot/config/plugins/` and starts on every boot. New versions show up on the **Plugins** tab after **Check for Updates**.

Offline install: download `ram.guard.plg`, copy it to the flash drive (for example `/boot/ram.guard.plg`), and enter that path instead of the URL.

> The settings page, notifications and log are currently in Russian.

## Checking that it works

The "containers now" block on the settings page shows how much memory each container uses and which one would be stopped first. The same from the console:

```
/usr/local/emhttp/plugins/ram.guard/scripts/ramguard status
```

For a trial run, enable **dry run** mode. RAM Guard then only reports, in the log and in notifications, which container it would have stopped.

## Settings

Listed in the same order as on the settings page.

| Setting | Default | Description |
|---|---|---|
| Enabled | yes | when disabled, the daemon does not run |
| Warning threshold | 90% | notification only |
| Stop threshold | 95% | the largest container is stopped |
| Time above threshold | 15 s | protection against short spikes; 0 means act immediately |
| Check interval | 5 s | |
| Cooldown after a stop | 120 s | time for memory to be released before the next decision |
| Minimum container size | 512 MB | if memory is taken by VMs, ZFS or the system, small containers are left alone and only a notification is sent |
| Exclusions | — | `mariadb, plex, binhex-*`: case-insensitive, `*` and `?` wildcards allowed |
| Stop timeout | 30 s | `docker stop -t`; after it the container is killed |
| Count ZFS ARC as free memory | yes | ZFS cache above `c_min` counts as free, because the ARC shrinks on its own when RAM runs low |
| Unraid notifications | yes | |
| Repeat warnings at most every | 30 min | notifications about stopped containers are always sent |
| Dry run | no | stop nothing, only report |

## How memory is measured

Used memory = `MemTotal − MemAvailable` from `/proc/meminfo`, so the file cache does not count as used. This is closer to a real memory shortage than the "used" figure on the Dashboard. Container memory comes from `docker stats`, the same numbers the Docker tab shows.

## Good to know

- Only Docker containers are stopped. Virtual machines are never touched.
- A stopped container does not start again on its own. Start it from the Docker tab once you have found the cause.
- Databases and other critical containers belong in the exclusions.

## Files

| Path | What it is |
|---|---|
| `/boot/config/plugins/ram.guard/ram.guard.cfg` | settings (on the flash drive) |
| `/var/log/ram.guard.log` | plugin log; stops are also written to the syslog with the `ramguard` tag |
| `/usr/local/emhttp/plugins/ram.guard/scripts/rc.ramguard` | `start` / `stop` / `restart` / `status` of the daemon |

Uninstall: **Plugins → RAM Guard → Remove**. The daemon is stopped, and the settings and log are deleted.

## Building

`ram.guard.plg` is built from `src/` by `./build.sh`; make changes in `src/`. The version is today's date. Unraid only offers an update when the version increases, so build a second release on the same day like this: `VERSION=2026.10.26.1 ./build.sh`. Add an entry to `<CHANGES>` in `build.sh`, then commit `ram.guard.plg` together with the changes in `src/`.

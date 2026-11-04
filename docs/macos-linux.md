# macOS and Linux

You do not need this project on macOS or Linux. Both have a built-in tool. This table shows the same job on each.

| Job | Windows (this project) | macOS | Linux with systemd |
|---|---|---|---|
| Keep the system awake until you stop it | `caffeinate` | `caffeinate` | `systemd-inhibit --what=idle:sleep sleep infinity` |
| Stop after an hour | `caffeinate -t 3600` | `caffeinate -t 3600` | `systemd-inhibit --what=idle:sleep sleep 3600` |
| Keep the display on too | `caffeinate -d` | `caffeinate -d` | Not covered here |
| Stop when a process exits | `caffeinate -w <pid>` | `caffeinate -w <pid>` | Not covered here |

## macOS

`caffeinate` is part of macOS (`/usr/bin/caffeinate`). Its options are `-d`, `-i`, `-m`, `-s`, `-u`, `-t` and `-w`, and it can run a command and hold the assertions while the command runs (`caffeinate -i make`). From the `man caffeinate` page on macOS 26.6.2:

- With no assertion flags, it prevents idle sleep. The display can still sleep.
- `-d` creates a display assertion. Here, `-d` holds the system as well as the display.
- `-m`, `-s`, `-u` and the command form are not in this project. They give a clear message instead.

The Windows command was written to take the same flags, so a macOS habit carries over.

## Linux

`systemd-inhibit` takes a lock, runs a command, and releases the lock when the command ends. `--what=idle:sleep` is a valid value ([systemd-inhibit man page](https://www.freedesktop.org/software/systemd/man/latest/systemd-inhibit.html)).

- It only applies to systems that run systemd. Other init systems are not covered.
- `sleep infinity` is a GNU `sleep` feature.
- Whether a given desktop environment honors the lock is up to it.
- Keeping the display on needs the desktop's own settings or tools, and is not covered.

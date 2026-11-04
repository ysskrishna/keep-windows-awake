# What was tested

This page lists what was run, on what, and the result. Anything not on this page is not tested. The README and [methods.md](methods.md) mark each claim as **Tested**, **Documented** or **Untested**. This page is the source for **Tested**.

## Run so far

| Date | Where | What was run | Result |
|---|---|---|---|
| 2026-11-04 | macOS 26.6.2 (arm64), PowerShell 7.6.9 | The Pester tests that do not need Windows: argument checks, stray arguments, `-File` forwarding, dot-sourcing, the Constrained Language message, the macOS/Linux message. PSScriptAnalyzer 1.25.0 on `src/` and `tests/` | 23 passed, 11 skipped (the Windows-only tests), no analyzer findings |
| 2026-11-04 | macOS 26.6.2 (arm64) | The built-in `caffeinate -d -t 2`, and `man caffeinate`, to write the parity table in [macos-linux.md](macos-linux.md) | Exit 0. Options as listed in that page |

## Not run yet

These are what stand between "written" and "tested". The Windows rows are the ones that matter.

| Where | What | Status |
|---|---|---|
| GitHub Actions, `windows-latest`, Windows PowerShell 5.1 and PowerShell 7 | The full Pester suite: the wake request is set to the system flag, or system and display with `-d`, and is cleared after a timeout, when `-w` ends, and when the wait is interrupted | Not run |
| A managed Windows laptop | Paste the function, run `caffeinate -t 30`, check that it ends and that Ctrl+C releases it | Not run |
| A managed Windows laptop | Leave it idle past the Group Policy lock time with `caffeinate -d -t 1800` running, and see whether it locks | Not run |
| A managed Windows laptop | `PresentationSettings /start` and `/stop`, on an edition that has it | Not run |
| A managed Windows laptop | Whether `powercfg /change` needs an administrator | Not run |
| Windows 11 Home | That `PresentationSettings` is absent | Not run |
| Linux with systemd | The `systemd-inhibit` commands in [macos-linux.md](macos-linux.md) | Not run |

## Add your result

If you run it on a machine not listed here, [open an issue](https://github.com/ysskrishna/keep-windows-awake/issues/new/choose) with the Windows edition and build, the PowerShell version, the language mode, and what happened. Results from locked-down machines are the most useful.

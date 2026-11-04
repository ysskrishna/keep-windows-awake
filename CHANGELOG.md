# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-04

First release.

### Added

- **`caffeinate` command for Windows PowerShell and PowerShell 7.** Keeps the PC awake through the Windows `SetThreadExecutionState` call. It needs no installer and no elevation, and writes no files or settings. One file works pasted whole into a console, dot-sourced, or run with `-File`.
- **macOS-style flags.** `-d` holds the display as well as the system, `-i` is accepted (idle sleep is the default), `-t <seconds>` stops after a time, and `-w <pid>` stops when a process exits. With no `-t` or `-w` it runs until Ctrl+C. `-m`, `-s`, `-u` and the command form (`caffeinate -i make`) are not supported and say so in one line.
- **Safe cleanup.** The wake request is cleared when the command ends, when you press Ctrl+C, and when the wait fails.
- **Clear errors.** A session in Constrained Language mode, a bad `-t` or `-w`, a missing process and a stray argument each print one line, with exit code `1` or `2`, instead of a .NET error.
- **Methods guide** ([`docs/methods.md`](docs/methods.md)): what works under which restriction (blocked script files, Constrained Language mode, Windows Home, Group Policy locks).
- **Docs:** troubleshooting with common questions, macOS and Linux equivalents, and a record of what was tested ([`docs/tested.md`](docs/tested.md)).
- **Tests and CI.** Pester tests for arguments, language mode and the wake request itself, PSScriptAnalyzer, and `scripts/validate.sh` for version agreement and ASCII-only files. They run on `windows-latest` in Windows PowerShell 5.1 and PowerShell 7.
- **Release workflow.** A `v*` tag creates a GitHub Release with `caffeinate.ps1` and a SHA-256 file, after checking the tag against the script version and this changelog.
- `LICENSE`, `SECURITY.md`, `CODEOWNERS`, `FUNDING.yml` and issue templates.

[1.0.0]: https://github.com/ysskrishna/keep-windows-awake/releases/tag/v1.0.0

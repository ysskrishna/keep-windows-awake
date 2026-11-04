# What was tested

| Date | Where | What was run | Result |
|---|---|---|---|
| 2026-11-04 | GitHub Actions, `windows-latest`, Windows PowerShell 5.1 and PowerShell 7 | The full Pester suite, including the tests that call the Windows API (the wake request is the system flag, or system and display with `-d`, and is cleared after a timeout, when `-w` ends and when the wait is interrupted), and PSScriptAnalyzer | [Passed](https://github.com/ysskrishna/keep-windows-awake/actions/runs/41878924519) |
| 2026-11-04 | GitHub Actions, `ubuntu-latest`, PowerShell 7 | The tests that do not need Windows | Passed |
| 2026-11-04 | macOS 26.6.2 (arm64), PowerShell 7.6.9 | The same tests, and PSScriptAnalyzer 1.25.0 | 23 passed, 11 skipped (the Windows-only tests), no findings |
| 2026-11-04 | macOS 26.6.2 (arm64) | The built-in `caffeinate -d -t 2` and `man caffeinate`, to write the table in [macos-linux.md](macos-linux.md) | Options as listed in that page |

## Add your result

If you run it on another machine, [open an issue](https://github.com/ysskrishna/keep-windows-awake/issues/new/choose) with the Windows edition and build, the PowerShell version, the language mode, and what happened. Results from locked-down machines are the most useful.

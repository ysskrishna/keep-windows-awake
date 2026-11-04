# Keep Windows Awake

<img src="assets/logo-lockup.png" alt="Keep Windows Awake" width="520">

[![Validate](https://github.com/ysskrishna/keep-windows-awake/actions/workflows/validate.yml/badge.svg)](https://github.com/ysskrishna/keep-windows-awake/actions/workflows/validate.yml) [![License: MIT](https://img.shields.io/github/license/ysskrishna/keep-windows-awake)](https://github.com/ysskrishna/keep-windows-awake/blob/main/LICENSE) [![GitHub release](https://img.shields.io/github/v/release/ysskrishna/keep-windows-awake?label=release)](https://github.com/ysskrishna/keep-windows-awake/releases) [![Author site](https://img.shields.io/badge/author-ysskrishna.space-informational)](https://ysskrishna.space)

A PowerShell command, `caffeinate`, that keeps a Windows PC awake with the same flags as the macOS `caffeinate` (`-d`, `-i`, `-t`, `-w`). It needs no installer, no PowerToys, no winget and no elevation, and it writes nothing to disk. This repo also has a [guide to what still works](docs/methods.md) when IT has locked the laptop down.

## Quick start

1. Open PowerShell. A normal window is enough.
2. Paste this block and press Enter. It defines the command for this window only.

<!-- paste:begin -->
<details open>
<summary><b>caffeinate (paste into PowerShell)</b></summary>

```powershell
# keep-windows-awake 1.0.0 - https://github.com/ysskrishna/keep-windows-awake
function caffeinate {
    [CmdletBinding(PositionalBinding = $false)]
    param([switch]$d, [switch]$i, [switch]$m, [switch]$s, [switch]$u, $t, $w, [Parameter(ValueFromRemainingArguments = $true)]$command)

    $global:LASTEXITCODE = 0
    $fail = {
        param($code, $message)
        Write-Host "caffeinate: $message" -ForegroundColor Red
        $global:LASTEXITCODE = $code
    }

    # Add-Type is blocked outside FullLanguage, so say so instead of failing with a .NET error.
    $mode = "$($ExecutionContext.SessionState.LanguageMode)"
    if ($mode -ne 'FullLanguage') {
        & $fail 1 "this session is in $mode mode, which blocks the Windows call this needs. See https://github.com/ysskrishna/keep-windows-awake/blob/main/docs/methods.md"
        return
    }

    if ($command) {
        & $fail 2 "unexpected argument(s): $($command -join ' '). Supported: -d, -i, -t <seconds>, -w <pid>. Running a command is not supported; use -w <pid> to follow a process."
        return
    }

    $unsupported = @(if ($m) { '-m' }; if ($s) { '-s' }; if ($u) { '-u' })
    if ($unsupported.Count -gt 0) {
        & $fail 2 "$($unsupported -join ', ') not supported on Windows. Supported: -d, -i, -t <seconds>, -w <pid>."
        return
    }
    $null = $i # accepted for macOS parity; the system is always held

    $seconds = $null
    if ($PSBoundParameters.ContainsKey('t')) {
        if ("$t" -notmatch '^\d{1,9}$' -or [int]"$t" -lt 1) {
            & $fail 2 '-t needs a whole number of seconds, 1 or more.'
            return
        }
        $seconds = [int]"$t"
    }
    $processId = $null
    if ($PSBoundParameters.ContainsKey('w')) {
        if ("$w" -notmatch '^\d{1,9}$' -or [int]"$w" -lt 1) {
            & $fail 2 '-w needs a process id.'
            return
        }
        $processId = [int]"$w"
    }

    if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
        & $fail 1 'this version is for Windows. On macOS use the built-in caffeinate, on Linux use systemd-inhibit.'
        return
    }

    $watched = $null
    if ($null -ne $processId) {
        $watched = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if (-not $watched) {
            & $fail 1 "no process with id $processId."
            return
        }
        try { $null = $watched.HasExited } catch {
            & $fail 1 "cannot watch process ${processId}: $($_.Exception.Message)"
            return
        }
    }

    if (-not ('KeepWindowsAwake.Native' -as [type])) {
        Add-Type -Namespace KeepWindowsAwake -Name Native -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
    }

    $esContinuous = [uint32]2147483648 # 0x80000000
    $esSystem = [uint32]1              # ES_SYSTEM_REQUIRED
    $esDisplay = [uint32]2             # ES_DISPLAY_REQUIRED
    $flags = $esContinuous -bor $esSystem
    if ($d) { $flags = $flags -bor $esDisplay }

    $what = if ($d) { 'system and display' } else { 'system' }
    $until = 'until you press Ctrl+C'
    if ($null -ne $seconds) { $until = 'until ' + (Get-Date).AddSeconds($seconds).ToString('yyyy-MM-dd HH:mm') }
    if ($null -ne $watched) {
        if ($null -ne $seconds) { $until += " or process $processId exits, whichever comes first" }
        else { $until = "until process $processId exits" }
    }
    Write-Host "caffeinate: keeping the $what awake $until (Ctrl+C to stop)"

    [void][KeepWindowsAwake.Native]::SetThreadExecutionState([uint32]$flags)
    try {
        $clock = [Diagnostics.Stopwatch]::StartNew()
        while ($null -eq $seconds -or $clock.Elapsed.TotalSeconds -lt $seconds) {
            if ($null -ne $watched -and $watched.HasExited) { break }
            Start-Sleep -Seconds 1
        }
    }
    finally {
        [void][KeepWindowsAwake.Native]::SetThreadExecutionState($esContinuous)
        try { Write-Host 'caffeinate: stopped. Windows follows its normal sleep settings again.' } catch { $null = $_ }
    }
}
```

</details>
<!-- paste:end -->

3. Run it:

```powershell
caffeinate -d -t 3600
```

That keeps the system and the display awake for one hour. Press **Ctrl+C** to stop sooner. When it ends, Windows follows its normal sleep settings again.

Pasting works even when script files are blocked, because the execution policy applies to script files and profiles, not to text typed at the prompt ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)). It does not work if the session is in Constrained Language mode. The command tells you so in one line.

## Which method works on my laptop?

| Your situation | What to use | Status |
|---|---|---|
| Nothing blocked, or only installers (PowerToys, winget) are | `caffeinate`, pasted or from the file | Tested in CI. [Details](docs/tested.md) |
| Script files are blocked (execution policy) | Paste the function into the console | Documented by Microsoft |
| PowerShell is in Constrained Language mode (AppLocker or WDAC) | `caffeinate` cannot run. Use Presentation Settings or the power plan | Documented by Microsoft |
| Windows Home edition | Power plan in Settings | Documented by Microsoft |
| A Group Policy locks the session after inactivity | Nothing here stops it | Documented by Microsoft |

Each method, what it needs, what it cannot do and how to undo it is in [docs/methods.md](docs/methods.md). Not everything there has been run on every Windows edition. Each entry is marked **Tested**, **Documented** or **Untested**.

## Usage

```powershell
caffeinate                  # keep the system awake until Ctrl+C
caffeinate -d               # also keep the display on
caffeinate -t 3600          # stop after 3600 seconds
caffeinate -d -t 3600       # display on, for one hour
caffeinate -w 4242          # stop when process 4242 exits
caffeinate -t 3600 -w 4242  # stop at whichever comes first
```

| Flag | macOS `caffeinate` | This command |
|---|---|---|
| `-d` | Prevent the display from sleeping | Holds the display and the system |
| `-i` | Prevent idle sleep | Accepted. Already the default |
| `-t <seconds>` | Stop after this time | Same. Whole seconds, 1 or more |
| `-w <pid>` | Stop when this process exits | Same |
| `-m`, `-s`, `-u` | Disk idle, system sleep on AC, user active | Not supported. Prints a one-line message |
| `caffeinate -i make` | Stay awake while a command runs | Not supported. Use `-w <pid>` |

With no flags, both hold only the system awake. The display can still turn off. With no `-t` or `-w`, both run until you stop them. The exit code is `0` on success, `2` for a bad argument and `1` for anything else, such as a blocked session.

macOS and Linux equivalents are in [docs/macos-linux.md](docs/macos-linux.md).

## What it cannot do

It asks Windows not to sleep, the way a video player does. It does not press keys or move the mouse. Microsoft documents these limits of the API it uses ([SetThreadExecutionState](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)):

- It cannot stop you, or a policy, from putting the PC to sleep with the lid, the power button or Start > Sleep.
- It does not stop the screen saver.

A Group Policy such as "Interactive logon: Machine inactivity limit" locks the session after a period without *user input* ([Microsoft](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)). A wake request is not user input, so expect such a lock to still happen. That has not been tested here. See [docs/faq.md](docs/faq.md).

## Responsible use

`caffeinate` does what a video player does: it asks Windows to stay awake. It does not fake input and does not try to get around lock screens, monitoring or other IT controls. If your employer or school has rules about what you may run on a managed device, or about staying active, follow them. How you use it is your decision and your responsibility.

## Other ways to install

<details>
<summary><b>As a file</b></summary>

Download `caffeinate.ps1` from the [latest release](https://github.com/ysskrishna/keep-windows-awake/releases/latest), or copy [`src/caffeinate.ps1`](src/caffeinate.ps1). Then:

```powershell
.\caffeinate.ps1 -d -t 3600
```

Or load it as a command for the session:

```powershell
. .\caffeinate.ps1
caffeinate -t 3600
```

If Windows says the file cannot be loaded, the execution policy is blocking script files. Use the paste route above. A file downloaded in a browser also carries a "from the internet" mark, which `RemoteSigned` blocks until you run `Unblock-File .\caffeinate.ps1`. Only do that for a file you have read.

</details>

<details>
<summary><b>Check a release download</b></summary>

Each release has `caffeinate.ps1` and `caffeinate.ps1.sha256`. Compare the hash of your copy with the one in the `.sha256` file:

```powershell
(Get-FileHash .\caffeinate.ps1 -Algorithm SHA256).Hash
```

</details>

<details>
<summary><b>Available in every new window (PowerShell profile)</b></summary>

Save `caffeinate.ps1` somewhere permanent, then add a line to your profile that loads it:

```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content $PROFILE '. "C:\Tools\caffeinate.ps1"'
```

Change the path to where you saved the file. Windows PowerShell and PowerShell 7 each have their own `$PROFILE`, so repeat this in the one you use. Profiles are script files, so a restrictive execution policy stops them from loading. More in [docs/troubleshooting.md](docs/troubleshooting.md).

</details>

## Documentation

| Guide | What is in it |
|---|---|
| [docs/methods.md](docs/methods.md) | What works under which restriction, with commands and limits |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Find out which restriction you hit, and read each message |
| [docs/faq.md](docs/faq.md) | Lid, lock screen, remote desktop, battery |
| [docs/macos-linux.md](docs/macos-linux.md) | The same job on macOS and Linux, with built-in tools |
| [docs/tested.md](docs/tested.md) | What was run, on what, and when |
| [docs/development.md](docs/development.md) | Tests, checks, releases |

Reporting a vulnerability: see [SECURITY.md](SECURITY.md).

## Built and maintained by

Keep Windows Awake is built and maintained by:

| | Name | GitHub | Role |
|---|------|--------|------|
| <img src="https://github.com/ysskrishna.png?size=120" width="60" height="60" alt="Y. Siva Sai Krishna"> | **Y. Siva Sai Krishna** | [@ysskrishna](https://github.com/ysskrishna) | Creator |

## Changelog

See [CHANGELOG](https://github.com/ysskrishna/keep-windows-awake/blob/main/CHANGELOG.md) for release history.

## Support

If you find this helpful:

- ⭐ Star the repository
- 🐛 Report issues
- 🔀 Submit pull requests
- 💝 [Sponsor on GitHub](https://github.com/sponsors/ysskrishna)

## License

MIT © [Y. Siva Sai Krishna](https://github.com/ysskrishna) — see [LICENSE](https://github.com/ysskrishna/keep-windows-awake/blob/main/LICENSE) for details.

---

<p align="left">
  <a href="https://github.com/ysskrishna">Author's GitHub</a> •
  <a href="https://linkedin.com/in/ysskrishna">Author's LinkedIn</a> •
  <a href="https://ysskrishna.space">Author's site</a> •
  <a href="https://github.com/ysskrishna/keep-windows-awake/issues">Report Issues</a>
</p>

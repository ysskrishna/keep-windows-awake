# Troubleshooting

## Find out which restriction you hit

Run these four commands in PowerShell. They only read information.

```powershell
$PSVersionTable.PSVersion
$ExecutionContext.SessionState.LanguageMode
Get-ExecutionPolicy -List
(Get-CimInstance Win32_OperatingSystem).Caption
```

| What you see | What it means | What to do |
|---|---|---|
| `LanguageMode` is `FullLanguage` | `caffeinate` can run | Use [method 1 or 2](methods.md) |
| `LanguageMode` is `ConstrainedLanguage` | PowerShell blocks the Windows call `caffeinate` needs ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_language_modes)) | Use [method 3 or 4](methods.md) |
| `Get-ExecutionPolicy -List` shows `Restricted` or `AllSigned` for `CurrentUser` or `LocalMachine`, or any value for `MachinePolicy` or `UserPolicy` | Script files, and your profile, may not load | Paste the function instead of loading the file |
| The edition name contains `Home` | `PresentationSettings` is not available there | Use [method 4](methods.md) |

`MachinePolicy` and `UserPolicy` are set by Group Policy. They take precedence over the other scopes ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)).

## Messages from `caffeinate`

| Message | Cause | Fix |
|---|---|---|
| `this session is in ConstrainedLanguage mode, which blocks the Windows call this needs` | AppLocker or WDAC puts PowerShell in Constrained Language mode | [Methods 3 and 4](methods.md) |
| `-t needs a whole number of seconds, 1 or more.` | `-t` was `0`, negative, a fraction, text, or more than 9 digits | Use whole seconds, for example `-t 3600` |
| `-w needs a process id.` | `-w` was not a positive whole number | Find the id with `Get-Process`, then `-w <id>` |
| `no process with id N.` | No process has that id now | Check it with `Get-Process -Id N` |
| `cannot watch process N: ...` | Windows would not let this session read that process, for example one run by another user | Pick a process you started |
| `-m not supported on Windows` (also `-s`, `-u`) | These macOS flags have no Windows version here | Drop the flag. See [macos-linux.md](macos-linux.md) |
| `unexpected argument(s): ...` | A word or flag the command does not know. `caffeinate -i make` (run a command) is not supported | Use only `-d`, `-i`, `-t`, `-w`. To follow a process, use `-w` |
| `this version is for Windows` | You ran it in PowerShell on macOS or Linux | Use the built-in tool. See [macos-linux.md](macos-linux.md) |

## Windows errors you might meet

**`The term 'caffeinate' is not recognized`**

The command is not defined in this window. A pasted function lasts only for the window you pasted it into. Paste it again, or load it from a file or a [profile](../README.md#other-ways-to-install).

**`File ... cannot be loaded because running scripts is disabled on this system`**

The execution policy blocks script files. Paste the function into the console instead. Do not change the policy on a managed device without checking your organization's rules.

**`... is not digitally signed` or a file from the internet will not run**

A file downloaded in a browser carries a "from the internet" mark, and `RemoteSigned` blocks unsigned files with it ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)). Read the file, then `Unblock-File .\caffeinate.ps1`. Or paste the function.

**My profile does not load `caffeinate`**

Profiles are script files, so the execution policy applies to them. Also, Windows PowerShell and PowerShell 7 each have their own `$PROFILE`. Check the path with `$PROFILE`, and that the file exists with `Test-Path $PROFILE`.

## It runs, but the PC still sleeps or locks

See the [FAQ](faq.md). In short: the lid, the power button and Start > Sleep always win, the screen saver is not stopped, and a Group Policy inactivity lock is a separate control.

If none of that applies, [open an issue](https://github.com/ysskrishna/keep-windows-awake/issues/new/choose) with the output of the four commands above and the command you ran.

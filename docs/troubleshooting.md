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

The command is not defined in this window. A pasted function lasts only for the window you pasted it into. Paste it again, or load it from the file or a [profile](../README.md#other-ways-to-use-it).

**`File ... cannot be loaded because running scripts is disabled on this system`**

The execution policy blocks script files. Paste the function into the console instead. Do not change the policy on a managed device without checking your organization's rules.

**`... is not digitally signed` or a file from the internet will not run**

A file downloaded in a browser carries a "from the internet" mark, and `RemoteSigned` blocks unsigned files with it ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)). Read the file, then `Unblock-File .\caffeinate.ps1`. Or paste the function.

**My profile does not load `caffeinate`**

Profiles are script files, so the execution policy applies to them. Also, Windows PowerShell and PowerShell 7 each have their own `$PROFILE`. Check the path with `$PROFILE`, and that the file exists with `Test-Path $PROFILE`.

## Questions

**Will it stop my screen from locking?**

It stops the PC from going to sleep, and with `-d` the display from turning off for being idle. It does not stop the screen saver ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). A Group Policy inactivity lock is a separate control. See [methods.md](methods.md#5-a-group-policy-lock).

**Will it keep the PC awake when I close the lid?**

No. Microsoft says the function cannot stop a user from putting the computer to sleep, and that includes the lid, the power button and Start > Sleep ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). What closing the lid does is a power setting you choose in Windows.

**What happens when I close the PowerShell window?**

The request ends. It belongs to the thread that made it, and the thread ends with the window ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). Keep the window open while you need the PC awake. You can minimize it.

**Does it change any Windows setting, or need admin rights?**

No to both. It makes one API call and clears it when it ends. It does not touch the power plan, the registry, files or scheduled tasks, and it never asks for elevation. If you want a permanent change instead, see [method 4](methods.md#4-the-power-settings).

**Does it keep chat apps from showing me as Away?**

Those apps use their own idle detection. This command sends no keyboard or mouse input, so it is not meant for that.

**Does it use battery faster?**

Keeping the system awake means the PC does not enter its low-power sleep state while the command runs. Keeping the display on with `-d` uses more again. Plug in for long runs.

**Why does it not move the mouse or press a key?**

By design. A wake request is what a video player uses. Fake input is out of scope, because some managed environments treat it as getting around a control. See [methods.md](methods.md#not-covered-on-purpose).

**Can I use the macOS flags I know?**

`-d`, `-i`, `-t` and `-w` work. `-m`, `-s`, `-u` and running a command (`caffeinate -i make`) do not. See the [table in the README](../README.md#usage).

## Still stuck

[Open an issue](https://github.com/ysskrishna/keep-windows-awake/issues/new/choose) with the output of the four commands at the top of this page and the command you ran.

# Methods: what works under which restriction

Pick the row that matches your laptop. If you do not know which one you have, [troubleshooting](troubleshooting.md) has four read-only commands that tell you.

Each claim links to its source, Microsoft documentation where there is any.

## At a glance

| Your situation | Method |
|---|---|
| Nothing blocked, or only installers (PowerToys, winget) are | [1. The `caffeinate` command](#1-the-caffeinate-command) |
| Script files are blocked | [2. Paste it into the console](#2-paste-it-into-the-console) |
| Constrained Language mode | [3. Presentation Settings](#3-presentation-settings) |
| Constrained Language mode, or Windows Home | [4. The power settings](#4-the-power-settings) |
| A Group Policy locks the session after inactivity | [5. Nothing here stops it](#5-a-group-policy-lock) |

Methods 1 and 2 are the same command. Method 2 only changes how you load it.

## 1. The `caffeinate` command

```powershell
caffeinate -d -t 3600
```

- **What it does:** calls the Windows `SetThreadExecutionState` API with the "system required" flag, and with `-d` the "display required" flag too ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). It is the call media players use.
- **Requires:** Windows PowerShell 5.1 or PowerShell 7, in `FullLanguage` mode. No installer, no elevation, no files written, no registry changes.
- **Cannot do:** stop sleep from the lid, the power button or Start > Sleep. Stop the screen saver. Stop a Group Policy lock. All three are limits of the API ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate), [Microsoft](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)).
- **Undo:** press Ctrl+C, or close the window. The request belongs to the thread that made it, so it ends with it ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). The command also clears the request itself when it ends.
- **Checked in CI:** the API call, the exit codes and the cleanup, on Windows ([tested.md](tested.md)).

## 2. Paste it into the console

Copy the contents of [`src/caffeinate.ps1`](../src/caffeinate.ps1), paste them into PowerShell and press Enter (see the [README](../README.md#quick-start)).

- **When to use it:** running a `.ps1` file is refused ("running scripts is disabled on this system"), or your profile does not load.
- **Why it can work:** the execution policy applies to script files and profiles, not to text typed or pasted at the prompt. Microsoft states the policy is not a security boundary ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)).
- **Requires:** the same as method 1.
- **Cannot do:** anything method 1 cannot. It also does nothing when another control, such as AppLocker, WDAC or Group Policy, restricts PowerShell in a different way.
- **Undo:** close the window. The command is gone with it.

## 3. Presentation Settings

```powershell
PresentationSettings /start
PresentationSettings /stop
```

- **What it does:** turns on Windows "presentation mode", which keeps the PC awake and turns off system notifications. Run `PresentationSettings` with no flag to open its dialog, where you can also choose to turn off the screen saver, set the volume and change the wallpaper. Check the dialog first, so presentation mode does not change more than you expect.
- **Requires:** a Windows edition that includes it. Secondary sources say Pro and Enterprise have it and Home does not ([BetaWiki](https://betawiki.net/wiki/Presentation_Mode)). The `/start` and `/stop` flags are described by [Winaero](https://winaero.com/enable-presentation-mode-windows-10/).
- **Does not need:** PowerShell, so it is a way in when PowerShell is in Constrained Language mode.
- **Cannot do:** stop a Group Policy lock. Work if an administrator turned presentation settings off by policy.
- **Another route:** Windows Mobility Center, then Presentation Settings, then **Turn on**. Winaero says it is available on laptops by default.
- **Undo:** `PresentationSettings /stop`, or **Turn off** in Mobility Center.
- **Sources:** both describe Windows 10.

## 4. The power settings

In Windows 11: **Settings > System > Power & battery > Screen, sleep & hibernate timeouts**. Set **Make my device sleep after** (and **Turn my screen off after**, if you want) to a longer time ([Microsoft](https://support.microsoft.com/en-us/windows/experience/power-battery/power-settings-in-windows-11)).

From a terminal, `powercfg /change` sets the same values, in minutes, for the current power scheme. For example, `powercfg /change standby-timeout-ac 120` makes the PC sleep after 120 idle minutes while plugged in ([Microsoft](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options)).

- **What it does:** changes your real, saved Windows settings. It keeps working after you close every window, and it keeps working after a restart.
- **Requires:** nothing special, unless your organization has locked the Settings page.
- **Cannot do:** stop a Group Policy lock. Stay in force if IT policy or a manufacturer utility resets the values. Both are reported on Microsoft's Q&A pages ([example](https://learn.microsoft.com/en-us/answers/questions/3884280/in-windows-11-the-setting-for-screen-and-sleep-kee)), which are community answers, not documentation.
- **Undo:** set the old values back. Write them down first. `powercfg /query` prints the current ones.

## 5. A Group Policy lock

"Interactive logon: Machine inactivity limit" locks the session after a set number of seconds without user input. When it is on, the device also locks when the screen saver starts or the display turns off ([Microsoft](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)).

The policy counts user input, and a wake request is not user input, so methods 1 to 4 are not expected to stop this lock. Nothing here tries to get around it.

If the lock gets in the way of real work, ask your IT team. They can tell you the limit, or whether an exception exists for your role.

## Not covered on purpose

Tools that press keys or move the mouse to look active are not covered here. Some managed environments treat that as getting around a control, and this project does not suggest it. `caffeinate` asks Windows to stay awake, the way a video player does. If your employer or school has rules about what you may run on a managed device, follow them.

For the same job on macOS and Linux, see [macos-linux.md](macos-linux.md).

# FAQ

## Will it stop my screen from locking?

It stops the PC from going to sleep, and with `-d` the display from turning off for being idle. It does not stop the screen saver ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)).

A Group Policy such as "Interactive logon: Machine inactivity limit" locks the session after a period without user input ([Microsoft](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/interactive-logon-machine-inactivity-limit)). A wake request is not user input, so expect that lock to still happen. This has not been tested here. See [methods.md](methods.md#5-a-group-policy-lock).

## Will it keep the PC awake when I close the lid?

No. Microsoft says the function cannot be used to stop a user from putting the computer to sleep, and that includes the lid, the power button and Start > Sleep ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). What closing the lid does is a power setting you choose in Windows, not something this command overrides.

## What happens when I close the PowerShell window?

The request ends. It belongs to the thread that made it, and the thread ends with the window ([Microsoft](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate)). Keep the window open while you need the PC awake. You can minimize it.

## Does it change any Windows setting?

No. It makes one API call and clears it when it ends. It does not touch the power plan, the registry, files or scheduled tasks. Your sleep settings apply again as soon as it stops. If you want a permanent change instead, see [method 4](methods.md#4-the-power-settings).

## Does it need admin rights?

The script never asks for elevation and contains nothing that needs it. Whether a given managed laptop lets a standard user run it is what [tested.md](tested.md) tracks.

## Does it work over Remote Desktop, or in a virtual machine?

Not tested.

## Does it keep chat apps from showing me as Away?

Not tested. Those apps use their own idle detection, and this command sends no keyboard or mouse input, so do not rely on it for that.

## Will a security tool flag it?

Not checked. The script is one short file that makes one Win32 call through `Add-Type`. Some security products treat that pattern with suspicion in general. If a tool on a managed device blocks it, do not work around the block. Ask your IT team.

## Does it use battery faster?

Keeping the system awake means the PC does not enter its low-power sleep state while the command runs. Keeping the display on with `-d` uses more again. Plug in for long runs.

## Why does it not move the mouse or press a key?

By design. A wake request is the same thing a video player uses, and it does not look like a person using the machine. Fake input is out of scope for this project, because some managed environments treat it as getting around a control. See [Responsible use](../README.md#responsible-use).

## Can I use the macOS flags I know?

`-d`, `-i`, `-t` and `-w` work. `-m`, `-s`, `-u` and running a command (`caffeinate -i make`) do not. See the [table in the README](../README.md#usage).

## How do I report a problem?

[Open an issue](https://github.com/ysskrishna/keep-windows-awake/issues/new/choose). The template asks for the version, the edition and PowerShell version, and the language mode. Those four commands are in [troubleshooting.md](troubleshooting.md#find-out-which-restriction-you-hit).

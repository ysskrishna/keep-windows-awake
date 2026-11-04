# Other ways to install

The [quick start](../README.md#quick-start) pastes the file into a console. That needs no download and works when script files are blocked. These are the alternatives.

## Run it as a file

Download `caffeinate.ps1` from the [latest release](https://github.com/ysskrishna/keep-windows-awake/releases/latest), or copy [`src/caffeinate.ps1`](../src/caffeinate.ps1). Then:

```powershell
.\caffeinate.ps1 -d -t 3600
```

If Windows says the file cannot be loaded, the execution policy is blocking script files. Paste the file instead.

A file downloaded in a browser also carries a "from the internet" mark, which `RemoteSigned` blocks ([Microsoft](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)). Read the file, then run `Unblock-File .\caffeinate.ps1`.

## Check a release download

Each release has `caffeinate.ps1` and `caffeinate.ps1.sha256`. Compare the hash of your copy with the one in the `.sha256` file:

```powershell
(Get-FileHash .\caffeinate.ps1 -Algorithm SHA256).Hash
```

## Make it available in every new window

Save `caffeinate.ps1` somewhere permanent, then add a line to your PowerShell profile that loads it:

```powershell
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
Add-Content $PROFILE '. "C:\Tools\caffeinate.ps1"'
```

Change the path to where you saved the file. Windows PowerShell and PowerShell 7 each have their own `$PROFILE`, so repeat this in the one you use. Profiles are script files, so a restrictive execution policy stops them from loading. If `caffeinate` is not found in a new window, see [troubleshooting](troubleshooting.md#windows-errors-you-might-meet).

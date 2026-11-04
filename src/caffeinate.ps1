<#
.SYNOPSIS
Keeps Windows awake for a set time, like the macOS caffeinate command.

.DESCRIPTION
Asks Windows not to sleep (and, with -d, not to turn the display off) until the
time is up, until you press Ctrl+C, or until a process exits. It calls the
SetThreadExecutionState API, the same call media players use. It needs no
install and no admin rights, changes no settings, and writes nothing to disk.
The request lasts only while this PowerShell window runs the command.

It does not stop the screen saver or a Group Policy lock, and it does not stop
sleep from the Start menu, the power button or closing the lid.

.PARAMETER d
Keep the display on as well as the system.

.PARAMETER i
Prevent idle sleep. This is already the default. Accepted so macOS commands
work unchanged.

.PARAMETER t
Stop after this many whole seconds. Without -t, runs until Ctrl+C.

.PARAMETER w
Stop when the process with this id exits. With -t, stops at whichever comes first.

.PARAMETER m
Not supported on Windows. Accepted so the error message is clear.

.PARAMETER s
Not supported on Windows. Accepted so the error message is clear.

.PARAMETER u
Not supported on Windows. Accepted so the error message is clear.

.EXAMPLE
.\caffeinate.ps1 -d -t 3600
Keeps the system and display awake for one hour.

.EXAMPLE
. .\caffeinate.ps1
caffeinate -t 3600
Loads the function into this session, then keeps the system awake for one hour.

.NOTES
Version: 1.0.0
Author:  Y. Siva Sai Krishna
License: MIT
Project: https://github.com/ysskrishna/keep-windows-awake

.LINK
https://github.com/ysskrishna/keep-windows-awake
#>
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

# When this file is run (.\caffeinate.ps1 -d -t 3600), run the command. When it is pasted
# into a console or dot-sourced, only define it.
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.MyCommand -is [System.Management.Automation.ExternalScriptInfo]) {
    caffeinate @args
    exit $global:LASTEXITCODE
}

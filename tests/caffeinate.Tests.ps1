#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
    $script:Source = [IO.Path]::GetFullPath([IO.Path]::Combine($PSScriptRoot, '..', 'src', 'caffeinate.ps1'))
    $script:HostPath = (Get-Process -Id $PID).Path
    . $script:Source

    # Runs caffeinate with named parameters and returns what it printed plus the exit code.
    function Invoke-Caffeinate {
        param([hashtable]$Params = @{})
        # Out-String wraps at the console width, so collapse whitespace before matching.
        $text = (caffeinate @Params 6>&1 | Out-String) -replace '\s+', ' '
        [pscustomobject]@{ Text = $text; ExitCode = $global:LASTEXITCODE }
    }

    # Clears the execution state on this thread and returns the system/display flags that were set before.
    # The type only exists after caffeinate has run Add-Type, so nothing was set if it is missing.
    function Get-AndClearState {
        if (-not ('KeepWindowsAwake.Native' -as [type])) { return 0 }
        $esContinuous = [uint32]2147483648
        [int]([KeepWindowsAwake.Native]::SetThreadExecutionState($esContinuous) -band 3)
    }
}

Describe 'arguments' {
    It 'rejects <flag> as not supported on Windows' -ForEach @(
        @{ flag = 'm' }, @{ flag = 's' }, @{ flag = 'u' }
    ) {
        $r = Invoke-Caffeinate @{ $flag = $true }
        $r.ExitCode | Should -Be 2
        $r.Text | Should -Match 'not supported on Windows'
        $r.Text | Should -Match "-$flag not supported"
    }

    It 'names every unsupported flag when several are given' {
        $r = Invoke-Caffeinate @{ m = $true; u = $true }
        $r.Text | Should -Match '-m, -u not supported'
    }

    It 'rejects -t <value>' -ForEach @(
        @{ value = '0' }, @{ value = '-5' }, @{ value = 'abc' }, @{ value = '1.5' }, @{ value = '9999999999' }
    ) {
        $r = Invoke-Caffeinate @{ t = $value }
        $r.ExitCode | Should -Be 2
        $r.Text | Should -Match '-t needs a whole number of seconds'
    }

    It 'rejects -w <value>' -ForEach @(
        @{ value = '0' }, @{ value = '-3' }, @{ value = 'abc' }
    ) {
        $r = Invoke-Caffeinate @{ w = $value }
        $r.ExitCode | Should -Be 2
        $r.Text | Should -Match '-w needs a process id'
    }

    It 'rejects stray arguments instead of treating them as -t or -w: <case>' -ForEach @(
        @{ case = 'a command name'; params = @{ command = 'make' } }
        @{ case = 'a bare number'; params = @{ command = '3600' } }
        @{ case = 'an unknown flag'; params = @{ command = '-x' } }
        @{ case = 'a command after -t'; params = @{ t = '5'; command = 'make' } }
    ) {
        $r = Invoke-Caffeinate $params
        $r.ExitCode | Should -Be 2
        $r.Text | Should -Match 'unexpected argument'
        $r.Text | Should -Match 'Running a command is not supported'
    }

    It 'binds -d, -i, -t, -w and -m to its own parameters, not to common ones such as -Debug' {
        $parameters = (Get-Command caffeinate -CommandType Function).Parameters
        foreach ($name in 'd', 'i', 'm', 's', 'u') { $parameters[$name].ParameterType | Should -Be ([switch]) }
        foreach ($name in 't', 'w') { $parameters[$name].Aliases.Count | Should -Be 0 }
        $parameters['d'].Aliases.Count | Should -Be 0
    }

    It 'checks arguments before the platform, so the same message appears on every OS' {
        (Invoke-Caffeinate @{ t = '0' }).Text | Should -Not -Match 'macOS'
    }
}

Describe 'running as a file' {
    It 'forwards arguments: bad -t exits 2' {
        $out = & $script:HostPath -NoProfile -ExecutionPolicy Bypass -File $script:Source -t 0 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 2
        $out | Should -Match '-t needs a whole number of seconds'
    }

    It 'forwards switches: -u is reported as unsupported' {
        $out = & $script:HostPath -NoProfile -ExecutionPolicy Bypass -File $script:Source -u 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 2
        $out | Should -Match '-u not supported'
    }

    It 'can be pasted into a console: defines the command and does not run it' {
        $stdin = Join-Path ([IO.Path]::GetTempPath()) "caffeinate-paste-$PID.txt"
        $stdout = Join-Path ([IO.Path]::GetTempPath()) "caffeinate-paste-out-$PID.txt"
        try {
            # What a paste does: the whole file, then a command typed after it.
            Set-Content -Path $stdin -Value ((Get-Content -Raw $script:Source) + "`ncaffeinate -m`n") -Encoding ASCII
            $p = Start-Process -FilePath $script:HostPath -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', '-' `
                -RedirectStandardInput $stdin -RedirectStandardOutput $stdout -NoNewWindow -PassThru
            $exited = $p.WaitForExit(60000)
            if (-not $exited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
            $exited | Should -BeTrue -Because 'pasting the file must not start the command'
            (Get-Content -Raw $stdout) | Should -Match '-m not supported on Windows'
        }
        finally { Remove-Item $stdin, $stdout -Force -ErrorAction SilentlyContinue }
    }

    It 'only defines the function when dot-sourced' {
        $cmd = ". '$($script:Source)'; (Get-Command caffeinate -CommandType Function).Name"
        $out = & $script:HostPath -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1 | Out-String
        $out.Trim() | Should -Be 'caffeinate'
    }
}

Describe 'language mode' {
    It 'explains the problem instead of failing in Add-Type' {
        $cmd = "`$ExecutionContext.SessionState.LanguageMode = 'ConstrainedLanguage'; . '$($script:Source)'; caffeinate -t 1; exit `$LASTEXITCODE"
        $out = & $script:HostPath -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 1
        $out | Should -Match 'ConstrainedLanguage mode'
        $out | Should -Match 'docs/methods.md'
    }
}

Describe 'on macOS and Linux' -Skip:($env:OS -eq 'Windows_NT') {
    It 'points to the built-in tools' {
        $r = Invoke-Caffeinate @{ t = '1' }
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match 'built-in caffeinate'
        $r.Text | Should -Match 'systemd-inhibit'
    }
}

Describe 'on Windows' -Skip:($env:OS -ne 'Windows_NT') {
    AfterEach {
        # Never leave a request behind, even if a test fails halfway.
        [void](Get-AndClearState)
    }

    It 'rejects -w with a process id that does not exist' {
        $missing = 987654
        if (Get-Process -Id $missing -ErrorAction SilentlyContinue) { Set-ItResult -Skipped -Because 'pid in use'; return }
        $r = Invoke-Caffeinate @{ w = $missing }
        $r.ExitCode | Should -Be 1
        $r.Text | Should -Match "no process with id $missing"
    }

    It 'holds the system only by default (flags 1)' {
        $script:seen = $null
        Mock Start-Sleep {
            if ($null -eq $script:seen) { $script:seen = Get-AndClearState }
            [Threading.Thread]::Sleep(100)
        }
        $r = Invoke-Caffeinate @{ t = 1 }
        $r.ExitCode | Should -Be 0
        $script:seen | Should -Be 1
    }

    It 'holds system and display with -d (flags 3)' {
        $script:seen = $null
        Mock Start-Sleep {
            if ($null -eq $script:seen) { $script:seen = Get-AndClearState }
            [Threading.Thread]::Sleep(100)
        }
        $r = Invoke-Caffeinate @{ d = $true; t = 1 }
        $r.ExitCode | Should -Be 0
        $script:seen | Should -Be 3
    }

    It 'treats -i as the default' {
        $script:seen = $null
        Mock Start-Sleep {
            if ($null -eq $script:seen) { $script:seen = Get-AndClearState }
            [Threading.Thread]::Sleep(100)
        }
        [void](Invoke-Caffeinate @{ i = $true; t = 1 })
        $script:seen | Should -Be 1
    }

    It 'clears the request after the timeout' {
        $r = Invoke-Caffeinate @{ t = 1 }
        $r.ExitCode | Should -Be 0
        $r.Text | Should -Match 'keeping the system awake until'
        $r.Text | Should -Match 'stopped'
        Get-AndClearState | Should -Be 0
    }

    It 'clears the request when the wait is interrupted' {
        Mock Start-Sleep { throw 'interrupted' }
        { caffeinate -d -t 30 6>$null } | Should -Throw 'interrupted'
        Get-AndClearState | Should -Be 0
    }

    It 'stops after -t seconds' {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        [void](Invoke-Caffeinate @{ t = 2 })
        $watch.Elapsed.TotalSeconds | Should -BeGreaterOrEqual 1.9
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 8
    }

    It 'stops when the -w process exits' {
        $child = Start-Process -FilePath $script:HostPath -ArgumentList '-NoProfile', '-Command', 'Start-Sleep -Seconds 3' -PassThru -WindowStyle Hidden
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Caffeinate @{ w = $child.Id }
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 30
        $child.HasExited | Should -BeTrue
        $r.Text | Should -Match "until process $($child.Id) exits"
        Get-AndClearState | Should -Be 0
    }

    It 'stops at -t when the -w process outlives it' {
        $child = Start-Process -FilePath $script:HostPath -ArgumentList '-NoProfile', '-Command', 'Start-Sleep -Seconds 20' -PassThru -WindowStyle Hidden
        try {
            $watch = [Diagnostics.Stopwatch]::StartNew()
            $r = Invoke-Caffeinate @{ t = 2; w = $child.Id }
            $watch.Elapsed.TotalSeconds | Should -BeLessThan 10
            $r.Text | Should -Match 'whichever comes first'
        }
        finally { Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue }
    }

    It 'can run twice in one session' {
        (Invoke-Caffeinate @{ t = 1 }).ExitCode | Should -Be 0
        (Invoke-Caffeinate @{ t = 1 }).ExitCode | Should -Be 0
    }

    It 'works when run as a file' {
        $out = & $script:HostPath -NoProfile -ExecutionPolicy Bypass -File $script:Source -d -t 1 2>&1 | Out-String
        $LASTEXITCODE | Should -Be 0
        $out | Should -Match 'system and display'
    }
}

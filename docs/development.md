# Development

```text
src/caffeinate.ps1          the command, and the file you paste or run
tests/caffeinate.Tests.ps1  Pester v5 tests
scripts/validate.sh         version and encoding checks
.github/workflows/          validate.yml, release.yml
```

## Run the checks

You need PowerShell 7 (`pwsh`), Pester 5 and PSScriptAnalyzer.

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -MaximumVersion 5.99.99 -Scope CurrentUser
Install-Module PSScriptAnalyzer -Scope CurrentUser
```

```powershell
Invoke-ScriptAnalyzer -Path src -Recurse -Severity Error, Warning -ExcludeRule PSAvoidUsingWriteHost
Invoke-ScriptAnalyzer -Path tests -Recurse -Severity Error, Warning -ExcludeRule PSAvoidUsingWriteHost
Invoke-Pester -Path tests -Output Detailed
```

```bash
bash scripts/validate.sh
```

On macOS and Linux the tests that call the Windows API are skipped. They run on Windows and in CI, which uses `windows-latest` with both Windows PowerShell 5.1 and PowerShell 7.

`validate.sh` checks that the version in the `src/caffeinate.ps1` header matches the top entry in `CHANGELOG.md`, and that the PowerShell files are plain ASCII. Windows PowerShell 5.1 reads a file without a byte-order mark as the system code page, so other characters can turn into garbage.

## Release

1. Change `Version:` in the header of `src/caffeinate.ps1`, and add a section at the top of `CHANGELOG.md` with a footer link.
2. Run the checks above, then merge to `main`.
3. Tag it and push the tag:

   ```bash
   git tag -a v1.0.0 -m "v1.0.0"
   git push origin v1.0.0
   ```

The release workflow stops if the tag, the script version and the top of the CHANGELOG disagree. It then attaches `caffeinate.ps1` and `caffeinate.ps1.sha256` and builds the release notes from the tag message, or else from the matching `CHANGELOG.md` section.

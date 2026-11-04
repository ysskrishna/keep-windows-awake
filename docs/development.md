# Development

The project is one script, `src/caffeinate.ps1`, with tests, a checker and two workflows.

```text
src/caffeinate.ps1          the command, and the file you can run
tests/caffeinate.Tests.ps1  Pester v5 tests
scripts/validate.sh         version, README block, links and safety checks
PSScriptAnalyzerSettings.psd1
.github/workflows/          validate.yml, release.yml
```

## Run the checks

You need PowerShell 7 (`pwsh`), Pester 5 and PSScriptAnalyzer, plus `python3` and `bash`.

```powershell
Install-Module Pester -MinimumVersion 5.5.0 -MaximumVersion 5.99.99 -Scope CurrentUser
Install-Module PSScriptAnalyzer -Scope CurrentUser
```

```powershell
Invoke-ScriptAnalyzer -Path src -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-ScriptAnalyzer -Path tests -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
Invoke-Pester -Path tests -Output Detailed
```

```bash
bash scripts/validate.sh
```

On macOS and Linux the tests that call the Windows API are skipped. They run on Windows and in CI. CI runs the suite on `windows-latest` in both Windows PowerShell 5.1 and PowerShell 7.

## What `validate.sh` checks

- The version in the `src/caffeinate.ps1` header, in the line inside the function, in the README paste block and at the top of `CHANGELOG.md` is the same.
- The README paste block is identical to the function in `src/caffeinate.ps1`. After changing the function, run `bash scripts/validate.sh --sync-readme` to rewrite the block, then check the diff.
- `src/caffeinate.ps1` is plain ASCII. Windows PowerShell 5.1 reads a file without a byte-order mark as the system code page, so other characters can turn into garbage.
- The script has no network, file-write, registry or scheduled-task commands, which the README says it does not use.
- No code block in the README or `docs/` pipes a download into a shell or `Invoke-Expression`.
- Required files exist, and relative links and images in the README and `docs/` resolve.
- With `--external`, links to other sites resolve. This runs weekly in CI. It reports a `403` as a warning, because some sites refuse automated requests.

## Release

1. Change the version in two places in `src/caffeinate.ps1` (the `.NOTES` header and the comment line inside the function), and add a section at the top of `CHANGELOG.md` with a footer link.
2. Run `bash scripts/validate.sh --sync-readme`, then the checks above.
3. Merge to `main`.
4. Tag it and push the tag:

   ```bash
   git tag -a v1.0.0 -m "v1.0.0"
   git push origin v1.0.0
   ```

The release workflow stops if the tag, the script version and the top of the CHANGELOG disagree. It then attaches `caffeinate.ps1` and `caffeinate.ps1.sha256` and builds the release notes from the tag message, or else from the matching `CHANGELOG.md` section.

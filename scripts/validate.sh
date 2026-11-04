#!/usr/bin/env bash
# Two checks that tests do not cover:
#   1. The version in src/caffeinate.ps1 matches the top entry in CHANGELOG.md.
#   2. The PowerShell files are plain ASCII. Windows PowerShell 5.1 reads a file without a
#      byte-order mark as the system code page, so other characters can turn into garbage.
set -euo pipefail
cd "$(dirname "$0")/.."

version="$(sed -n 's/^Version:[[:space:]]*\([0-9][0-9.]*\)[[:space:]]*$/\1/p' src/caffeinate.ps1 | head -n 1)"
changelog="$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' CHANGELOG.md | head -n 1)"
if [ -z "$version" ] || [ "$version" != "$changelog" ]; then
    echo "FAIL script version '${version}' does not match the top of CHANGELOG.md '${changelog}'"
    exit 1
fi
echo "OK   version $version"

for f in src/caffeinate.ps1 tests/caffeinate.Tests.ps1; do
    if LC_ALL=C grep -n '[^[:print:][:space:]]' "$f"; then
        echo "FAIL $f has non-ASCII characters"
        exit 1
    fi
    echo "OK   $f is ASCII"
done

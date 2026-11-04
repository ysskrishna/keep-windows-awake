#!/usr/bin/env bash
# Validate the repo: versions that must agree, the README paste block against the script,
# ASCII-only PowerShell files, the script's no-network/no-writes promise, no pipe-to-shell
# in the docs, and links and images in the README and docs/.
#
#   bash scripts/validate.sh                 run all checks
#   bash scripts/validate.sh --sync-readme   rewrite the README paste block from src/caffeinate.ps1
#   bash scripts/validate.sh --external      also check links to other sites (a 403 is a warning)
set -uo pipefail
cd "$(dirname "$0")/.."

command -v python3 >/dev/null 2>&1 || { echo "FAIL python3 is required"; exit 1; }

python3 - "$@" <<'EOF'
import glob, os, re, sys, urllib.error, urllib.request

REPO = "ysskrishna/keep-windows-awake"
SRC = "src/caffeinate.ps1"
SYNC = "--sync-readme" in sys.argv
EXTERNAL = "--external" in sys.argv
bad = 0

def ok(msg): print(f"OK   {msg}")
def warn(msg): print(f"WARN {msg}")
def err(msg):
    global bad
    bad = 1
    print(f"FAIL {msg}")

def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()

# 1. Required files
for f in ("README.md", "LICENSE", "CHANGELOG.md", "SECURITY.md", SRC, "tests/caffeinate.Tests.ps1",
          "docs/methods.md", "docs/troubleshooting.md", "docs/faq.md", "docs/macos-linux.md",
          "docs/tested.md", "docs/development.md", ".github/CODEOWNERS", ".github/FUNDING.yml"):
    if not os.path.isfile(f):
        err(f"missing {f}")
if bad:
    sys.exit(1)

src = read(SRC)
readme = read("README.md")

# 2. The function block in the script, and the paste block in the README
fn_match = re.search(r"^# >>> function begin\n(.*?)^# <<< function end$", src, re.S | re.M)
if not fn_match:
    err(f"{SRC}: '# >>> function begin' / '# <<< function end' markers not found")
    sys.exit(1)
function = fn_match.group(1).rstrip("\n")

block_re = re.compile(r"(<!-- paste:begin -->.*?```powershell\n)(.*?)(\n```.*?<!-- paste:end -->)", re.S)
block = block_re.search(readme)
if not block:
    err("README.md: paste block markers or ```powershell fence not found")
    sys.exit(1)
if SYNC and block.group(2) != function:
    readme = readme[:block.start(2)] + function + readme[block.end(2):]
    with open("README.md", "w", encoding="utf-8") as f:
        f.write(readme)
    print("SYNC README.md paste block rewritten from " + SRC)
    block = block_re.search(readme)
if block.group(2) == function:
    ok("README paste block matches the function in " + SRC)
else:
    err("README paste block differs from the function in " + SRC + " (run: bash scripts/validate.sh --sync-readme)")

# 3. One version everywhere
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")
m = re.search(r"^Version:\s+(\S+)\s*$", src, re.M)
header = m.group(1) if m else None
m = re.search(r"^# keep-windows-awake (\S+) - ", function, re.M)
inline = m.group(1) if m else None
if not header or not SEMVER.match(header):
    err(f"{SRC}: header 'Version:' is {header!r}, expected X.Y.Z")
elif header != inline:
    err(f"{SRC}: header version {header!r} differs from the line inside the function {inline!r}")
else:
    ok(f"script version {header}")
cl = read("CHANGELOG.md")
heads = re.findall(r"^## \[(\d+\.\d+\.\d+)\]", cl, re.M)
if not heads or heads[0] != header:
    err(f"CHANGELOG top version {heads[:1]} differs from the script version {header!r}")
elif not re.search(rf"^\[{re.escape(header)}\]: https://github.com/{REPO}/", cl, re.M):
    err(f"CHANGELOG has no footer link for [{header}]")
else:
    ok(f"CHANGELOG top version {header} matches the script")

# 4. PowerShell files are ASCII (Windows PowerShell 5.1 reads BOM-less files as the system code page)
for path in (SRC, "tests/caffeinate.Tests.ps1", "PSScriptAnalyzerSettings.psd1"):
    with open(path, "rb") as f:
        data = f.read()
    if any(b > 127 for b in data):
        line = next(i for i, l in enumerate(data.split(b"\n"), 1) if any(b > 127 for b in l))
        err(f"{path}:{line}: non-ASCII character")
    else:
        ok(f"{path} is ASCII")

# 5. The script keeps its promise: no network, no file or registry writes, no tasks, no iex
forbidden = (r"Invoke-WebRequest|Invoke-RestMethod|\biwr\b|\birm\b|\bcurl\b|\bwget\b|Net\.WebClient|Start-BitsTransfer|"
             r"Set-Content|Add-Content|Out-File|New-Item|Set-ItemProperty|New-ItemProperty|Remove-Item|"
             r"Register-ScheduledTask|\bschtasks\b|\breg(\.exe)?\s+(add|delete)|Invoke-Expression|\biex\b|Start-Process")
hits = sorted({m.group(0) for m in re.finditer(forbidden, src)})
if hits:
    err(f"{SRC} uses commands the README says it does not: {hits}")
else:
    ok(f"{SRC} has no network, file, registry, scheduled-task or Invoke-Expression commands")

# 6. No pipe-to-shell in code blocks
docs = ["README.md", "SECURITY.md"] + sorted(glob.glob("docs/*.md"))
pipe = re.compile(r"\|\s*(iex|Invoke-Expression|(sudo\s+)?(ba|z)?sh)\b|Invoke-Expression|\biex\b", re.I)
piped = []
for md in docs:
    for fence in re.findall(r"```[a-z]*\n(.*?)```", read(md), re.S):
        for line in fence.split("\n"):
            if pipe.search(line):
                piped.append(f"{md}: {line.strip()}")
if piped:
    for p in piped:
        err(f"pipe-to-shell in a code block: {p}")
else:
    ok("no pipe-to-shell or Invoke-Expression in code blocks")

# 7. Links, anchors and images
def slug(heading):
    text = re.sub(r"`", "", heading).strip().lower()
    text = re.sub(r"[^a-z0-9 _-]", "", text)
    return text.replace(" ", "-")

def anchors(path):
    return {slug(h) for h in re.findall(r"^#{1,6}\s+(.*?)\s*$", read(path), re.M)}

external = set()
for md in docs:
    text = read(md)
    base = os.path.dirname(md)
    for target in re.findall(r"\]\(([^)\s]+)\)", text):
        if re.match(r"https?:", target):
            external.add(target)
            continue
        if re.match(r"[a-z]+:", target):
            continue
        file_part, _, frag = target.partition("#")
        path = os.path.normpath(os.path.join(base, file_part)) if file_part else md
        if not os.path.exists(path):
            err(f"{md}: broken link {target}")
        elif frag and path.endswith(".md") and frag not in anchors(path):
            err(f"{md}: no heading for anchor {target}")
for img in re.findall(r'src="([^"]+)"', readme):
    if re.match(r"https?:", img):
        continue
    if not os.path.exists(img):
        err(f"README.md: missing image {img}")

# Links to this repo's own files on GitHub must point at files that exist
own = re.compile(rf"github\.com/{re.escape(REPO)}/(?:blob|tree)/main/([^)\s\"#]+)")
scan = docs + sorted(glob.glob(".github/ISSUE_TEMPLATE/*.yml")) + [SRC]
for path in scan:
    for rel in own.findall(read(path)):
        if not os.path.exists(rel.rstrip("/")):
            err(f"{path}: links to {rel}, which is not in the repo")
if not bad:
    ok("required files, links, anchors and images")

# 8. Optional: links to other sites
if EXTERNAL:
    urls = sorted(external | {u for p in scan for u in re.findall(r"https?://[^\s)\"'>]+", read(p))})
    skip = re.compile(rf"github\.com/{re.escape(REPO)}|img\.shields\.io|github\.com/ysskrishna|linkedin\.com|ysskrishna\.space")
    checked = 0
    for url in urls:
        url = url.rstrip(".,;")
        if skip.search(url) or "<" in url or "{" in url:
            continue
        checked += 1
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (link check)"})
            with urllib.request.urlopen(req, timeout=20) as r:
                if r.status >= 400:
                    err(f"{url}: HTTP {r.status}")
        except urllib.error.HTTPError as e:
            if e.code in (403, 429):
                warn(f"{url}: HTTP {e.code} (site refuses automated requests)")
            else:
                err(f"{url}: HTTP {e.code}")
        except Exception as e:
            err(f"{url}: {e}")
    ok(f"checked {checked} external links")

sys.exit(bad)
EOF
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "VALIDATION FAILED"
    exit 1
fi
echo "All checks passed."

# Security policy

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Report it privately through GitHub: open the [Security tab](https://github.com/ysskrishna/keep-windows-awake/security) and choose **Report a vulnerability**. Include what you found, how to reproduce it, and your Windows and PowerShell versions (`$PSVersionTable.PSVersion`).

You can expect a first reply within 7 days. If the report is confirmed, the fix ships in a new release and the CHANGELOG credits you unless you ask not to be named.

## Supported versions

Only the latest release gets fixes.

## What counts

This repo ships one PowerShell script, some docs, and CI workflows. Examples of in-scope reports:

- The script does something its documentation says it does not: it touches the network, writes a file, changes the registry, or leaves a wake request running after it stops.
- A value passed to `-t` or `-w` that makes the script run a command or behave unsafely.
- A workflow or script in `.github/` or `scripts/` that can be abused, for example to publish a release from an untrusted change.
- A release file whose SHA-256 does not match the published checksum.

The script does not defeat locks, Group Policy or other IT controls, and does not try to. It only asks Windows not to sleep. A report that it fails to stop a policy-driven lock is not a vulnerability. See [docs/methods.md](docs/methods.md) for what it cannot do.

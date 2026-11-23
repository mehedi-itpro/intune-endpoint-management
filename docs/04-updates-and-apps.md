# 04 - Windows updates and apps

## Windows updates

Three update rings, one for each ring group. The definitions are in `policies/update-ring-*.json`. Create them with `scripts/03-New-UpdateRings.ps1`, then assign each one to its group.

| Ring | Group | Quality update delay | Deadline |
|---|---|---|---|
| Ring 0 | `INT-DEV-Ring0-Pilot` | 0 days | 2 days |
| Ring 1 | `INT-DEV-Ring1-Early` | 3 days | 3 days |
| Ring 2 | `INT-DEV-Ring2-Broad` | 7 days | 5 days |

Users cannot pause updates. A deadline forces the restart after a short grace period.

**Monthly plan** (Patch Tuesday is the second Tuesday):

- Day 0: Ring 0 installs, IT watches
- Day 3: Ring 1 installs if Ring 0 was clean
- Day 7: Ring 2 installs
- Day 12: Ring 2 deadline, report on PCs still behind

If a ring shows a problem, **pause** the later rings first, then investigate.

**Feature updates:** use a Feature update policy to pin the Windows version. Move the pin one ring per week.

**Emergencies:** use an Expedited quality update policy, still starting with Ring 0.

**Project sites with slow internet:** set Delivery Optimization to LAN or Group mode so PCs share downloads inside the site.

Check the property names in the JSON against the current Microsoft Graph reference before you run the script.

## Apps

| Software | App type |
|---|---|
| Microsoft 365 Apps, Edge | Built-in app types |
| Company Portal, store apps | Microsoft Store app (new) |
| Everything else | Win32 app (`.intunewin`) |

**Win32 steps:**

1. Copy `apps/_template`, add the installer, edit `Install.ps1`, `Uninstall.ps1` and `Detect.ps1`.
2. Package: `IntuneWinAppUtil.exe -c <source> -s Install.ps1 -o <output>`
3. Upload in Intune > Apps > Windows. Install command: `powershell.exe -ExecutionPolicy Bypass -File .\Install.ps1`. Install behaviour: System.
4. Detect by **version** (`>=`), not just "file exists", so upgrades are detected.
5. Test the installer as SYSTEM on a test PC first (for example with PsExec `-s`).

Assign Required apps to Ring 0, then Ring 1, then Ring 2. Use supersedence to replace an old version.

If an install fails, check `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` on the PC (`AppWorkload.log`). Usual causes: wrong silent switch, installer needs a user session, detection never matches.

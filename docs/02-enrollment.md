# 02 - Enrollment

## New PCs: Autopilot

1. **Register the PC.** Best: ask the reseller to register it in your tenant. Otherwise run this on the PC:
   ```powershell
   Install-Script -Name Get-WindowsAutopilotInfo
   Get-WindowsAutopilotInfo -Online -GroupTag "HO"
   ```
   Use the group tag for the site (`HO`, `SITE-A`).
2. **Deployment profile:** user-driven, Entra join, user is a **standard user**, device name `PC-%SERIAL%` (15 character limit), assigned to `INT-DEV-Autopilot`.
3. **Enrollment Status Page:** block the user until required apps are installed, but keep that list short: Company Portal, Microsoft 365 Apps, the security tool. A long list means a very slow first sign-in on a weak site link. Set a 60 minute timeout.

Flow: user signs in, Autopilot joins Entra and enrolls in Intune, policies and apps apply, BitLocker starts silently, the user reaches the desktop. Time it in your pilot and write down the real number.

## Existing PCs

| Today | What to do |
|---|---|
| Can be reset | Wipe and re-provision with Autopilot (cleanest) |
| Must stay domain joined | Hybrid join and auto-enroll |
| Windows 10 or no TPM 2.0 | Upgrade or replace first |

Order of work:

1. Export an inventory first (model, serial, OS, TPM, disk, user).
2. Fix blockers: old Windows, no TPM, full disks.
3. Wave 0: IT PCs. Wave 1: one PC per site. Then 20 to 30 PCs per week, one site at a time.
4. Before any wipe, make sure OneDrive Known Folder Move has finished syncing. A wipe cannot be undone.
5. Tell users two days before, and again on the day.

## Reuse and disposal

- New user for a laptop: **Autopilot Reset**.
- Device leaving the company: wipe, then delete it from Intune, Autopilot **and** Entra. Leftover records cause confusing problems.

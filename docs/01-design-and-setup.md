# 01 - Design and setup

## The situation

About 150 Windows PCs. A head office and several project sites. A small IT team. Today most work is done by hand: software is installed PC by PC, updates depend on users, and nobody has one clear list of what is encrypted or patched.

## Assumptions

- Windows 11 PCs, about 150 users
- Microsoft 365 Business Premium (or E3/E5), which includes Intune and Entra ID P1
- PCs are **Entra joined** and enrolled with Autopilot
- Users are standard users, not local admins
- Windows only

If you still depend on on-premises Active Directory, use **hybrid join** first and move workloads to Intune step by step. Compliance, BitLocker, updates, apps and wipe in this repo work either way.

## Tenant setup (do this first)

1. **Break-glass accounts.** Two cloud-only admin accounts, long passwords kept offline, excluded from every Conditional Access policy, with an alert on sign-in.
2. **Separate admin accounts** from daily accounts.
3. **Enrollment.** Set the MDM user scope, and block personal Windows devices if you only want company PCs.
4. **Windows Hello for Business.** Turn it on, PIN length 6 or more, TPM required.
5. **Company Portal.** Add the real helpdesk contact. Users see it when something fails.
6. **Windows LAPS.** Create an Account protection policy: store the local admin password in Entra, rotate every 30 days, 14+ characters.

## Roles

| Who | Role |
|---|---|
| IT lead | Intune Administrator |
| Support staff | Help Desk Operator (sync and lock, no policy edits) |
| Policy owner | Policy and Profile Manager |
| Management / audit | Read Only Operator |

## Groups and rings

Never assign a new policy straight to "All devices". Roll it out in rings. Create the groups with `scripts/01-New-IntuneGroups.ps1`.

| Group | Purpose |
|---|---|
| `INT-DEV-Windows-All` | All managed Windows PCs (dynamic) |
| `INT-DEV-Autopilot` | Autopilot-registered PCs (dynamic) |
| `INT-DEV-Ring0-Pilot` | IT team PCs, about 5 |
| `INT-DEV-Ring1-Early` | About 15 PCs, at least one from every site |
| `INT-DEV-Ring2-Broad` | Everyone else, about 130 |
| `INT-DEV-Exclude-Policies` | Emergency exclusion. Keep it empty |

A PC must be in only one ring, or it gets two update rings and a conflict.

## Naming

`<Platform>-<Type>-<Scope>-<Purpose>-v<N>`, for example `WIN-CMP-All-Baseline-v1`.

Do not edit a live policy. Clone it as `v2`, assign it to Ring 0, check, then move on to Ring 1 and Ring 2.

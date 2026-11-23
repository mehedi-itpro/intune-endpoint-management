# 05 - Inventory, operations and rollout plan

## Inventory

`scripts/04-Export-DeviceInventory.ps1` writes a CSV (name, user, model, serial, OS version, compliance, encryption, last sync, storage) and prints a short summary: non-compliant, not encrypted, stale.

```powershell
.\scripts\04-Export-DeviceInventory.ps1 -StaleDays 30
```

Output goes to `output/`, which git ignores. It has serial numbers and user names, so never commit it.

## Routine

| When | What |
|---|---|
| Daily | Check Intune home for failing policies and apps, and Entra sign-in logs for Conditional Access failures |
| Weekly | Run the inventory. Check stale PCs, non-compliant PCs and apps that failed. Run the BitLocker key report; it should be empty |
| Monthly | Patch cycle, review group members and admin roles, check break-glass sign-ins (should be none), export a copy of the Intune config |
| Quarterly | Raise the minimum OS, move clean ASR rules to block, test a wipe and a BitLocker recovery on a lab PC |

## Targets

These are goals, not results.

| Measure | Target |
|---|---|
| PCs enrolled | 100 percent |
| Compliant | 95 percent or more |
| Recovery keys saved | 100 percent |
| On the current update | 95 percent |
| Stale for over 30 days | None |

## Rollout plan

| Week | Step |
|---|---|
| 0 | Tenant setup, groups, inventory, list blockers |
| 1 | Ring 0 (IT). Test a wipe and a key recovery |
| 2-3 | Ring 1 (about 15 PCs, all sites). Conditional Access in report-only |
| 4-6 | Ring 2 in waves of 20 to 30 PCs |
| 7 | Compliance 95 percent or more, then turn Conditional Access on |
| 8 | Hand over to the routine above |

Move to the next step only when the last one is clean. If it is not, repeat it.

## Rollback

| Area | How |
|---|---|
| Policy | Unassign it from the group |
| Compliance or Conditional Access | Set Conditional Access to report-only first, then fix |
| Updates | Pause the ring, or pin the older version |
| App | Assign the uninstall, or supersede with the old version |
| BitLocker | No clean undo. Fix the policy for PCs not yet encrypted |

Emergency stopgap: add the affected PCs to `INT-DEV-Exclude-Policies`, then fix the policy as `v2`.

Intune has no one-click backup. Export policies as JSON on a schedule (for example with the IntuneBackupAndRestore PowerShell module) into a **private** repo, never a public one.

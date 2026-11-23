# 06 - Lost device and remote wipe

Write this down before you need it.

## Which action?

| Situation | Action |
|---|---|
| Lost or stolen company laptop | **Wipe** |
| Employee leaves, laptop returned | **Wipe**, then Autopilot Reset for the next user |
| Laptop goes to another user | **Autopilot Reset** |
| Personal device, only company data should go | **Retire** |
| Suspected compromise, PC still in hand | Isolate it and collect diagnostics before reinstalling |

Retire is not enough for a lost company laptop. It leaves user data on the disk.

## Lost or stolen: steps

1. **Open a ticket.** Who, which device, when and where it was last seen.
2. **Secure the account first.** It is faster than the device. Reset the password, revoke sign-in sessions, check recent sign-ins.
3. **Wipe.** The IT lead or the user's manager approves in the ticket.
   ```powershell
   .\scripts\06-Invoke-DeviceAction.ps1 -DeviceName PC-0042 -Action Wipe -Reason "Lost, ticket 1234" -WhatIf
   ```
   Run it with `-WhatIf` first to check the right device is found, then run it again without. The script needs a reason and writes a line to `output/device-actions.log`.
4. **Wipe is queued.** If the PC is offline, it wipes the next time it connects. "Wipe pending" is not "wiped". Say that in the ticket.
5. **Confirm** in Intune that the wipe completed.
6. **Clean up.** Delete the device from Intune, Autopilot and Entra once the wipe is confirmed.

## Other actions

Sync (force check-in), remote lock, rotate BitLocker keys, collect diagnostics, run a Defender scan.

## Controls

- Only named roles can wipe. The helpdesk role can sync and lock.
- Review the action log and the Intune audit log every month.
- Test a wipe on a lab PC once a year, and time it from report to confirmed.

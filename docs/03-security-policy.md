# 03 - Security policy, compliance and BitLocker

## Policy set

Keep it small. Every extra policy can conflict with another one.

| Policy | Where in Intune | Main settings |
|---|---|---|
| `WIN-SEC-All-Defender-v1` | Endpoint security > Antivirus | Real-time and cloud protection on, PUA protection on |
| `WIN-SEC-All-Firewall-v1` | Endpoint security > Firewall | All profiles on, inbound blocked by default |
| `WIN-SEC-All-ASR-v1` | Endpoint security > Attack surface reduction | **Audit** for two weeks, then block selected rules |
| `WIN-SEC-All-BitLocker-v1` | Endpoint security > Disk encryption | See below |
| `WIN-SEC-All-LAPS-v1` | Endpoint security > Account protection | See [01](01-design-and-setup.md) |
| `WIN-CFG-All-OneDriveKFM-v1` | Settings catalog | Move Desktop, Documents, Pictures to OneDrive silently |
| `WIN-CFG-All-EdgeBaseline-v1` | Settings catalog | SmartScreen on, extension allow-list |
| `WIN-CMP-All-Baseline-v1` | Compliance | See below |

Order: Defender, firewall, LAPS, BitLocker and OneDrive first (low user impact). Edge settings next. ASR rules last, and only after reading the audit data. Turn on Tamper protection in the Defender portal.

Compare with Microsoft's Windows security baseline, but do not deploy it blindly. Assign it to Ring 0 first and read what it changes.

## Compliance

The baseline is in [`policies/compliance-windows-baseline.json`](../policies/compliance-windows-baseline.json). It requires:

- BitLocker on, Secure Boot, code integrity, TPM
- Firewall on, Defender on with real-time protection and current signatures
- Windows 11 24H2 or newer (raise this over time)

No password rules. Windows Hello replaces them on Entra joined PCs.

Non-compliant devices are marked immediately. After a 72-hour grace period, Conditional Access blocks access to company apps. Add an email notification template in the portal.

## Conditional Access

Policy `CA-All-RequireCompliantDevice-M365`: all users, Office 365, Windows, require compliant device. Exclude the break-glass accounts.

Rollout:

1. Assign the compliance policy to Ring 0, then 1, then 2. Wait until 95 percent or more are compliant.
2. Create the CA policy in **Report-only** mode for two weeks. Read the sign-in logs.
3. Fix what would have failed (missing TPM, old build, PC that never checks in).
4. Switch it on.

Turn on "Mark devices with no compliance policy as not compliant" only after the baseline reaches every ring.

## BitLocker

Policy `WIN-SEC-All-BitLocker-v1`:

| Setting | Value |
|---|---|
| Require device encryption | On |
| Warning for other disk encryption | **Off** (needed for silent encryption) |
| Standard users can enable encryption in Autopilot | On |
| Method | XTS-AES 256 |
| Save recovery key to Entra ID | On, and do not encrypt until it is saved |
| Startup | TPM only (add PIN only for high-risk laptops) |

Needs: TPM 2.0, UEFI with Secure Boot, WinRE enabled (`reagentc /info`).

Check a PC with `manage-bde -status C:`. Check the fleet with the Intune Encryption report and `scripts/05-Get-BitLockerEscrowReport.ps1`, weekly. Any device it lists has no recoverable key.

**When a user is locked out:**

1. Confirm who they are by callback or manager, not by the locked PC.
2. Find the key in Intune or Entra (Devices > the device > Recovery keys). Match the Key ID on the user's screen.
3. Read it out by phone. Never email or chat it.
4. Rotate the key afterwards: `scripts/06-Invoke-DeviceAction.ps1 -DeviceName <name> -Action RotateBitLockerKeys`.

Only helpdesk roles should be able to read keys. Reads are audit-logged. There is no clean undo for BitLocker, so test on Ring 0 first.

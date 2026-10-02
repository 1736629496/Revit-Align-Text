# Align Text to Line — Revit 2020 Add-in

Moves text notes (TextNote) onto a reference line, perpendicular to it.

![Ribbon panel](docs/images/ribbon-panel.png)

---

## Install

1. **Exit Revit completely** — check Task Manager, no `Revit.exe` may remain.
   Revit only scans the add-in folder at startup.
2. **Copy both files** into:

   ```
   %APPDATA%\Autodesk\Revit\Addins\2020\
   ```
3. **Start Revit.**

That folder is normally:

```
C:\Users\<your username>\AppData\Roaming\Autodesk\Revit\Addins\2020\
```

> Both files must be in the same folder — the `.addin` refers to the assembly by
> relative path. Do **not** copy `RevitAPI.dll` / `RevitAPIUI.dll` in; Revit
> provides those itself.

You should now see a **Text Tools** tab on the Ribbon with two buttons in it.

---

## The two workflows

| Button | Use it for | How it works |
|---|---|---|
| **Align Text (Batch)** | A batch of text against a few lines | One mixed selection → press `Enter` → everything aligns at once |
| **Align Text (Click)** | Long jobs, frequent line changes | One click per item; click a different line at any time to switch the reference |

These are two parallel features. Use whichever fits the job.

---

## Documentation

**[User Guide (English)](docs/UserGuide.md)** — behaviour rules, message reference,
troubleshooting, uninstall.

**[用户使用说明（中文）](docs/UserGuide.zh-CN.md)**

---

## Requirements

- Revit **2020** (other versions untested)
- 64-bit Windows

---

## Troubleshooting the install

If the `Text Tools` tab does not appear, run the bundled diagnostic script from the
same folder as the add-in files:

```powershell
powershell -ExecutionPolicy Bypass -File .\diagnose.ps1
```

It writes `diagnose_out.txt` covering the file fingerprint, bitness, `.addin`
resolution, journal load records and signature status. Include that file when
reporting a problem.

For day-to-day diagnosis the plugin writes its own log to:

```
%LOCALAPPDATA%\RevitTextAlignment\align.log
```

---

## Uninstall

1. Exit Revit completely
2. Delete `RevitTextAlignment.dll` and `RevitTextAlignment.addin` from
   `%APPDATA%\Autodesk\Revit\Addins\2020\`
3. Optionally delete `%LOCALAPPDATA%\RevitTextAlignment\` and
   `%LOCALAPPDATA%\RevitTextAlignment.State\`

---

## Notes

This is a trial build. It stops working after the trial period.
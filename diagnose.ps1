# Revit add-in load diagnostic — run this on the machine that has Revit
#
# Usage: put this file together with RevitTextAlignment.dll and
#   RevitTextAlignment.addin, then:
#   powershell -ExecutionPolicy Bypass -File diagnose.ps1
# The result is written to diagnose_out.txt in the same folder — send that back.
#
# Read-only: nothing is modified.

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out  = Join-Path $here 'diagnose_out.txt'

$lines = New-Object System.Collections.Generic.List[string]
function W($s) { $lines.Add([string]$s); Write-Host $s }

# ★ Must be defined BEFORE it is used. A previous version used it ~50 lines
#   above its definition, which in PowerShell means $null — the loop silently
#   did nothing and the Addins check reported nothing at all.
$addinDirs = @(
    (Join-Path $env:APPDATA 'Autodesk\Revit\Addins\2020'),
    (Join-Path $env:ProgramData 'Autodesk\Revit\Addins\2020'),
    (Join-Path $env:ProgramFiles 'Autodesk\Revit 2020\AddIns')
)

# The DLL Revit actually loads: this folder if present, otherwise the copy
# found in an Addins folder (that is the one Revit really loads).
$cur = Join-Path $here 'RevitTextAlignment.dll'
if (-not (Test-Path $cur)) {
    foreach ($d in $addinDirs) {
        $cand = Join-Path $d 'RevitTextAlignment.dll'
        if (Test-Path $cand) { $cur = $cand; break }
    }
}

W "==================== Revit Add-in Load Diagnostic ===================="
W "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "Machine: $env:COMPUTERNAME  User: $env:USERNAME"
W "Script folder: $here"
W ""

# ------------------------------------------------------------ 1. file fingerprint
W "---------------- 1. Add-in files in this folder ----------------"
foreach ($f in @('RevitTextAlignment.dll', 'RevitTextAlignment.addin')) {
    $p = Join-Path $here $f
    if (Test-Path $p) {
        $fi = Get-Item $p
        $md5 = (Get-FileHash $p -Algorithm MD5).Hash
        W ("  {0}  {1} bytes  MD5={2}  modified {3}" -f `
            $fi.Name, $fi.Length, $md5, $fi.LastWriteTime)
    } else {
        W "  $f -- MISSING"
    }
}
W ""

# Compare against the expected build (2026-10-03 01:11)
$expect = '18B20B552219DE07C3279A5870614AC7'
function Show-Md5($path, $label) {
    if (Test-Path $path) {
        $h = (Get-FileHash $path -Algorithm MD5).Hash
        $same = if ($h -eq $expect) { 'matches the released build' }
                else { 'DOES NOT match -- this copy is stale or damaged, please re-copy' }
        W "  $label MD5=$h => $same"
        if ($h -ne $expect) { W "     expected: $expect" }
    } else {
        W "  $label -- not present"
    }
}
Show-Md5(Join-Path $here 'RevitTextAlignment.dll') 'this folder:'
foreach ($d in $addinDirs) {
    Show-Md5 (Join-Path $d 'RevitTextAlignment.dll') 'addins     :'
}
W ""

# ------------------------------------------------------------ 2. assembly / bitness
W "---------------- 2. Assembly and bitness ----------------"
if ($cur -and (Test-Path $cur)) {
    W "  checking: $cur"
    try {
        $an = [System.Reflection.AssemblyName]::GetAssemblyName($cur)
        W "  name: $($an.FullName)"
    } catch {
        W "  could not read the assembly name: $($_.Exception.Message)"
    }
    try {
        $pe = [System.IO.File]::ReadAllBytes($cur)
        $peOff = [BitConverter]::ToInt32($pe, 0x3C)
        $machine = [BitConverter]::ToUInt16($pe, $peOff + 4)
        $is64 = ($machine -eq 0x8664)
        W ("  PE machine: 0x{0:X4} ({1})" -f $machine, $(if ($is64) { 'x64' } else { 'not x64' }))
        if (-not $is64) {
            W "  => PROBLEM: Revit 2020 is 64-bit; a 32-bit DLL cannot load"
        } else {
            W "  => bitness OK"
        }
    } catch {
        W "  could not read the PE header: $($_.Exception.Message)"
    }
} else {
    W "  skipped: no DLL found (see section 3 for the Addins locations)"
}
W ""

# ------------------------------------------------------------ 3. Addins locations
W "---------------- 3. Copies inside the Addins folders ----------------"
$found = $false
foreach ($d in $addinDirs) {
    if (-not (Test-Path $d)) { W "  [does not exist] $d"; continue }
    W "  [exists] $d"
    $items = Get-ChildItem -Path $d -Filter 'RevitTextAlignment.*' -ErrorAction SilentlyContinue
    if (-not $items) { W "      (no RevitTextAlignment.* in here)" }
    foreach ($i in $items) {
        $found = $true
        $line = "      -> {0}  {1} bytes  {2}" -f $i.Name, $i.Length, $i.LastWriteTime
        if ($i.Extension -eq '.dll') {
            $line += "  MD5=" + (Get-FileHash $i.FullName -Algorithm MD5).Hash
        }
        W $line
    }
}
W ""
if (-not $found) {
    W "  => KEY FINDING: the plugin is in none of the three standard locations."
    W "     Revit only loads add-ins from its Addins folder. Dropping the DLL"
    W "     into an arbitrary folder does nothing."
}
W ""

# ------------------------------------------------------------ 4. .addin manifest
W "---------------- 4. The .addin manifests Revit reads ----------------"
$addinFiles = @()
foreach ($d in $addinDirs) {
    if (Test-Path $d) {
        $addinFiles += Get-ChildItem -Path $d -Filter '*.addin' -ErrorAction SilentlyContinue
    }
}
if ($addinFiles.Count -eq 0) {
    W "  no .addin files found"
} else {
    foreach ($af in $addinFiles) {
        $c = Get-Content $af.FullName -Raw -Encoding UTF8
        if ($c -match 'RevitTextAlignment') {
            W "  >>> related to this add-in: $($af.FullName)"
            W ($c.Trim())
            W ""
            # The Assembly path must resolve to a file that exists.
            if ($c -match '<Assembly>\s*([^<\s]+)\s*</Assembly>') {
                $asm = $Matches[1]
                $resolved = Join-Path $af.DirectoryName $asm
                W "  Assembly declared: $asm"
                W "  resolves to     : $resolved"
                if (Test-Path $resolved) {
                    W "  => file exists"
                } else {
                    W "  => PROBLEM: the Assembly path points at a file that does not exist!"
                }
            }
            # FullClassName must match a type inside the DLL.
            if ($c -match '<FullClassName>\s*([^<\s]+)\s*</FullClassName>') {
                W "  FullClassName: $($Matches[1])"
            }
            W ""
        }
    }
}
W ""

# ------------------------------------------------------------ 5. startup_error.log
W "---------------- 5. startup_error.log (OnStartup threw) ----------------"
# Two different folders. The licence state folder name is a masked constant
# whose real value is "RevitTextAlignment.State"; the run log uses the plain
# "RevitTextAlignment". Checking only the plain one produces a false
# "log does not exist" conclusion and throws away the only evidence.
$stateDirs = @(
    (Join-Path $env:LOCALAPPDATA 'RevitTextAlignment'),
    (Join-Path $env:LOCALAPPDATA 'RevitTextAlignment.State')
)
$seFound = $false
foreach ($sd in $stateDirs) {
    $se = Join-Path $sd 'startup_error.log'
    if (Test-Path $se) {
        $seFound = $true
        W "  >>> found: $se"
        Get-Content $se -Encoding UTF8 | ForEach-Object { W "    $_" }
        W ""
    } else {
        W "  [none] $se"
    }
}
if ($seFound) {
    W "  => the log has content: OnStartup ran and threw; the exception above is the reason"
} else {
    W "  => no startup_error.log in either folder"
    W "     if the journal shows API_ERROR, OnStartup was called but could not write"
    W "     the log -- the throw is probably in type loading or static init"
    W "     (which try/catch cannot intercept). Read section 6."
    W "     if the journal says nothing at all, the load was rejected before OnStartup;"
    W "     check the signature, the bitness and the .addin path."
}
W ""

# ------------------------------------------------------------ 6. the journal
W "---------------- 6. Load records in the Revit journal ----------------"
$jroot = Join-Path $env:LOCALAPPDATA 'Autodesk\Revit'
$journals = @()
if (Test-Path $jroot) {
    $journals = Get-ChildItem -Path $jroot -Filter 'journal*.txt' -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 3
}
if ($journals.Count -eq 0) {
    W "  no journal files found (Revit has not run, or it ran under another user account)"
    W "  expected path: %LOCALAPPDATA%\Autodesk\Revit\Autodesk Revit 2020\Journals\journal.1.txt"
} else {
    foreach ($j in $journals) {
        W "  >>> $($j.FullName)  ($($j.LastWriteTime))"
        $lines2 = @(Get-Content $j.FullName -ErrorAction SilentlyContinue)
        $hit = $lines2 | Select-String -Pattern 'RevitTextAlignment|RTA'
        if (-not $hit) {
            W "      (no mention of RevitTextAlignment anywhere -- Revit never even tried)"
        } else {
            foreach ($h in $hit) { W "      $($h.Line.Trim())" }
        }

        # KEY: 25 lines of context around every API_ERROR. Revit writes the real
        # load exception here (assembly resolution failure, type not found, and
        # so on). Grepping only for the keyword misses it.
        $errIdx = @()
        for ($i = 0; $i -lt $lines2.Count; $i++) {
            if ($lines2[$i] -match 'API_ERROR.*RevitTextAlignment') { $errIdx += $i }
        }
        if ($errIdx.Count -gt 0) {
            W "      ===== context around API_ERROR (25 lines either side) ====="
            $seen = @{}
            foreach ($i in $errIdx) {
                $from = [Math]::Max(0, $i - 25)
                $to   = [Math]::Min($lines2.Count - 1, $i + 25)
                for ($k = $from; $k -le $to; $k++) {
                    if ($seen.ContainsKey($k)) { continue }
                    $seen[$k] = $true
                    $mark = if ($k -eq $i) { '>>>' } else { '   ' }
                    W "      $mark $($lines2[$k].Trim())"
                }
            }
            W "      ===== end of context ====="
        } else {
            W "      (no API_ERROR entry in this journal)"
        }

        # Also pull out anything load-failure or exception related.
        W "      --- load failure / exception lines ---"
        $err = $lines2 | Select-String -Pattern 'Failed to load|Could not load|LoadException|FileNotFound|BadImageFormat|does not exist|not trusted|Exception' |
               Select-Object -First 25
        if ($err) { foreach ($e in $err) { W "      $($e.Line.Trim())" } }
        else { W "      (nothing matched)" }
        W ""
    }
}
W ""

# ------------------------------------------------------------ 7. Authenticode
W "---------------- 7. Authenticode signature ----------------"
if ($cur -and (Test-Path $cur)) {
    try {
        $sig = Get-AuthenticodeSignature $cur -ErrorAction Stop
        W "  file: $cur"
        W "  Status: $($sig.Status)"
        W "  what it means:"
        W "    Valid          = trusted signature, fine"
        W "    NotSigned      = unsigned, which is expected for this build"
        W "    UnknownError   = usually a SELF-SIGNED certificate. Revit rejects"
        W "                     those at load time without showing any prompt!"
        if ($sig.SignerCertificate) {
            W "  issuer : $($sig.SignerCertificate.Issuer)"
            W "  subject: $($sig.SignerCertificate.Subject)"
            if ($sig.SignerCertificate.Issuer -eq $sig.SignerCertificate.Subject) {
                W "  => PROBLEM: issuer == subject, so this is self-signed."
                W "     Revit's add-in loader requires a trusted chain and rejects"
                W "     self-signed DLLs outright; the symptom is that the Ribbon"
                W "     panel simply never appears."
            }
        } else {
            W "  issuer : (none -- the file is unsigned)"
        }
    } catch {
        W "  signature check failed: $($_.Exception.Message)"
    }
} else {
    W "  skipped: no DLL to inspect"
}
W ""

# ------------------------------------------------------------ 8. dependency DLLs
W "---------------- 8. Dependency DLLs ----------------"
if ($cur -and (Test-Path $cur)) {
    W "  checking: $cur"
    W "  references RevitAPI.dll / RevitAPIUI.dll, which the Revit host provides;"
    W "  they must NOT be shipped alongside the add-in."
    $copied = @()
    foreach ($d in $addinDirs) {
        if (Test-Path $d) {
            foreach ($n in @('RevitAPI.dll', 'RevitAPIUI.dll')) {
                if (Test-Path (Join-Path $d $n)) { $copied += (Join-Path $d $n) }
            }
        }
    }
    if ($copied.Count -gt 0) {
        W "  => PROBLEM: host API copies sit in the Addins folder; a version mismatch"
        W "     causes a load failure. Delete these:"
        foreach ($c in $copied) { W "     $c" }
    } else {
        W "  => no RevitAPI copies in the Addins folder, correct"
    }
} else {
    W "  skipped: no DLL found"
}
W ""

# ------------------------------------------------------------ 9. other add-ins
W "---------------- 9. Other add-ins present (noise check) ----------------"
$allAddins = @()
foreach ($d in $addinDirs) {
    if (Test-Path $d) { $allAddins += Get-ChildItem -Path $d -Filter '*.addin' -ErrorAction SilentlyContinue }
}
W "  $($allAddins.Count) .addin file(s) total"
W ""

W "==================== diagnostic complete ===================="
W "Send diagnose_out.txt back to the developer."

$lines | Out-File $out -Encoding UTF8
Write-Host ""
Write-Host "Result written to: $out"
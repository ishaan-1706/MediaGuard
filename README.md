# MediaGuard — File Integrity Monitor

**Purpose**: Automatically detect when files in your folders are added, deleted, or modified. Creates an immutable baseline for comparison and reports changes weekly via Task Scheduler.

---

## 🔐 Privacy & Security

**This is the PUBLIC template version.** It does NOT contain any personal folder names or sensitive paths—only example placeholders.

- ✓ **Safe to publish on GitHub**
- ✓ All folder paths are generic examples
- ✓ Ready to customize with your own directories

**For your personal use**, you'll create `IntegrityCheck_personal.ps1` with your actual folder paths (this file is in `.gitignore` and never committed to GitHub).

See [SETUP.md](SETUP.md) for configuration instructions.

---

## 📋 Table of Contents

1. [What It Does](#what-it-does)
2. [How It Works](#how-it-works)
3. [Installation & Setup](#installation--setup)
4. [Usage](#usage)
5. [Understanding the Results](#understanding-the-results)
6. [File Structure](#file-structure)
7. [Adding More Directories](#adding-more-directories)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 What It Does

This script monitors 17 media formats across multiple directories and:

✓ **Creates a baseline** — Records SHA256 hashes of all files on first run  
✓ **Detects changes** — Compares future scans against the immutable baseline  
✓ **Reports issues** — Lists deleted, modified, and newly added files  
✓ **Generates summaries** — Creates one easy-to-read summary file per scan  
✓ **Maintains history** — Keeps timestamped snapshots for audit trails  
✓ **Runs automatically** — Integrates with Windows Task Scheduler  

### Supported File Types

**Images**: JPG, JPEG, PNG, GIF, BMP, TIFF, TIF, HEIC, WebP  
**Videos**: MP4, MKV, AVI, MOV, FLV, WMV, WebM  
**Documents**: DOCX, PDF, PPTX, TXT, XLS, XLSX, DOC, ODT, ODS, ODP

---

## 🔍 How It Works

### The Baseline Concept

Think of the baseline as a "gold standard" snapshot:

1. **First run** → Script hashes all media files → Creates `hashes_baseline.csv` (locked)
2. **Future runs** → Script hashes files again → Compares against locked baseline
3. **Result** → Reports what changed, but **never modifies the baseline**

This prevents corruption from spreading. If you accidentally delete files, the baseline stays intact as proof.

### The Two-Step Process

```
┌─────────────────────────────────────────┐
│ STEP 1: Hash All Media Files            │
│ (For each monitored directory)          │
│ • Calculate SHA256 of each file         │
│ • Save current hashes                   │
│ • Save historical snapshot              │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ STEP 2: Compare Against Baseline        │
│ • Load baseline hashes                  │
│ • Compare paths & hashes                │
│ • Generate reports                      │
│ • Create summary                        │
└─────────────────────────────────────────┘
```

---

## ⚙️ Installation & Setup

**This README describes the public template.** For detailed configuration instructions:

👉 **[See SETUP.md](SETUP.md)** for step-by-step guide to configure MediaGuard for your use.

### Quick Summary

1. Edit `IntegrityCheck.ps1` → Customize `$dirs` array with your folder paths
2. Save as `IntegrityCheck_personal.ps1` 
3. Run: `.\IntegrityCheck_personal.ps1` (first run creates baseline)
4. Optionally add to Task Scheduler for weekly automated scans

The personal version (`_personal.ps1`) is automatically excluded from git via `.gitignore`.

---

## 🚀 Usage

### Normal Scan (Compare Against Baseline)

```powershell
.\IntegrityCheck_personal.ps1
```

This runs a standard integrity check and compares against the baseline. Results go to your configured log directory.

### Reset Baseline (Start Over)

```powershell
.\IntegrityCheck_personal.ps1 -ResetBaseline
```

⚠️ **Use this if:**
- You intentionally changed files and want a new baseline
- You want to forget all previous changes and start fresh

This overwrites the old baseline with a new one.

---

## 📊 Understanding the Results

### 1. The Summary File (⭐ Start Here)

**Location**: `C:\data\integrity_logs\SUMMARY_[timestamp].txt`

**Example Output**:
```
╔════════════════════════════════════════════════════════════════╗
║          INTEGRITY SCAN SUMMARY — ONE-FILE REPORT              ║
╚════════════════════════════════════════════════════════════════╝

SCAN DATE: 2026-05-27 14:32:15
SCAN MODE: NORMAL COMPARISON

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATISTICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Total directories monitored: 18
  ✓ No issues detected:       16
  ⚠ Issues detected:          2
  🔄 Baseline resets:         0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠ DIRECTORIES WITH CHANGES/ISSUES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 C:\data\ar_trip
   Deleted/Modified: 3 file(s)
   New/Modified:     2 file(s)
   Full report:      C:\data\integrity_logs\C_data_ar_trip\integrity_report_20260527_143215.txt

📁 C:\data\australia_25_26
   Deleted/Modified: 0 file(s)
   New/Modified:     1 file(s)
   Full report:      C:\data\integrity_logs\C_data_australia_25_26\integrity_report_20260527_143215.txt
```

**How to Read It:**
- **Statistics**: Quick numbers at the top
- **Directories with issues**: Only shows folders with changes
- **Deleted/Modified**: Files that were in baseline but aren't now or have different hashes
- **New/Modified**: Files that are in current scan but weren't in baseline (new) or have different content

### 2. Detailed Reports (If You Need More Info)

**Location**: `C:\data\integrity_logs\[directory_name]\integrity_report_[timestamp].txt`

**Example:**
```
Baseline Created: 2026-05-20 10:15:30

⚠ INTEGRITY ISSUES DETECTED:

DELETED or MODIFIED (in baseline, not in current):
  [-] C:\data\ar_trip\photo_old.jpg
  [-] C:\data\ar_trip\video_edited.mp4

NEW or MODIFIED (in current, not in baseline):
  [+] C:\data\ar_trip\photo_new.jpg
  [+] C:\data\ar_trip\photo_old.jpg        ← Different hash
```

**Reading Guide:**
- `[-]` = File was deleted or modified (hash changed)
- `[+]` = File is new or file content changed

### 3. Historical Snapshots (Audit Trail)

**Location**: `C:\data\integrity_logs\[directory_name]\hashes_[timestamp].csv`

These are timestamped copies of all file hashes. Keep these for long-term audit trails.

---

## 📁 File Structure

After running the script, you'll have:

```
C:\data\
├── IntegrityCheck.ps1                    ← The script
├── README_IntegrityCheck.md              ← This file
└── integrity_logs/                       ← AUTO-CREATED
    ├── master_integrity_log.txt          ← Overall log
    ├── SUMMARY_[timestamp].txt           ← ⭐ YOUR MAIN REPORT
    │
    ├── C_data_a_d_i/                     ← One folder per directory
    │   ├── hashes_baseline.csv           ← Gold standard (locked)
    │   ├── baseline_metadata.txt         ← When baseline created
    │   ├── hashes_current.csv            ← Latest scan
    │   ├── hashes_[timestamp].csv        ← Historical snapshots
    │   └── integrity_report_[timestamp].txt
    │
    ├── C_data_ar_trip/
    │   ├── hashes_baseline.csv
    │   ├── baseline_metadata.txt
    │   └── ...
    │
    └── ... (one per directory)
```

---

## ➕ Adding More Directories

Want to monitor additional folders?

1. Open `IntegrityCheck_personal.ps1` in a text editor
2. Find the **CONFIGURATION** section, locate the `$dirs` array
3. Add your directory:
```powershell
$dirs = @(
    "C:\your\existing\path",
    "C:\your\new\path",    ← Add this line
    ...
)
```

4. Save the file
5. Run manually once: `.\IntegrityCheck_personal.ps1`
   - This creates a baseline for the new directory
6. Future runs will include it automatically

---

## 🐛 Troubleshooting

### "Access Denied" when running script

**Solution**: Run PowerShell as Administrator
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

### No summary file created

**Possible causes:**
- Script ran but hit an error mid-way
- Check `master_integrity_log.txt` for error messages
- Verify directories in the `$dirs` array actually exist

### Directory doesn't show up in summary

- Directory may not exist (check path spelling)
- Directory may have no media files (script only monitors images/videos)
- Check `master_integrity_log.txt` for "ERROR: Directory not found"

### Files show as "deleted" but they're still there

- File content was modified (hash changed)
- This is expected—hash changed = file is different
- It's not actually deleted from disk

### When should I reset the baseline?

**Reset baseline when:**
- You intentionally added files and want to establish a new baseline
- You made approved changes and don't want them flagged as "issues" anymore
- You want to forget about all previous changes and start fresh

**Reset baseline with:**
```powershell
.\IntegrityCheck.ps1 -ResetBaseline
```

⚠️ This discards the old baseline and creates a new one from current files. After reset, Task Scheduler will compare against the NEW baseline going forward.

### Task Scheduler task won't run

**Solution**:
1. Open Task Scheduler
2. Find your task, right-click → **Properties**
3. Go to **General** tab
4. Check: **Run with highest privileges**
5. Apply and OK

---

## 🔒 Safety Guarantees

✅ **Your files are never modified**  
✅ **Baseline is immutable (locked by design)**  
✅ **Baseline ONLY updates with explicit `-ResetBaseline` command**  
✅ **All writes go to `integrity_logs/` only**  
✅ **Historical snapshots always preserved**  
✅ **No data duplication**  
✅ **Handles empty/corrupt baseline files gracefully (no crashes)**  

### Why Immutable Baseline Matters

Without an immutable baseline, if files get corrupted or deleted, you lose your reference point. With this design:
- Your baseline is your "truth" — it never changes unless you explicitly reset it
- Task Scheduler can run 100 times and the baseline stays the same
- You always know exactly what changed since you last intentionally reset it
- Corruption can't spread to the baseline itself

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Run scan | `.\IntegrityCheck.ps1` |
| Reset baseline | `.\IntegrityCheck.ps1 -ResetBaseline` |
| View summary | Open `SUMMARY_*.txt` in `integrity_logs/` |
| View details | Open `integrity_report_*.txt` in directory subfolder |
| Add directory | Edit `$dirs` array in script |
| Schedule weekly | Use Windows Task Scheduler |

---

## 📅 Recommended Workflow

1. **First Run (Manual)**: `.\IntegrityCheck.ps1`
   - Creates immutable baselines for all directories
   - Generates `SUMMARY_*.txt` report

2. **Add to Task Scheduler**: Set it to run weekly automatically
   - Runs in normal mode (no `-ResetBaseline` parameter)
   - Baseline stays locked, never auto-updates
   - Compares current files against baseline
   - Generates new `SUMMARY_*.txt` each week

3. **Weekly Review**: Check `SUMMARY_*.txt` file for any changes

4. **If You Add Files Intentionally**: Run manually when ready
   ```powershell
   .\IntegrityCheck.ps1 -ResetBaseline
   ```
   - Creates new baseline with current files
   - Future weeks will compare against this new baseline

5. **If Issues Detected**: Open detailed `integrity_report_*.txt` for that directory

### Important: Baseline Behavior

- **Normal mode** (Task Scheduler): Baseline is READ-ONLY, never modified
- **Reset mode** (manual `-ResetBaseline`): Baseline is overwritten with current state
- **Key guarantee**: Without `-ResetBaseline` parameter, baseline always stays locked

---

**Last Updated**: May 20, 2026 (Tested & Verified Working)  
**Script Version**: 2.0-immutable  
**Status**: ✓ Production Ready
#   M e d i a G u a r d  
 
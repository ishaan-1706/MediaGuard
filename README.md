# MediaGuard - File Integrity Monitor

**Purpose**: Automatically detect when files in your folders are added, deleted, or modified. Creates an immutable baseline for comparison and reports changes weekly via Task Scheduler.

---

## Privacy & Security

**This is the PUBLIC template version.** It does NOT contain any personal folder names or sensitive paths—only example placeholders.

- Safe to publish on GitHub
- All folder paths are generic examples
- Ready to customize with your own directories

**For your personal use**, you'll create `IntegrityCheck_personal.ps1` with your actual folder paths (this file is in `.gitignore` and never committed to GitHub).

See [SETUP.md](SETUP.md) for configuration instructions.

---

## Table of Contents

1. [What It Does](#what-it-does)
2. [How It Works](#how-it-works)
3. [Installation & Setup](#installation--setup)
4. [Usage](#usage)
5. [Understanding Results](#understanding-results)
6. [File Structure](#file-structure)
7. [Adding More Directories](#adding-more-directories)
8. [Troubleshooting](#troubleshooting)

---

## What It Does

This script monitors 26 file types across multiple directories:

- Creates a baseline — Records SHA256 hashes of all files on first run
- Detects changes — Compares future scans against the immutable baseline
- Reports issues — Lists deleted, modified, and newly added files
- Generates summaries — Creates one easy-to-read summary file per scan
- Maintains history — Keeps timestamped snapshots for audit trails
- Runs automatically — Integrates with Windows Task Scheduler

### Supported File Types

**Images**: JPG, JPEG, PNG, GIF, BMP, TIFF, TIF, HEIC, WebP

**Videos**: MP4, MKV, AVI, MOV, FLV, WMV, WebM

**Documents**: DOCX, PDF, PPTX, TXT, XLS, XLSX, DOC, ODT, ODS, ODP

---

## How It Works

### The Baseline Concept

Think of the baseline as a "gold standard" snapshot:

1. First run: Script hashes all files and creates hashes_baseline.csv (locked)
2. Future runs: Script hashes files again and compares against locked baseline
3. Result: Reports what changed, but never modifies the baseline

This prevents corruption from spreading. If you accidentally delete files, the baseline stays intact as proof.

### The Two-Step Process

1. Hash All Files Recursively
   - For each monitored directory
   - Calculate SHA256 of each file
   - Save current hashes
   - Save historical snapshot

2. Compare Against Baseline
   - Load baseline hashes
   - Compare paths and hashes
   - Generate reports
   - Create summary

---

## Installation & Setup

**This README describes the public template.** For detailed configuration instructions, see [SETUP.md](SETUP.md).

### Quick Summary

1. Edit IntegrityCheck.ps1 and customize the $dirs array with your folder paths
2. Save as IntegrityCheck_personal.ps1
3. Run: .\IntegrityCheck_personal.ps1 (first run creates baseline)
4. Optionally add to Task Scheduler for weekly automated scans

The personal version (_personal.ps1) is automatically excluded from git via .gitignore.

---

## Usage

### Normal Scan (Compare Against Baseline)

```powershell
.\IntegrityCheck_personal.ps1
```

This runs a standard integrity check and compares against the baseline. Results go to your configured log directory.

### Reset Baseline (Start Over)

```powershell
.\IntegrityCheck_personal.ps1 -ResetBaseline
```

Use this if:
- You intentionally changed files and want a new baseline
- You want to forget all previous changes and start fresh

This overwrites the old baseline with a new one.

---

## Understanding Results

### 1. The Summary File (Start Here)

**Location**: [YourLogDirectory]/SUMMARY_[timestamp].txt

**Contents:**
- Total directories monitored count
- Number of directories with issues
- Per-directory status (OK, WARN, or RESET)

**How to Read It:**
- OK: No integrity differences detected
- WARN: File changes detected (see detailed report)
- RESET: Baseline was reset to current state

### 2. Detailed Reports

**Location**: [YourLogDirectory]/[DirectoryName]/integrity_report_[timestamp].txt

**Contents:**
- Deleted or modified files (were in baseline, not in current)
- New or modified files (in current, not in baseline or hash changed)

**Reading Guide:**
- [-] = File was deleted or modified (hash changed)
- [+] = File is new or file content changed

### 3. Historical Snapshots

**Location**: [YourLogDirectory]/[DirectoryName]/hashes_[timestamp].csv

These are timestamped copies of all file hashes. Keep for long-term audit trails.

---

## File Structure

After running the script:

```
[YourLogDirectory]/
├── master_integrity_log.txt
├── SUMMARY_[timestamp].txt
│
├── [DirectoryName1]/
│   ├── hashes_baseline.csv
│   ├── baseline_metadata.txt
│   ├── hashes_current.csv
│   ├── hashes_[timestamp].csv
│   └── integrity_report_[timestamp].txt
│
├── [DirectoryName2]/
│   ├── hashes_baseline.csv
│   └── ...
│
└── ... (one per directory)
```

---

## Adding More Directories

Want to monitor additional folders?

1. Open IntegrityCheck_personal.ps1 in a text editor
2. Find the CONFIGURATION section, locate the $dirs array
3. Add your directory:

```powershell
$dirs = @(
    "C:\your\existing\path",
    "C:\your\new\path",
)
```

4. Save the file
5. Run manually once: .\IntegrityCheck_personal.ps1
6. Future runs will include it automatically

---

## Troubleshooting

### "Access Denied" when running script

Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

### No logs are being created

Possible causes:
- Script ran but hit an error
- Check master_integrity_log.txt for error messages
- Verify directories in $dirs array exist
- Ensure log directory path is writable

### Directory doesn't show up in summary

- Directory may not exist (check path spelling)
- Directory may have no monitored file types
- Check master_integrity_log.txt for "Directory not found" messages

### Files show as deleted but they're still there

- File content was modified (hash changed)
- This is expected behavior
- Files are not actually deleted from disk, just changed

### When should I reset the baseline?

Reset baseline when:
- You intentionally added files and want a new baseline
- You made approved changes and don't want them flagged as issues
- You want to start fresh and forget previous changes

```powershell
.\IntegrityCheck_personal.ps1 -ResetBaseline
```

### Task Scheduler task won't run

1. Open Task Scheduler
2. Find your task, right-click and select Properties
3. Go to General tab
4. Check "Run with highest privileges"
5. Apply and OK

---

## Safety Guarantees

- Your files are never modified
- Baseline is immutable (locked by design)
- Baseline only updates with explicit -ResetBaseline command
- All writes go to log directory only
- Historical snapshots always preserved
- No data duplication
- Handles empty/corrupt baseline files gracefully

### Why Immutable Baseline Matters

Without an immutable baseline, if files get corrupted or deleted, you lose your reference point. With this design:
- Your baseline is your truth
- Automatic scans run 100+ times and baseline stays the same
- You always know exactly what changed since you last reset
- Corruption cannot spread to the baseline

---

## Quick Reference

| Task | Command |
|------|---------|
| Run scan | .\IntegrityCheck_personal.ps1 |
| Reset baseline | .\IntegrityCheck_personal.ps1 -ResetBaseline |
| View summary | Open SUMMARY_*.txt in log directory |
| View details | Open integrity_report_*.txt in directory subfolder |
| Add directory | Edit $dirs array in script |
| Schedule weekly | Use Windows Task Scheduler |

---

## Recommended Workflow

1. First Run (Manual): .\IntegrityCheck_personal.ps1
   - Creates immutable baselines for all directories
   - Generates SUMMARY_*.txt report

2. Add to Task Scheduler: Set it to run weekly automatically
   - Runs in normal mode (no -ResetBaseline parameter)
   - Baseline stays locked, never auto-updates
   - Compares current files against baseline
   - Generates new SUMMARY_*.txt each week

3. Weekly Review: Check SUMMARY_*.txt file for any changes

4. If You Add Files Intentionally: Run manually when ready
   ```powershell
   .\IntegrityCheck_personal.ps1 -ResetBaseline
   ```

5. If Issues Detected: Open detailed integrity_report_*.txt for that directory

### Important: Baseline Behavior

- Normal mode (Task Scheduler): Baseline is READ-ONLY, never modified
- Reset mode (manual -ResetBaseline): Baseline is overwritten with current state
- Key guarantee: Without -ResetBaseline parameter, baseline always stays locked

---

Last Updated: May 22, 2026 (Public Template)

Script Version: 2.0-immutable

Status: Production Ready

GitHub Repository: https://github.com/ishaan-1706/MediaGuard

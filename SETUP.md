# MediaGuard Setup Guide

This guide explains how to configure MediaGuard for your personal use.

## File Organization

- **`IntegrityCheck.ps1`** — PUBLIC template (safe to commit to GitHub)
- **`IntegrityCheck_personal.ps1`** — YOUR personal version with actual folder paths (ignored by git)
- **`.gitignore`** — Prevents personal version from being uploaded

## Initial Setup

### Step 1: Create Your Personal Configuration

1. Open the public template: `IntegrityCheck.ps1`
2. Look for the **CONFIGURATION** section (around line 33)
3. Edit these two settings:

```powershell
# Array of directories to monitor
$dirs = @(
    "C:\Users\YourUsername\Documents\Project1",
    "C:\Users\YourUsername\Pictures\Archive",
    "D:\BackupFolder\MediaCollection",
    # Add your directories here
)

# Root directory where logs will be stored
$rootLogDir = "C:\IntegrityLogs"
```

4. Replace the example paths with your actual folder paths
5. Save it as `IntegrityCheck_personal.ps1` in the same directory

### Step 2: Test Your Configuration

```powershell
cd path\to\media_integrity_checker
.\IntegrityCheck_personal.ps1
```

This creates baseline hashes for all your directories on first run.

### Step 3: Add to Windows Task Scheduler (Optional)

To run automatically:

1. Open **Task Scheduler** (search in Windows Start menu)
2. Click **Create Basic Task**
3. Name: `MediaGuard Integrity Check`
4. Trigger: **Weekly** (choose your preferred day/time)
5. Action:
   - Program: `powershell.exe`
   - Arguments: `-NoProfile -ExecutionPolicy Bypass -File "C:\full\path\to\IntegrityCheck_personal.ps1"`
6. Click **Finish**

## Usage

### Normal Scan (Compare Against Baseline)
```powershell
.\IntegrityCheck_personal.ps1
```

### Reset Baseline (After Intentional Changes)
```powershell
.\IntegrityCheck_personal.ps1 -ResetBaseline
```

⚠️ Only use `-ResetBaseline` when you've intentionally modified files and want to establish a new baseline.

## Customizing File Types

The script monitors images, videos, and documents by default. To add more file types:

1. Open `IntegrityCheck_personal.ps1`
2. Find the `$filePattern` array
3. Add extensions in PowerShell format:

```powershell
$filePattern = @(
    "*.jpg", "*.jpeg", "*.png",  # Images
    "*.mp4", "*.mkv",             # Videos
    "*.mp3",                       # Audio
    "*.zip",                       # Archives
    # Add more as needed
)
```

## Important Security Notes

- **Never commit `IntegrityCheck_personal.ps1` to GitHub** — It contains your folder names
- **The `.gitignore` file automatically excludes it** — It's safe, just make sure to keep using the `_personal` suffix
- **The public template (`IntegrityCheck.ps1`) is safe to share** — It only contains example paths

## Troubleshooting

### "Access Denied" Error
Run PowerShell as Administrator

### No logs are being created
- Verify $rootLogDir path is correct and writable
- Check that directories in $dirs actually exist
- Review the output messages for specific errors

### Task Scheduler task won't run
1. Open Task Scheduler
2. Find your task, right-click → **Properties**
3. Go to **General** tab
4. Check: **Run with highest privileges**
5. Apply and OK

## Support

For issues or feature requests, visit: https://github.com/ishaan-1706/MediaGuard

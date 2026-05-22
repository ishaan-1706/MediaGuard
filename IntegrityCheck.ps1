# =========================================================
# MediaGuard - File Integrity Monitor
# =========================================================
# Features:
# - Recursive scanning of specified directories
# - SHA256 hashing for file integrity verification
# - Detects:
#     * Modified files
#     * Deleted files
#     * Newly added files
# - Immutable baseline (never auto-updates)
# - Baseline versioning with creation timestamp
# - Timestamped historical snapshots
# - Centralized logging
# - Non-destructive (read-only monitoring)
# =========================================================

# USAGE: 
# ./IntegrityCheck.ps1              # Normal run - compare against baseline
# ./IntegrityCheck.ps1 -ResetBaseline  # Reset baseline to current state
# 
# SETUP: Edit the $dirs array below to add your monitored folders
# TASK SCHEDULER: This script is safe to run via Task Scheduler (no user interaction needed)
# FIRST RUN: Run manually first time to create baselines, then add to Task Scheduler
# RESULTS: All logs saved to $rootLogDir (created automatically if missing)

param(
    [switch]$ResetBaseline = $false
)

# =====================================================
# CONFIGURATION - EDIT THESE SETTINGS
# =====================================================

# Array of directories to monitor
# Add/remove paths as needed for your setup
$dirs = @(
    "C:\Users\YourUsername\Documents\Project1",
    "C:\Users\YourUsername\Pictures\Archive",
    "D:\BackupFolder\MediaCollection",
    "E:\ExternalDrive\ImportantFiles"
    # Add more directories here following the same pattern
)

# Root directory where logs will be stored
# Change this to wherever you want integrity logs saved
$rootLogDir = "C:\IntegrityLogs"

# Supported file types (modify to monitor different file types)
# Current: Images, Videos, Documents, Spreadsheets
# Add extensions as needed (e.g., *.mp3, *.zip, *.py)
$filePattern = @(
    "*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.tiff", "*.tif", "*.heic", "*.webp",  # Images
    "*.mp4", "*.mkv", "*.avi", "*.mov", "*.flv", "*.wmv", "*.webm",                        # Videos
    "*.docx", "*.pdf", "*.pptx", "*.txt", "*.xls", "*.xlsx", "*.doc", "*.odt", "*.ods", "*.odp"  # Documents
)

# =====================================================
# NO CHANGES NEEDED BELOW THIS LINE
# =====================================================

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create log directory if missing
New-Item -ItemType Directory -Path $rootLogDir -Force | Out-Null

# Master summary log
$summaryLog = Join-Path $rootLogDir "master_integrity_log.txt"

Add-Content $summaryLog ""
Add-Content $summaryLog "================================================="
Add-Content $summaryLog "Integrity Check Run: $(Get-Date)"
Add-Content $summaryLog "================================================="

# ---------------------------------------------------------
# STEP 1 - PROCESS EACH DIRECTORY
# ---------------------------------------------------------
$directoriesProcessed = @()
$directoriesWithIssues = @()
$baselineResetsPerformed = @()

foreach ($TargetDir in $dirs) {

    # Verify directory exists
    if (!(Test-Path $TargetDir)) {
        Write-Host "ERROR: Directory not found: $TargetDir" -ForegroundColor Red
        Add-Content $summaryLog "ERROR: Directory not found: $TargetDir"
        continue
    }

    # Safe folder name for file paths (escape backslashes, colons)
    $safeName = $TargetDir -replace '\\', '_' -replace ':', ''

    # Create per-directory log folder
    $dirLogFolder = Join-Path $rootLogDir $safeName
    New-Item -ItemType Directory -Path $dirLogFolder -Force | Out-Null

    # Current hash file
    $currentHashFile = Join-Path $dirLogFolder "hashes_current.csv"

    # Previous baseline (immutable gold standard)
    $baselineHashFile = Join-Path $dirLogFolder "hashes_baseline.csv"
    
    # Baseline metadata (version/creation info)
    $baselineMetaFile = Join-Path $dirLogFolder "baseline_metadata.txt"

    # Per-directory report
    $reportFile = Join-Path $dirLogFolder "integrity_report_$timestamp.txt"

    Write-Host "Processing: $TargetDir"

    # HASH ALL FILES RECURSIVELY
    # Supported: Images, Videos, Documents, Spreadsheets
    Write-Host "Hashing files..."

    $hashes = Get-ChildItem `
        -Path $TargetDir `
        -Recurse `
        -File `
        -Include $filePattern |
        Get-FileHash -Algorithm SHA256 |
        Select-Object Path, Hash, Algorithm

    # Save current hashes
    $hashes | Export-Csv $currentHashFile -NoTypeInformation

    # Save timestamped snapshot for historical records
    $hashes | Export-Csv (Join-Path $dirLogFolder "hashes_$timestamp.csv") -NoTypeInformation

    # ---------------------------------------------------------
    # BASELINE INITIALIZATION (One-time only)
    # ---------------------------------------------------------
    if (!(Test-Path $baselineHashFile)) {

        Write-Host "No baseline found. Creating initial baseline..."

        $hashes | Export-Csv $baselineHashFile -NoTypeInformation

        # Save baseline metadata with creation timestamp
        @{
            Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = 1
            ScriptVersion = "2.0-immutable"
        } | ConvertTo-Json | Out-File $baselineMetaFile

        Add-Content $summaryLog "Baseline created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }

    # ---------------------------------------------------------
    # BASELINE RESET (Explicit only, via -ResetBaseline flag)
    # ---------------------------------------------------------
    if ($ResetBaseline) {

        Write-Host "RESETTING BASELINE for: $TargetDir"

        $hashes | Export-Csv $baselineHashFile -NoTypeInformation

        @{
            Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = 1
            ScriptVersion = "2.0-immutable"
            ResetAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        } | ConvertTo-Json | Out-File $baselineMetaFile

        Add-Content $summaryLog "BASELINE RESET at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Add-Content $reportFile "BASELINE RESET"
        Add-Content $reportFile "Previous baseline discarded, new baseline established."

        # Track baseline reset
        $baselineResetsPerformed += @{
            Directory = $TargetDir
            ResetTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $directoriesProcessed += @{
            Directory = $TargetDir
            Status = "BASELINE_RESET"
            ReportPath = $reportFile
        }
    }

    # ---------------------------------------------------------
    # COMPARE AGAINST IMMUTABLE BASELINE (Never auto-updates)
    # ---------------------------------------------------------
    else {

        Add-Content $reportFile "Baseline Created: $baselineCreated"
        Add-Content $reportFile ""

        Write-Host "Comparing against baseline..."

        $old = Import-Csv $baselineHashFile
        $new = Import-Csv $currentHashFile

        # Handle null/empty baseline
        if ($null -eq $old -or $old.Count -eq 0) {
            Add-Content $reportFile "WARNING: Baseline file is empty. Skipping comparison."
            Add-Content $reportFile ""
        }
        elseif ($comparison = (Compare-Object -ReferenceObject $old -DifferenceObject $new -Property Path, Hash)) {
            # If comparison returns results, process them

            Add-Content $reportFile "INTEGRITY ISSUES DETECTED:"
            Add-Content $reportFile ""

            # Separate deletions and new/modified files for clarity
            $deletions = $comparison | Where-Object { $_.SideIndicator -eq "<=" }
            $additions = $comparison | Where-Object { $_.SideIndicator -eq "=>" }

            if ($deletions) {
                Add-Content $reportFile "DELETED or MODIFIED (in baseline, not in current):"
                foreach ($item in $deletions) {
                    Add-Content $reportFile "  [-] $($item.Path)"
                }
                Add-Content $reportFile ""
            }

            if ($additions) {
                Add-Content $reportFile "NEW or MODIFIED (in current, not in baseline):"
                foreach ($item in $additions) {
                    Add-Content $reportFile "  [+] $($item.Path)"
                }
                Add-Content $reportFile ""
            }

            Add-Content $summaryLog "WARNING: Differences detected in $TargetDir"
            Add-Content $summaryLog "Report: $reportFile"

            # Track for summary
            $directoriesWithIssues += @{
                Directory = $TargetDir
                DeletedOrModified = @($deletions).Count
                NewOrModified = @($additions).Count
                ReportPath = $reportFile
                Details = $comparison
            }

            $directoriesProcessed += @{
                Directory = $TargetDir
                Status = "ISSUES_DETECTED"
                ReportPath = $reportFile
            }
        }
        else {

            Add-Content $reportFile "No integrity differences detected."
            Add-Content $summaryLog "No differences detected."

            $directoriesProcessed += @{
                Directory = $TargetDir
                Status = "OK"
                ReportPath = $reportFile
            }
        }
    }

    Add-Content $reportFile ""
    Add-Content $reportFile "Report Generated: $(Get-Date)"
}

# ---------------------------------------------------------
# GENERATE SUMMARY REPORT
# ---------------------------------------------------------

$summaryReportFile = Join-Path $rootLogDir "SUMMARY_$timestamp.txt"

$summaryContent = @"
========================================================================
          INTEGRITY SCAN SUMMARY - ONE-FILE REPORT
========================================================================

SCAN DATE: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
SCAN MODE: $(if ($ResetBaseline) { "BASELINE RESET" } else { "NORMAL COMPARISON" })

=========================================================================
STATISTICS
=========================================================================

  Total directories monitored: $($dirs.Count)
  OK: No issues detected:       $(@($directoriesProcessed | Where-Object { $_.Status -eq "OK" }).Count)
  WARN: Issues detected:         $(@($directoriesProcessed | Where-Object { $_.Status -eq "ISSUES_DETECTED" }).Count)
  RESET: Baseline resets:        $($baselineResetsPerformed.Count)

=========================================================================
ALL DIRECTORIES STATUS
=========================================================================

"@

foreach ($dir in $directoriesProcessed) {
    $status = $dir.Status
    $symbol = switch ($status) {
        "OK" { "OK " }
        "ISSUES_DETECTED" { "WARN" }
        "BASELINE_RESET" { "RESET" }
        default { "?" }
    }

    $summaryContent += "$symbol  $($dir.Directory)`n"

    if ($status -eq "ISSUES_DETECTED") {
        $issue = $directoriesWithIssues | Where-Object { $_.Directory -eq $dir.Directory }
        if ($issue) {
            $summaryContent += "     Deleted/Modified: $($issue.DeletedOrModified) file(s)`n"
            $summaryContent += "     New/Modified:     $($issue.NewOrModified) file(s)`n"
            $summaryContent += "     Full report:      $($dir.ReportPath)`n"
        }
    }
}

$summaryContent += @"

=========================================================================
For detailed reports, see:
  * Master log:  $summaryLog
  * Per-dir logs: $rootLogDir\<directory_name>\integrity_report_*.txt
=========================================================================
"@

$summaryContent | Out-File $summaryReportFile

# ---------------------------------------------------------
# COMPLETION
# ---------------------------------------------------------

Add-Content $summaryLog ""
Add-Content $summaryLog "Integrity scan complete."
Add-Content $summaryLog ""

Write-Host ""
Write-Host "Integrity scan complete."
Write-Host ""
Write-Host "SUMMARY: $summaryReportFile"
Write-Host ""
Write-Host "Results stored in: $rootLogDir"
Write-Host ""
Write-Host "OK - Baseline is immutable (no auto-updates)"
Write-Host "OK - Task Scheduler friendly (runs without user interaction)"
Write-Host "=================================================="

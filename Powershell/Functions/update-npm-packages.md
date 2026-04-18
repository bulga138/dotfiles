# Update-NpmPackages PowerShell Utility

## Overview

`Update-NpmPackages` is a robust PowerShell automation tool designed to manage npm dependencies with precision. Unlike standard `npm update` commands, this tool enforces fixed versioning (removing carets `^` and tildes `~`), handles deep dependency conflicts, manages backups, and provides detailed reporting suitable for both local development and CI/CD pipelines.

## Key Features

- **Fixed Versioning:** Updates packages to their latest or compatible versions and pins them using `--save-exact`.
- **SemVer Awareness:** Analyzes version changes to distinguish between Major, Minor, and Patch updates, protecting against accidental downgrades.
- **Safety Mechanisms:** Includes automated `package.json` backups and a rollback (Restore) feature.
- **Conflict Resolution:** Automates the handling of peer dependency conflicts via the `-Force` flag.
- **Deprecation Management:** Captures deprecation warnings during installation and generates `overrides` configurations to fix nested dependency issues.
- **Reporting:** Generates console summaries and Markdown changelogs suitable for pull request descriptions.
- **Performance:** optimized "Clean Install" logic that updates the manifest directly before reinstalling, reducing network overhead.

## Installation

This tool is designed to be added to your PowerShell Profile so it is available in any directory.

1.  Open your PowerShell profile:
    ```powershell
    notepad $PROFILE
    ```
2.  Copy the **Source Code** provided at the bottom of this document.
3.  Paste it into the profile file and save it.
4.  Reload your profile:
    ```powershell
    . $PROFILE
    ```

## Usage Examples

### 1. Dry Run (Simulation)

Check what updates are available without modifying any files.

```powershell
Update-NpmPackages -DryRun
```

Here is the professional documentation and source code for the tool. You can save this file as `README.md`.

````markdown
# Update-NpmPackages PowerShell Utility

## Overview

`Update-NpmPackages` is a robust PowerShell automation tool designed to manage npm dependencies with precision. Unlike standard `npm update` commands, this tool enforces fixed versioning (removing carets `^` and tildes `~`), handles deep dependency conflicts, manages backups, and provides detailed reporting suitable for both local development and CI/CD pipelines.

## Key Features

- **Fixed Versioning:** Updates packages to their latest or compatible versions and pins them using `--save-exact`.
- **SemVer Awareness:** Analyzes version changes to distinguish between Major, Minor, and Patch updates, protecting against accidental downgrades.
- **Safety Mechanisms:** Includes automated `package.json` backups and a rollback (Restore) feature.
- **Conflict Resolution:** Automates the handling of peer dependency conflicts via the `-Force` flag.
- **Deprecation Management:** Captures deprecation warnings during installation and generates `overrides` configurations to fix nested dependency issues.
- **Reporting:** Generates console summaries and Markdown changelogs suitable for pull request descriptions.
- **Performance:** optimized "Clean Install" logic that updates the manifest directly before reinstalling, reducing network overhead.

## Installation

This tool is designed to be added to your PowerShell Profile so it is available in any directory.

1.  Open your PowerShell profile:
    ```powershell
    notepad $PROFILE
    ```
2.  Copy the **Source Code** provided at the bottom of this document.
3.  Paste it into the profile file and save it.
4.  Reload your profile:
    ```powershell
    . $PROFILE
    ```

## Usage Examples

### 1. Dry Run (Simulation)

Check what updates are available without modifying any files.

```powershell
Update-NpmPackages -DryRun
```

### 2. Standard Update

Update all packages to the absolute latest version.

```powershell
Update-NpmPackages

```

### 3. Safe Update (Compatible Mode)

Update packages only to the latest version allowed by your current `package.json` ranges (e.g., sticking to v1.x). Includes an automatic backup.

```powershell
Update-NpmPackages -Compatible -AutoBackup

```

### 4. Full Reset (CI/CD Mode)

Force updates ignoring peer dependency conflicts, delete `node_modules`, and perform a clean install.

```powershell
Update-NpmPackages -Force -CleanInstall

```

### 5. Generate Report

Simulate updates and export the results to a Markdown file for documentation.

```powershell
Update-NpmPackages -DryRun -ExportMarkdown "CHANGELOG.md"

```

### 6. Restore Backup

Revert `package.json` to the most recent backup.

```powershell
Update-NpmPackages -Restore

```

## Parameter Reference

| Parameter         | Type     | Description                                                                                  |
| ----------------- | -------- | -------------------------------------------------------------------------------------------- |
| `-DryRun`         | Switch   | Simulates the process. No files are modified.                                                |
| `-Compatible`     | Switch   | Updates to the 'wanted' version based on existing ranges instead of 'latest'.                |
| `-Force`          | Switch   | Appends `--legacy-peer-deps` to install commands to bypass conflict errors.                  |
| `-CleanInstall`   | Switch   | Deletes `node_modules` and runs a fresh install after updating the manifest.                 |
| `-AutoBackup`     | Switch   | Creates a timestamped copy of `package.json` before execution.                               |
| `-Restore`        | Switch   | Finds the most recent backup file and overwrites the current `package.json`.                 |
| `-ListBackups`    | Switch   | Lists all available backup files and their timestamps.                                       |
| `-Exclude`        | String[] | A list of package names to ignore during the update (e.g., `-Exclude "react","typescript"`). |
| `-IgnoreDev`      | Switch   | Skips processing of `devDependencies`.                                                       |
| `-ExportMarkdown` | String   | Path to an output file for a table-formatted update report.                                  |
| `-PassThru`       | Switch   | Returns the result objects to the pipeline for further processing.                           |
| `-Audit`          | Switch   | Runs `npm audit` after the update process.                                                   |
| `-Fix`            | Switch   | Runs `npm audit fix` after the update process.                                               |

Param([string]$Deploy)

Write-Host "DGUS DWIN firmware build package script v1.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: " -ForegroundColor Yellow
Write-Host "1 . Ensure you've clicked 'Generate' in the DWIN editor first" -ForegroundColor Yellow
Write-Host "2 . If any screens are updated, make sure you've re-generated the ICL file (see README.md)" -ForegroundColor Yellow

# Variables 
$BuildDir = "build"
$BuildTmpDir = "build\tmp"

$ProjectFolder = "src/DWIN"
$FirmwareFolderName = "DWIN_SET"

$OutputPath = "$BuildDir/CR-6-touchscreen-$(Get-Date -Format "yyyy-MM-dd").zip"

# ... ZIP inputs
$ReadMeFilePath = "src/README.md"
$ReadMeCopiedFilePath = "$BuildTmpDir/README.txt"
$ExampleSuccesfulFilePath = "src/flash_succesful.jpg"
$ExampleProgressFilePath = "src/flashing_in_progress.jpg"
$ExampleFailedFilePath = "src/flash_failed.jpg"

[array] $ZipInputs = $($ReadMeCopiedFilePath, $ExampleSuccesfulFilePath, $ExampleProgressFilePath, $ExampleFailedFilePath)

# Clean up
Write-Host "Cleaning up..." -ForegroundColor Cyan
Remove-Item $BuildDir -Recurse -Force -ErrorAction SilentlyContinue
New-Item $BuildDir -ItemType Directory | Out-Null
New-Item $BuildTmpDir -ItemType Directory | Out-Null

Copy-Item $ReadMeFilePath $ReadMeCopiedFilePath -Force -Verbose

# Copy DWIN stuff
Write-Host "Preparing..." -ForegroundColor Cyan

Copy-Item -Path "$ProjectFolder/$FirmwareFolderName" -Recurse -Destination $BuildTmpDir

# ... Bitmaps are now actually used
Get-ChildItem -Path $BuildTmpDir -Recurse -Filter "*.bmp" | Remove-Item -Force

# ... DWIN seems sensitive to these names?
Get-ChildItem -Path $BuildTmpDir -Recurse -Filter "13*.bin" | Rename-Item -NewName "13_TouchFile.bin"
Get-ChildItem -Path $BuildTmpDir -Recurse -Filter "14*.bin" | Rename-Item -NewName "14_VariableFile.bin"

# Check sector allocation
Write-Host "Checking sector allocation..." -ForegroundColor Cyan

Write-Host "---------------------------------------------------"
.\scripts\Get-DwinSectorAllocation.ps1 $BuildTmpDir
Write-Host "---------------------------------------------------"

if ($LASTEXITCODE -ne 0) {
    Write-Host "... sector allocation check failed" -ForegroundColor Red
    Exit -1
}

Write-Host "... sector allocation check succesful" -ForegroundColor Green

# Make ZIP file
Write-Host "Zipping..." -ForegroundColor Cyan
[array] $ZipContents = $ZipInputs | Get-Item
$DWINFolder = Get-Item -Path "$BuildTmpDir/$FirmwareFolderName"
$ZipContents += $DWINFolder

$ZipContents | Compress-Archive -DestinationPath $OutputPath -CompressionLevel Optimal -Verbose

if ($Deploy) {
	Remove-Item -Path $(Join-Path $Deploy "DWIN_SET") -Recurse -Force -Verbose
	Expand-Archive -Path $OutputPath -DestinationPath $Deploy -Verbose -Force
}

# Done
Write-Host ""
Write-Host "Done! Please find the archive in $OutputPath" -ForegroundColor Green

Exit 0
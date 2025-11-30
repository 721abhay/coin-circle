# Automated Code Quality Fixer
# This script fixes common code quality issues

Write-Host "Starting Automated Code Quality Fixes..." -ForegroundColor Cyan
Write-Host ""

$projectRoot = "c:\Users\ABHAY\coin circle\coin_circle"
$libPath = Join-Path $projectRoot "lib"

# Counter for fixes
$fixCount = 0

# Replace print() with debugPrint()
Write-Host "Fix 1: Replacing print() with debugPrint()..." -ForegroundColor Yellow

$dartFiles = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        
        if ($content -match '\bprint\(') {
            $newContent = $content -replace '\bprint\(', 'debugPrint('
            
            if ($content -ne $newContent) {
                Set-Content -Path $file.FullName -Value $newContent -NoNewline
                $fixCount++
                Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "  Skipped: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "AUTOMATED FIXES COMPLETE" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fixes Applied: $fixCount" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Review the changes made" -ForegroundColor White
Write-Host "2. Run 'flutter analyze' to see remaining issues" -ForegroundColor White
Write-Host "3. Fix critical errors manually (see COMPLETE_FIX_GUIDE.md)" -ForegroundColor White
Write-Host "4. Test the application" -ForegroundColor White
Write-Host ""

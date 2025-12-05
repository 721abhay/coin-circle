# Push Notifications Quick Setup Script

Write-Host "Push Notifications Setup" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\Users\ABHAY\coin circle\coin_circle"

# Step 1: Check FlutterFire CLI
Write-Host "Step 1: Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfire = Get-Command flutterfire -ErrorAction SilentlyContinue
if (-not $flutterfire) {
    Write-Host "  Installing FlutterFire CLI..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
    Write-Host "  Done" -ForegroundColor Green
}
else {
    Write-Host "  Already installed" -ForegroundColor Green
}

# Step 2: Configure Firebase
Write-Host ""
Write-Host "Step 2: Configure Firebase..." -ForegroundColor Yellow
Write-Host "  This will open a browser" -ForegroundColor Cyan
Write-Host ""
$response = Read-Host "Ready to configure? (y/n)"
if ($response -eq 'y') {
    flutterfire configure
    Write-Host "  Done" -ForegroundColor Green
}
else {
    Write-Host "  Skipped" -ForegroundColor Yellow
}

# Step 3: Check result
Write-Host ""
Write-Host "Step 3: Checking firebase_options.dart..." -ForegroundColor Yellow
if (Test-Path "lib\firebase_options.dart") {
    Write-Host "  Found!" -ForegroundColor Green
}
else {
    Write-Host "  Not found" -ForegroundColor Red
}

# Step 4: Get dependencies
Write-Host ""
Write-Host "Step 4: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "  Done" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next: See PUSH_NOTIFICATIONS_QUICK_GUIDE.md" -ForegroundColor Cyan
Write-Host ""

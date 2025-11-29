Write-Host "🤖 Starting Complete Test Suite..." -ForegroundColor Cyan

Write-Host "`n1️⃣ Running Static Analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Analysis Failed" -ForegroundColor Red }

Write-Host "`n2️⃣ Running Linter..." -ForegroundColor Yellow
dart analyze
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Linting Failed" -ForegroundColor Red }

Write-Host "`n3️⃣ Running All Tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Tests Failed" -ForegroundColor Red }

Write-Host "`n✅ Complete Test Suite Finished!" -ForegroundColor Green

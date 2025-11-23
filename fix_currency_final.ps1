# Precise currency replacement - Replace ₹ with ₹ in Dart string literals
# This targets escaped dollar signs in strings, not variable interpolation

$ErrorActionPreference = "Stop"

$files = @(
    "lib\features\wallet\presentation\screens\wallet_screen.dart",
    "lib\features\wallet\presentation\screens\transaction_history_screen.dart",
    "lib\features\wallet\presentation\screens\payment_screen.dart",
    "lib\features\wallet\presentation\screens\payout_screen.dart",
    "lib\features\pools\presentation\screens\pool_details_screen.dart",
    "lib\features\pools\presentation\screens\create_pool_screen.dart",
    "lib\features\pools\presentation\screens\join_pool_screen.dart",
    "lib\features\pools\presentation\screens\my_pools_screen.dart",
    "lib\features\pools\presentation\widgets\statistics_tab.dart",
    "lib\features\profile\presentation\screens\profile_screen.dart",
    "lib\features\dashboard\presentation\screens\home_screen.dart"
)

$count = 0
foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        # Replace ₹ (escaped dollar) with ₹ - this is used in Dart strings
        $newContent = $content -replace '\₹', '₹'
        
        if ($content -ne $newContent) {
            Set-Content $file -Value $newContent -Encoding UTF8 -NoNewline
            $count++
            Write-Host "✓ Updated: $file"
        }
        else {
            Write-Host "  No changes: $file"
        }
    }
    else {
        Write-Host "✗ Not found: $file"
    }
}

Write-Host "`n✓ Successfully updated $count files with ₹ symbol!"

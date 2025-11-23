# Replace all ? with ₹ (Rupee symbol) in Dart files
$files = @(
    "lib\features\wallet\presentation\screens\wallet_screen.dart",
    "lib\features\wallet\presentation\screens\transaction_history_screen.dart",
    "lib\features\wallet\presentation\screens\payment_screen.dart",
    "lib\features\wallet\presentation\screens\payout_screen.dart",
    "lib\features\pools\presentation\screens\pool_details_screen.dart",
    "lib\features\pools\presentation\screens\create_pool_screen.dart",
    "lib\features\pools\presentation\screens\join_pool_screen.dart",
    "lib\features\pools\presentation\screens\my_pools_screen.dart",
    "lib\features\pools\presentation\screens\winner_selection_screen.dart",
    "lib\features\pools\presentation\widgets\statistics_tab.dart",
    "lib\features\pools\presentation\widgets\voting_tab.dart",
    "lib\features\profile\presentation\screens\profile_screen.dart",
    "lib\features\dashboard\presentation\screens\home_screen.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw -Encoding UTF8
        # Replace ? with ₹ but be careful not to replace question marks in actual questions
        $content = $content -replace "'\?", "'₹"
        $content = $content -replace " \?", " ₹"
        $content = $content -replace "\+\?", "+₹"
        $content = $content -replace "-\?", "-₹"
        $content = $content -replace ":\s*'\?", ": '₹"
        Set-Content $file -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Fixed: $file"
    }
}

Write-Host "`nAll files updated with ₹ symbol!"

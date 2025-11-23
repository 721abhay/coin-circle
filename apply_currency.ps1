# Replace \$ with ₹ in Dart files
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$count = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -match '\\$') {
        $newContent = $content -replace '\\$', '₹'
        Set-Content $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
        $count++
        Write-Output "Updated: $($file.FullName)"
    }
}

Write-Output "`nTotal files updated: $count"

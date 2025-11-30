# Fix missing imports for debugPrint
# This script adds 'package:flutter/foundation.dart' to files using debugPrint without proper imports

Write-Host "Fixing missing imports for debugPrint..." -ForegroundColor Cyan

$projectRoot = "c:\Users\ABHAY\coin circle\coin_circle"
$libPath = Join-Path $projectRoot "lib"

$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart"
$fixCount = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    if ($content -match '\bdebugPrint\(') {
        $hasMaterial = $content -match "package:flutter/material.dart"
        $hasCupertino = $content -match "package:flutter/cupertino.dart"
        $hasWidgets = $content -match "package:flutter/widgets.dart"
        $hasFoundation = $content -match "package:flutter/foundation.dart"
        
        if (-not ($hasMaterial -or $hasCupertino -or $hasWidgets -or $hasFoundation)) {
            $lines = Get-Content $file.FullName
            $newLines = @("import 'package:flutter/foundation.dart';") + $lines
            Set-Content -Path $file.FullName -Value $newLines
            $fixCount++
            Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
        }
    }
}

Write-Host "Fixed $fixCount files" -ForegroundColor Green

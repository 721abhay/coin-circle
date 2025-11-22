@echo off
echo ==========================================
echo   Coin Circle - GitHub Setup Assistant
echo ==========================================
echo.
echo This script will help you push your code to GitHub.
echo.
echo 1. Go to https://github.com/new
echo 2. Create a new repository (name it 'coin-circle' or similar)
echo 3. Do NOT initialize with README, .gitignore, or License
echo 4. Copy the HTTPS URL (e.g., https://github.com/username/repo.git)
echo.
set /p REPO_URL="Paste your GitHub Repository URL here: "

if "%REPO_URL%"=="" (
    echo Error: URL cannot be empty.
    pause
    exit /b
)

echo.
echo Linking remote repository...
git remote add origin %REPO_URL%

echo.
echo Pushing code to GitHub...
git branch -M main
git push -u origin main

echo.
echo ==========================================
echo   Done! Your code is now on GitHub.
echo ==========================================
pause

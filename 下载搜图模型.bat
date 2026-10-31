@echo off
chcp 65001 >nul
title Download image-search model
cd /d "%~dp0"

set "OUT=%~dp0_tools\_imgsearch\vitb32.bin"
set "URL=https://www.modelscope.cn/api/v1/models/AI-ModelScope/CLIP-ViT-B-32-laion2B-s34B-b79K/repo?Revision=master^&FilePath=open_clip_pytorch_model.bin"

rem ---- already complete? ----
set "SIZE="
if exist "%OUT%" for %%A in ("%OUT%") do set "SIZE=%%~zA"
if not defined SIZE goto download
if %SIZE% GEQ 500000000 (
  echo Model file already exists: %OUT%
  echo Nothing to do. Close this window.
  pause
  exit /b 0
)

echo Found a partial file from an earlier run.
echo It will be RESUMED, not downloaded from zero.
echo.

:download
echo ============================================================
echo  Downloading the CLIP model file (about 578 MB, one time).
echo  Saving to: %OUT%
echo  If it fails, just run this .bat again - it continues
echo  from where it stopped. Keep this window open.
echo ============================================================
echo.

where curl.exe >nul 2>nul
if not errorlevel 1 (
  curl.exe -L -C - --retry 8 --retry-delay 2 --connect-timeout 20 -o "%OUT%" "%URL%"
  goto check
)

echo curl.exe not found, using PowerShell (cannot resume) ...
if exist "%OUT%" del "%OUT%"
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('%URL%', '%OUT%')"
if errorlevel 1 goto dlfail

:check
set "SIZE="
for %%A in ("%OUT%") do set "SIZE=%%~zA"
if not defined SIZE goto dlfail
if %SIZE% LSS 500000000 goto dlfail

echo.
echo ============================================================
echo  DONE. Model saved. The image-search tab will now work.
echo  Model file: _tools\_imgsearch\vitb32.bin
echo ============================================================
pause
exit /b 0

:dlfail
echo.
echo   [!] Download interrupted or file looks incomplete.
echo   The partial file is KEPT - just run this .bat again and
echo   it continues from where it stopped.
pause
exit /b 1

@echo off
chcp 65001 >nul
title Install image-search dependencies
cd /d "%~dp0"

set "VENV=%~dp0_tools\_imgsearch\.venv"
set "VPY=%VENV%\Scripts\python.exe"

echo ============================================================
echo  This installs the dependencies for the image-search tab.
echo  It creates an isolated environment inside _tools\_imgsearch\.venv
echo  (your main Python is NOT touched) and downloads about 300 MB.
echo  Fast China mirrors are tried first. Keep this window open
echo  until it says DONE.
echo ============================================================
echo.

rem --- 0) bundled portable runtime: deps already included ---
if exist "%~dp0runtime\python.exe" (
  "%~dp0runtime\python.exe" -c "import numpy, torch, open_clip" >nul 2>nul
  if not errorlevel 1 (
    echo The bundled runtime already has all dependencies included.
    echo Nothing to install. You can use everything right away.
    echo.
    pause
    exit /b 0
  )
)

rem ---- find a base python (NOT the project venv) ----
set "PY="
if exist "%USERPROFILE%\.workbuddy\binaries\python\versions\3.13.12\python.exe" set "PY=%USERPROFILE%\.workbuddy\binaries\python\versions\3.13.12\python.exe"
if not defined PY where python.exe >nul 2>nul && set "PY=python.exe"
if not defined PY where py.exe >nul 2>nul && set "PY=py.exe"
if not defined PY goto nopython

"%PY%" -c "import sys" >nul 2>nul
if errorlevel 1 goto nopython

rem ---- create the venv once ----
if not exist "%VPY%" (
  echo [1/3] Creating isolated environment ...
  "%PY%" -m venv "%VENV%"
  if errorlevel 1 goto venvfail
) else (
  echo [1/3] Environment already exists, reusing it.
)

rem ---- skip everything if deps are already installed ----
"%VPY%" -c "import numpy, torch, open_clip" >nul 2>nul
if not errorlevel 1 (
  echo [2/3] Dependencies are already installed. Nothing to do.
  goto done
)

echo [2/3] Updating pip (small download, makes the fast mirror work) ...
"%VPY%" -m pip install --upgrade pip >nul 2>nul
if errorlevel 1 echo   (pip update skipped, will use built-in pip)

echo [3/3] Installing all libraries in ONE download, about 300 MB ...
echo   (fast China mirror first, then fallbacks)
set "OK="
for %%I in (https://pypi.tuna.tsinghua.edu.cn/simple https://mirrors.aliyun.com/pypi/simple/ https://pypi.org/simple) do (
  if not defined OK (
    echo   trying index: %%I
    "%VPY%" -m pip install --timeout 45 --retries 2 numpy requests pillow tqdm sentencepiece ftfy regex open_clip_torch torch torchvision -i %%I
    if not errorlevel 1 set "OK=1"
  )
)
if not defined OK goto pipfail

"%VPY%" -c "import numpy, torch, open_clip"
if errorlevel 1 goto pipfail

:done
echo.
echo ============================================================
echo  DONE. Now start the scraper again with its usual launcher
echo  .bat. The image-search tab should become available.
echo  (To actually search, you still need the model file:
echo   run the model-download .bat once, or copy vitb32.bin
echo   into the folder _tools\_imgsearch yourself.)
echo ============================================================
pause
exit /b 0

:nopython
echo.
echo   [!] Python 3 was not found on this computer.
echo   Please install it from: https://www.python.org/downloads/
echo   During setup, tick "Add python.exe to PATH", then run this again.
echo.
pause
exit /b 1

:venvfail
echo.
echo   [!] Failed to create the environment. Check disk space and retry.
echo.
pause
exit /b 1

:pipfail
echo.
echo   [!] Installation failed. Check your internet connection and run
echo       this script again (already-downloaded parts are cached,
echo       so the next run is much faster).
echo.
pause
exit /b 1

@echo off
:: Q-Paw Portable Launcher for Windows
:: Supports uv (fast) + pip (fallback)
:: All paths use %~dp0 as USB root

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

:: --- Check Python environment ---
if not exist "%USB_ROOT%\python\python.exe" goto :NO_PYTHON

:: --- Set portable Python environment ---
set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages;%USB_ROOT%\qwenpaw-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"

:: --- Core portable setting: QwenPaw working directory on USB ---
set "QWENPAW_WORKING_DIR=%USB_ROOT%\data"
set "QWENPAW_SECRET_DIR=%USB_ROOT%\data\.secret"

:: --- Portable mode flags ---
set "QP_PORTABLE_MODE=1"
set "QP_MODELS_DIR=%USB_ROOT%\models"

:: --- Ensure directories exist ---
if not exist "%QWENPAW_WORKING_DIR%" mkdir "%QWENPAW_WORKING_DIR%"
if not exist "%QP_MODELS_DIR%" mkdir "%QP_MODELS_DIR%"

:: --- Check if QwenPaw workspace is initialized ---
if not exist "%QWENPAW_WORKING_DIR%\config.json" (
echo  [WARN] QwenPaw workspace not initialized!
echo         Please run setup.bat first, or run: qwenpaw init --defaults
echo.
pause
exit /b 1
)

:: --- Display info ---
echo.
echo  =============================================
echo    Q-Paw Portable - QwenPaw USB Launcher
echo  =============================================
echo.
echo  USB Root:   %USB_ROOT%
echo  Python:     %PYTHONHOME%\python.exe
echo  Work Dir:   %QWENPAW_WORKING_DIR%
echo  Secret Dir: %QWENPAW_SECRET_DIR%
echo  Models Dir: %QP_MODELS_DIR%

:: --- Show package manager ---
if exist "%USB_ROOT%\bin\uv.exe" (
echo  Pkg Mgr:    uv ^(fast^)
) else (
echo  Pkg Mgr:    pip
)
echo.

:: --- Check models directory ---
set "HAS_MODEL=0"
for /f %%a in ('dir /b "%QP_MODELS_DIR%" 2^>nul ^| find /c /v ""') do set "HAS_MODEL=%%a"
if not "%HAS_MODEL%"=="0" goto :HAS_MODELS

echo  [INFO] No local models found. Online mode will be used.
echo         Run model-manager.bat to download or import models.
echo.

:HAS_MODELS
:: --- Launch QwenPaw ---
echo  Starting QwenPaw...
echo.

if exist "%USB_ROOT%\qwenpaw-desktop\QwenPaw.exe" goto :LAUNCH_DESKTOP

:: CLI version - try desktop mode first, then app mode
"%PYTHONHOME%\python.exe" -m qwenpaw desktop
if %errorlevel%==0 goto :LAUNCHED
"%PYTHONHOME%\python.exe" -m qwenpaw app
goto :LAUNCHED

:LAUNCH_DESKTOP
start "" "%USB_ROOT%\qwenpaw-desktop\QwenPaw.exe"
echo  Desktop version launched!

:LAUNCHED
echo.
pause
exit /b 0

:NO_PYTHON
echo.
echo  [ERROR] Portable Python not found!
echo  Please run setup.bat first.
echo.
pause
exit /b 1

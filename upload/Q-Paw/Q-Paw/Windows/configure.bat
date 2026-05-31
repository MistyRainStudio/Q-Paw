@echo off
:: Q-Paw Interactive Configuration Editor
:: Calls the Python-based config editor

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

:: --- Check Python ---
if not exist "%USB_ROOT%\python\python.exe" (
    echo.
    echo  [ERROR] Portable Python not found! Please run setup.bat first.
    echo.
    pause
    exit /b 1
)

:: --- Set environment ---
set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"
set "QWENPAW_WORKING_DIR=%USB_ROOT%\data"
set "QWENPAW_SECRET_DIR=%USB_ROOT%\data\.secret"
set "QWENPAW_BACKUP_DIR=%USB_ROOT%\data\.backups"
set "USB_ROOT=%USB_ROOT%"

:: --- Launch config editor ---
"%USB_ROOT%\python\python.exe" "%USB_ROOT%\scripts\qpaw-config.py"

:: --- Restore console colors ---
echo.
pause

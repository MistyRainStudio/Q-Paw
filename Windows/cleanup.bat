@echo off
:: Q-Paw Cleanup Utility for Windows
:: Supports uv + pip cache cleanup
:: Clean caches and logs to free USB space

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

echo.
echo  =============================================
echo    Q-Paw Cleanup Utility
echo    (uv + pip cache supported)
echo  =============================================
echo.
echo  Choose what to clean:
echo.
echo    1. Clean log files
echo    2. Clean Python cache
echo    3. Clean pip cache
echo    4. Clean uv cache
echo    5. Clean temp files
echo    6. Clean all - above items
echo    0. Exit
echo.
set /p "CHOICE=  Enter choice: "

if "%CHOICE%"=="1" goto :CLEAN_LOGS
if "%CHOICE%"=="2" goto :CLEAN_PYCACHE
if "%CHOICE%"=="3" goto :CLEAN_PIP
if "%CHOICE%"=="4" goto :CLEAN_UV
if "%CHOICE%"=="5" goto :CLEAN_TEMP
if "%CHOICE%"=="6" goto :CLEAN_ALL
goto :DONE

:CLEAN_LOGS
echo  Cleaning logs...
del /Q "%USB_ROOT%\logs\*" 2>nul
echo  Done.
goto :DONE

:CLEAN_PYCACHE
echo  Cleaning Python cache...
for /d /r "%USB_ROOT%" %%i in (__pycache__) do rd /S /Q "%%i" 2>nul
del /S /Q "%USB_ROOT%\*.pyc" 2>nul
echo  Done.
goto :DONE

:CLEAN_PIP
echo  Cleaning pip cache...
if exist "%USB_ROOT%\python\Scripts\pip.exe" "%USB_ROOT%\python\Scripts\pip.exe" cache purge 2>nul
rd /S /Q "%USB_ROOT%\python\pip-cache" 2>nul
echo  Done.
goto :DONE

:CLEAN_UV
echo  Cleaning uv cache...
if exist "%USB_ROOT%\bin\uv.exe" (
    "%USB_ROOT%\bin\uv.exe" cache clean 2>nul
    echo  uv cache cleaned.
) else (
    echo  uv not found, skipping uv cache.
)
rd /S /Q "%USB_ROOT%\bin\.uv-cache" 2>nul
rd /S /Q "%LOCALAPPDATA%\uv" 2>nul
echo  Done.
goto :DONE

:CLEAN_TEMP
echo  Cleaning temp files...
del /Q "%USB_ROOT%\*.tmp" 2>nul
del /Q "%USB_ROOT%\*.log" 2>nul
rd /S /Q "%USB_ROOT%\temp" 2>nul
echo  Done.
goto :DONE

:CLEAN_ALL
echo  Running full cleanup...
del /Q "%USB_ROOT%\logs\*" 2>nul
for /d /r "%USB_ROOT%" %%i in (__pycache__) do rd /S /Q "%%i" 2>nul
del /S /Q "%USB_ROOT%\*.pyc" 2>nul
if exist "%USB_ROOT%\python\Scripts\pip.exe" "%USB_ROOT%\python\Scripts\pip.exe" cache purge 2>nul
if exist "%USB_ROOT%\bin\uv.exe" "%USB_ROOT%\bin\uv.exe" cache clean 2>nul
rd /S /Q "%USB_ROOT%\bin\.uv-cache" 2>nul
rd /S /Q "%USB_ROOT%\python\pip-cache" 2>nul
del /Q "%USB_ROOT%\*.tmp" 2>nul
del /Q "%USB_ROOT%\*.log" 2>nul
echo  Full cleanup done.

:DONE
echo.
pause

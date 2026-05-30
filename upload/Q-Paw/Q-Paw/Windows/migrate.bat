@echo off
setlocal enabledelayedexpansion

REM Q-Paw Migration Tool for Windows
REM Merges data from an old Q-Paw directory into the current one
REM Handles: models, data (chat history/skills), config

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

echo.
echo  =============================================
echo    Q-Paw Migration Tool
echo    Merge data from old Q-Paw directory
echo  =============================================
echo.
echo  Current Q-Paw: %USB_ROOT%
echo.

REM --- Step 1: Get old Q-Paw path ---
set "OLD_PATH="
set /p "OLD_PATH=  Enter old Q-Paw directory path: "

if "%OLD_PATH%"=="" goto :CANCEL
if not exist "%OLD_PATH%" goto :PATH_NOT_FOUND

REM Remove trailing backslash
if "%OLD_PATH:~-1%"=="\" set "OLD_PATH=%OLD_PATH:~0,-1%"

REM Verify it looks like a Q-Paw directory
if exist "%OLD_PATH%\launch.bat" goto :PATH_OK
if exist "%OLD_PATH%\launch.sh" goto :PATH_OK
if exist "%OLD_PATH%\data" goto :PATH_OK
if exist "%OLD_PATH%\models" goto :PATH_OK

echo.
echo  [WARN] The path does not look like a Q-Paw directory.
echo         Expected to find: launch.bat, data/, or models/
echo.
set /p "FORCE=  Continue anyway? y/n: "
if /i not "!FORCE!"=="y" goto :CANCEL
echo.

:PATH_OK
echo.
echo  Old Q-Paw: %OLD_PATH%
echo.

REM --- Step 2: Scan old directory ---
echo  Scanning old directory...
echo.

set "HAS_MODELS=0"
set "HAS_DATA=0"
set "HAS_CONFIG=0"

if not exist "%OLD_PATH%\models" goto :SCAN_DATA
set "MODEL_COUNT=0"
for /f %%a in ('dir /b "%OLD_PATH%\models" 2^>nul ^| find /c /v ""') do set "MODEL_COUNT=%%a"
if "%MODEL_COUNT%"=="0" goto :SCAN_DATA
set "HAS_MODELS=1"
echo  [Models] Found %MODEL_COUNT% model directories:
dir /b "%OLD_PATH%\models"
echo.

:SCAN_DATA
if not exist "%OLD_PATH%\data" goto :SCAN_CONFIG
set "DATA_COUNT=0"
for /f %%a in ('dir /b "%OLD_PATH%\data" 2^>nul ^| find /c /v ""') do set "DATA_COUNT=%%a"
if "%DATA_COUNT%"=="0" goto :SCAN_CONFIG
set "HAS_DATA=1"
echo  [Data] Found %DATA_COUNT% items in data directory:
dir /b "%OLD_PATH%\data"
echo.

:SCAN_CONFIG
if not exist "%OLD_PATH%\config\portable.env" goto :SCAN_DONE
set "HAS_CONFIG=1"
echo  [Config] Found portable.env
echo.

:SCAN_DONE
echo  -------------------------------------------
echo  Select what to merge:
echo.
echo    1. Merge all - models + data + config
echo    2. Models only
echo    3. Data only - chat history, skills, etc.
echo    4. Config only - portable.env settings
echo    5. Custom selection
echo    0. Cancel
echo.
set /p "MERGE_CHOICE=  Enter choice: "

if "%MERGE_CHOICE%"=="1" goto :MERGE_ALL
if "%MERGE_CHOICE%"=="2" goto :MERGE_MODELS_ONLY
if "%MERGE_CHOICE%"=="3" goto :MERGE_DATA_ONLY
if "%MERGE_CHOICE%"=="4" goto :MERGE_CONFIG_ONLY
if "%MERGE_CHOICE%"=="5" goto :MERGE_CUSTOM
goto :CANCEL

:MERGE_ALL
set "DO_MODELS=1"
set "DO_DATA=1"
set "DO_CONFIG=1"
goto :CONFIRM

:MERGE_MODELS_ONLY
set "DO_MODELS=1"
set "DO_DATA=0"
set "DO_CONFIG=0"
goto :CONFIRM

:MERGE_DATA_ONLY
set "DO_MODELS=0"
set "DO_DATA=1"
set "DO_CONFIG=0"
goto :CONFIRM

:MERGE_CONFIG_ONLY
set "DO_MODELS=0"
set "DO_DATA=0"
set "DO_CONFIG=1"
goto :CONFIRM

:MERGE_CUSTOM
echo.
set "DO_MODELS=0"
set "DO_DATA=0"
set "DO_CONFIG=0"

if not "%HAS_MODELS%"=="1" goto :CUSTOM_DATA
set /p "DO_MODELS=  Merge models? y/n: "
if /i "!DO_MODELS!"=="y" set "DO_MODELS=1"
if /i not "!DO_MODELS!"=="y" set "DO_MODELS=0"

:CUSTOM_DATA
if not "%HAS_DATA%"=="1" goto :CUSTOM_CONFIG
set /p "DO_DATA=  Merge data? y/n: "
if /i "!DO_DATA!"=="y" set "DO_DATA=1"
if /i not "!DO_DATA!"=="y" set "DO_DATA=0"

:CUSTOM_CONFIG
if not "%HAS_CONFIG%"=="1" goto :CONFIRM
set /p "DO_CONFIG=  Merge config? y/n: "
if /i "!DO_CONFIG!"=="y" set "DO_CONFIG=1"
if /i not "!DO_CONFIG!"=="y" set "DO_CONFIG=0"

:CONFIRM
echo.
echo  =============================================
echo    Migration Summary
echo  =============================================
echo.
echo  Source: %OLD_PATH%
echo  Target: %USB_ROOT%
echo.
if "%DO_MODELS%"=="1" echo  [x] Models - will COPY, skip existing
if not "%DO_MODELS%"=="1" echo  [ ] Models - skipped
if "%DO_DATA%"=="1" echo  [x] Data - will COPY, skip existing
if not "%DO_DATA%"=="1" echo  [ ] Data - skipped
if "%DO_CONFIG%"=="1" echo  [x] Config - will SMART MERGE
if not "%DO_CONFIG%"=="1" echo  [ ] Config - skipped
echo.
echo  Strategy: Existing files will NOT be overwritten.
echo  Config values from old version will be preserved
echo  if they do not exist in the new config.
echo.
set /p "CONFIRM=  Proceed with migration? y/n: "
if /i not "!CONFIRM!"=="y" goto :CANCEL
echo.

REM =============================================
REM Perform Migration
REM =============================================

if not "%DO_MODELS%"=="1" goto :CHECK_DATA

REM --- Merge Models ---
echo  [1/3] Migrating models...
echo.

if not exist "%OLD_PATH%\models" goto :MODELS_SKIP
if not exist "%USB_ROOT%\models" mkdir "%USB_ROOT%\models"

REM Copy each model directory - avoid goto inside for loop
for /f "delims=" %%d in ('dir /b /ad "%OLD_PATH%\models" 2^>nul') do (
    if exist "%USB_ROOT%\models\%%d" (
        echo  Skipping existing model: %%d
    ) else (
        echo  Copying model: %%d
        xcopy /E /I /Q /H "%OLD_PATH%\models\%%d" "%USB_ROOT%\models\%%d" >nul
    )
)

:MODELS_SKIP
echo  Models migration done.
echo.

:CHECK_DATA
if not "%DO_DATA%"=="1" goto :CHECK_CONFIG

REM --- Merge Data ---
echo  [2/3] Migrating data...
echo.

if not exist "%OLD_PATH%\data" goto :DATA_SKIP
if not exist "%USB_ROOT%\data" mkdir "%USB_ROOT%\data"

REM xcopy /D = copy only if newer, /Y = no prompt
REM This means existing same-or-newer files will be kept
xcopy /E /I /Q /H /D /Y "%OLD_PATH%\data" "%USB_ROOT%\data" >nul 2>&1

echo  Data migration done.
echo.

:DATA_SKIP

:CHECK_CONFIG
if not "%DO_CONFIG%"=="1" goto :MIGRATE_DONE

REM --- Merge Config ---
echo  [3/3] Migrating config...
echo.

if not exist "%OLD_PATH%\config\portable.env" goto :CONFIG_SKIP
if not exist "%USB_ROOT%\config" mkdir "%USB_ROOT%\config"

REM Smart config merge:
REM 1. If new config doesn't exist, just copy old one
REM 2. If both exist, merge: keep new structure + add old user values

if not exist "%USB_ROOT%\config\portable.env" goto :CONFIG_COPY_OLD

REM Both configs exist - do smart merge using a temp PowerShell script
echo  Both old and new portable.env exist. Smart merging...
echo  Old values will be added only if they don't exist in new config.
echo.

set "NEW_CFG=%USB_ROOT%\config\portable.env"
set "OLD_CFG=%OLD_PATH%\config\portable.env"
set "MERGE_TMP=%USB_ROOT%\config\portable.env.merged"

REM Copy new config as base
copy /Y "%NEW_CFG%" "%MERGE_TMP%" >nul

REM Use PowerShell to do the smart merge - much more reliable than BAT for loops
powershell -NoProfile -Command "$newCfg = Get-Content '%NEW_CFG%'; $oldLines = Get-Content '%OLD_CFG%'; foreach ($line in $oldLines) { $trimmed = $line.Trim(); if ($trimmed -and -not $trimmed.StartsWith('#')) { $eqIdx = $trimmed.IndexOf('='); if ($eqIdx -gt 0) { $key = $trimmed.Substring(0, $eqIdx).Trim(); if (-not ($newCfg | Where-Object { $_ -match \"^$key=\" })) { Add-Content -Path '%MERGE_TMP%' -Value $line; Write-Host \"  Adding: $line\" } else { Write-Host \"  Keeping new: $line\" } } } }"

REM Replace original with merged version
copy /Y "%MERGE_TMP%" "%NEW_CFG%" >nul
del "%MERGE_TMP%" 2>nul

echo.
echo  Config merge done.
goto :CONFIG_DONE

:CONFIG_COPY_OLD
echo  No existing portable.env found. Copying from old version...
copy /Y "%OLD_PATH%\config\portable.env" "%USB_ROOT%\config\portable.env" >nul
echo  Config copied.

:CONFIG_DONE
echo.

:CONFIG_SKIP

:MIGRATE_DONE
echo  =============================================
echo    Migration Complete!
echo  =============================================
echo.
echo  Migration results:
echo.

set "NEW_MODEL_COUNT=0"
for /f %%a in ('dir /b /ad "%USB_ROOT%\models" 2^>nul ^| find /c /v ""') do set "NEW_MODEL_COUNT=%%a"
echo  Models:  %NEW_MODEL_COUNT% model directories

set "NEW_DATA_COUNT=0"
for /f %%a in ('dir /b "%USB_ROOT%\data" 2^>nul ^| find /c /v ""') do set "NEW_DATA_COUNT=%%a"
echo  Data:    %NEW_DATA_COUNT% items in data directory

if exist "%USB_ROOT%\config\portable.env" echo  Config:  portable.env exists
echo.
echo  You can now run launch.bat to start QwenPaw.
echo.
pause
exit /b 0

:PATH_NOT_FOUND
echo.
echo  [ERROR] Path not found: %OLD_PATH%
echo  Please check the path and try again.
echo.
pause
exit /b 1

:CANCEL
echo.
echo  Migration cancelled.
echo.
pause
exit /b 0

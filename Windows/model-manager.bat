@echo off
setlocal enabledelayedexpansion

:: Q-Paw Model Manager for Windows
:: Supports uv (fast) + pip (fallback)
:: Uses Chinese mirrors for faster downloads

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages;%USB_ROOT%\qwenpaw-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"
set "QP_MODELS_DIR=%USB_ROOT%\models"

:: Detect package manager
set "UV_EXE=%USB_ROOT%\bin\uv.exe"
set "PKG_CMD=pip"
if exist "%UV_EXE%" set "PKG_CMD=uv"

chcp 65001 >nul 2>&1

:MENU
echo.
echo  =============================================
echo    Q-Paw Model Manager
echo    Package manager: %PKG_CMD%
echo  =============================================
echo.
echo  Models Dir: %QP_MODELS_DIR%
echo.

REM Show installed models
echo  [Installed Models]
set "MODEL_COUNT=0"
for /f %%a in ('dir /b "%QP_MODELS_DIR%" 2^>nul ^| find /c /v ""') do set "MODEL_COUNT=%%a"
if not "%MODEL_COUNT%"=="0" dir /b "%QP_MODELS_DIR%"
if "%MODEL_COUNT%"=="0" echo    ^<empty^> No local models, using online mode
echo.
echo  -------------------------------------------
echo  Choose an action:
echo.
echo    1. Download model from ModelScope
echo    2. Import model from local files
echo    3. Delete installed model
echo    4. Switch online/offline mode
echo    5. Show disk space
echo    6. Install Python package (uv/pip)
echo    7. Configure download mirror
echo    0. Exit
echo.
set /p "CHOICE=  Enter choice: "

if "%CHOICE%"=="1" goto :DOWNLOAD
if "%CHOICE%"=="2" goto :IMPORT
if "%CHOICE%"=="3" goto :DELETE
if "%CHOICE%"=="4" goto :SWITCH_MODE
if "%CHOICE%"=="5" goto :DISK_INFO
if "%CHOICE%"=="6" goto :INSTALL_PKG
if "%CHOICE%"=="7" goto :MIRROR_CFG
if "%CHOICE%"=="0" exit /b 0
goto :MENU

:DOWNLOAD
echo.
echo  --- Download Model ---
echo.
echo  Available models:
echo.
echo    1. QwenPaw-Flash-2B      - about 4GB, recommended
echo    2. Qwen2.5-7B-Instruct   - about 15GB, better quality
echo    3. Qwen2.5-3B-Instruct   - about 6GB, balanced
echo    4. Qwen2.5-1.5B-Instruct - about 3GB, lightweight
echo    5. Custom model - enter ModelScope path
echo    0. Back
echo.
set /p "MODEL_CHOICE=  Select model: "

if "%MODEL_CHOICE%"=="1" goto :DL_1
if "%MODEL_CHOICE%"=="2" goto :DL_2
if "%MODEL_CHOICE%"=="3" goto :DL_3
if "%MODEL_CHOICE%"=="4" goto :DL_4
if "%MODEL_CHOICE%"=="5" goto :DL_CUSTOM
goto :MENU

:DL_1
echo.
echo  Downloading QwenPaw-Flash-2B from ModelScope...
"%PYTHONHOME%\python.exe" -m modelscope download --model AgentScope/QwenPaw-Flash-2B --local_dir "%QP_MODELS_DIR%\QwenPaw-Flash-2B"
echo  Done!
pause
goto :MENU

:DL_2
echo.
echo  Downloading Qwen2.5-7B-Instruct from ModelScope...
"%PYTHONHOME%\python.exe" -m modelscope download --model Qwen/Qwen2.5-7B-Instruct --local_dir "%QP_MODELS_DIR%\Qwen2.5-7B-Instruct"
echo  Done!
pause
goto :MENU

:DL_3
echo.
echo  Downloading Qwen2.5-3B-Instruct from ModelScope...
"%PYTHONHOME%\python.exe" -m modelscope download --model Qwen/Qwen2.5-3B-Instruct --local_dir "%QP_MODELS_DIR%\Qwen2.5-3B-Instruct"
echo  Done!
pause
goto :MENU

:DL_4
echo.
echo  Downloading Qwen2.5-1.5B-Instruct from ModelScope...
"%PYTHONHOME%\python.exe" -m modelscope download --model Qwen/Qwen2.5-1.5B-Instruct --local_dir "%QP_MODELS_DIR%\Qwen2.5-1.5B-Instruct"
echo  Done!
pause
goto :MENU

:DL_CUSTOM
echo.
echo  Enter ModelScope model path (format: org/model-name)
echo  Examples: Qwen/Qwen2.5-14B-Instruct, deepseek-ai/DeepSeek-V3
echo.
set /p "CUSTOM_URL=  Model path: "
set /p "CUSTOM_NAME=  Local name: "
echo  Downloading !CUSTOM_NAME! from ModelScope...
"%PYTHONHOME%\python.exe" -m modelscope download --model !CUSTOM_URL! --local_dir "%QP_MODELS_DIR%\!CUSTOM_NAME!"
echo  Done!
pause
goto :MENU

:IMPORT
echo.
echo  --- Import Local Model ---
echo.
set /p "IMPORT_PATH=  Source directory path: "
if exist "%IMPORT_PATH%" goto :IMPORT_DO
echo  [ERROR] Path not found: %IMPORT_PATH%
pause
goto :MENU

:IMPORT_DO
set /p "IMPORT_NAME=  Model name - for display: "
echo  Copying model files...
xcopy /E /I /Q "%IMPORT_PATH%" "%QP_MODELS_DIR%\%IMPORT_NAME%"
echo  Done!
pause
goto :MENU

:DELETE
echo.
echo  --- Delete Model ---
echo.
echo  Installed models:
dir /b "%QP_MODELS_DIR%"
echo.
set /p "DEL_NAME=  Enter model name to delete: "
if not exist "%QP_MODELS_DIR%\%DEL_NAME%" goto :DELETE_FAIL
rmdir /S /Q "%QP_MODELS_DIR%\%DEL_NAME%"
echo  Deleted: %DEL_NAME%
pause
goto :MENU

:DELETE_FAIL
echo  [ERROR] Model not found: %DEL_NAME%
pause
goto :MENU

:SWITCH_MODE
echo.
echo  --- Switch Mode ---
echo.
findstr /C:"QP_MODEL_MODE=online" "%USB_ROOT%\config\portable.env" >nul
if errorlevel 1 goto :SWITCH_TO_ONLINE

echo  Current: ONLINE mode
set /p "SWITCH=  Switch to offline mode? y/n: "
if /i not "!SWITCH!"=="y" goto :SWITCH_DONE
powershell -Command "(Get-Content '%USB_ROOT%\config\portable.env') -replace 'QP_MODEL_MODE=online','QP_MODEL_MODE=local' | Set-Content '%USB_ROOT%\config\portable.env'"
echo  Switched to offline mode.
goto :SWITCH_DONE

:SWITCH_TO_ONLINE
echo  Current: OFFLINE mode
set /p "SWITCH=  Switch to online mode? y/n: "
if /i not "!SWITCH!"=="y" goto :SWITCH_DONE
powershell -Command "(Get-Content '%USB_ROOT%\config\portable.env') -replace 'QP_MODEL_MODE=local','QP_MODEL_MODE=online' | Set-Content '%USB_ROOT%\config\portable.env'"
echo  Switched to online mode.

:SWITCH_DONE
pause
goto :MENU

:DISK_INFO
echo.
echo  --- Disk Space ---
echo.
for %%d in ("%QP_MODELS_DIR%") do fsutil volume diskfree %%~dd 2>nul | findstr /C:"Available"
dir /s "%QP_MODELS_DIR%" 2>nul | findstr "File(s)"
pause
goto :MENU

:INSTALL_PKG
echo.
echo  --- Install Python Package ---
echo  Using: %PKG_CMD%
echo.
set /p "PKG_NAME=  Package name: "
if "%PKG_NAME%"=="" goto :MENU

if not "%PKG_CMD%"=="uv" goto :INSTALL_PIP

echo  Installing with uv (fast)...
"%UV_EXE%" pip install %PKG_NAME% --python "%PYTHONHOME%\python.exe" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :INSTALL_OK

echo  uv + Aliyun failed, trying uv + Tsinghua...
"%UV_EXE%" pip install %PKG_NAME% --python "%PYTHONHOME%\python.exe" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :INSTALL_OK

echo  uv failed, trying pip fallback...
:INSTALL_PIP
"%PYTHONHOME%\python.exe" -m pip install %PKG_NAME% -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :INSTALL_OK
"%PYTHONHOME%\python.exe" -m pip install %PKG_NAME%
if %errorlevel%==0 goto :INSTALL_OK
echo  [ERROR] Failed to install %PKG_NAME%
pause
goto :MENU

:INSTALL_OK
echo  Installed: %PKG_NAME%
pause
goto :MENU

:MIRROR_CFG
echo.
echo  --- Download Mirror Configuration ---
echo.
echo  Current pip mirror:
"%PYTHONHOME%\python.exe" -m pip config get global.index-url 2>nul || echo  (default)
echo.
echo  Available mirrors:
echo    1. Aliyun        - https://mirrors.aliyun.com/pypi/simple/
echo    2. Tsinghua      - https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/
echo    3. Huawei Cloud  - https://repo.huaweicloud.com/repository/pypi/simple/
echo    4. Official      - https://pypi.org/simple/
echo    0. Back
echo.
set /p "MIRROR_CHOICE=  Select mirror: "

if "%MIRROR_CHOICE%"=="1" goto :SET_ALIYUN
if "%MIRROR_CHOICE%"=="2" goto :SET_TSINGHUA
if "%MIRROR_CHOICE%"=="3" goto :SET_HUAWEI
if "%MIRROR_CHOICE%"=="4" goto :SET_OFFICIAL
goto :MENU

:SET_ALIYUN
"%PYTHONHOME%\python.exe" -m pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
"%PYTHONHOME%\python.exe" -m pip config set global.trusted-host mirrors.aliyun.com
echo  Set to Aliyun mirror!
pause
goto :MENU

:SET_TSINGHUA
"%PYTHONHOME%\python.exe" -m pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/
"%PYTHONHOME%\python.exe" -m pip config set global.trusted-host mirrors.tuna.tsinghua.edu.cn
echo  Set to Tsinghua mirror!
pause
goto :MENU

:SET_HUAWEI
"%PYTHONHOME%\python.exe" -m pip config set global.index-url https://repo.huaweicloud.com/repository/pypi/simple/
"%PYTHONHOME%\python.exe" -m pip config set global.trusted-host repo.huaweicloud.com
echo  Set to Huawei Cloud mirror!
pause
goto :MENU

:SET_OFFICIAL
"%PYTHONHOME%\python.exe" -m pip config unset global.index-url 2>nul
echo  Set to official source!
pause
goto :MENU

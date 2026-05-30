@echo off
:: Q-Paw Setup Script for Windows
:: Package manager: uv (default) + pip (fallback)
:: All downloads use Chinese mirrors for faster speed
:: Models are NOT downloaded by default

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

echo.
echo  =============================================
echo    Q-Paw Setup - Initializing...
echo    Package manager: uv (fast) / pip (fallback)
echo    Mirrors: China-first
echo  =============================================
echo.

:: =============================================
:: Step 1: Install uv (super fast package manager)
:: =============================================
echo  [1/6] Installing uv package manager...

set "UV_BIN=%USB_ROOT%\bin\uv.exe"

if exist "%UV_BIN%" goto :UV_DONE

echo  Downloading uv from GitHub...

REM Try NPMMirror (China) first, then GitHub
set "UV_ZIP=%USB_ROOT%\uv.zip"

echo  Trying NPMMirror (China)...
curl -L -o "%UV_ZIP%" "https://registry.npmmirror.com/-/binary/uv/0.6.6/uv-x86_64-pc-windows-msvc.zip" --connect-timeout 10 -s -f
if not exist "%UV_ZIP%" goto :UV_GH

REM Verify size - at least 5MB
for %%A in ("%UV_ZIP%") do set "UV_SIZE=%%~zA"
if %UV_SIZE% LSS 5000000 goto :UV_GH

echo  NPMMirror OK, extracting...
mkdir "%USB_ROOT%\bin" 2>nul
powershell -Command "Expand-Archive -Path '%UV_ZIP%' -DestinationPath '%USB_ROOT%\bin' -Force"
del "%UV_ZIP%" 2>nul
if exist "%UV_BIN%" goto :UV_OK

:UV_GH
echo  NPMMirror failed, trying GitHub...
curl -L -o "%UV_ZIP%" "https://github.com/astral-sh/uv/releases/download/0.6.6/uv-x86_64-pc-windows-msvc.zip" --connect-timeout 15
if not exist "%UV_ZIP%" goto :UV_FAIL

for %%A in ("%UV_ZIP%") do set "UV_SIZE=%%~zA"
if %UV_SIZE% LSS 5000000 goto :UV_FAIL

mkdir "%USB_ROOT%\bin" 2>nul
powershell -Command "Expand-Archive -Path '%UV_ZIP%' -DestinationPath '%USB_ROOT%\bin' -Force"
del "%UV_ZIP%" 2>nul
if exist "%UV_BIN%" goto :UV_OK

:UV_FAIL
echo.
echo  [WARN] uv download failed, will use pip instead.
del "%UV_ZIP%" 2>nul
set "UV_BIN="
goto :UV_DONE

:UV_OK
echo  OK - uv installed.
:UV_DONE
echo.

:: =============================================
:: Step 2: Portable Python
:: =============================================
echo  [2/6] Checking portable Python...

if exist "%USB_ROOT%\python\python.exe" goto :PY_DONE

echo  Downloading Python 3.11 Embedded 64-bit...

set "PY_ZIP=%USB_ROOT%\python-embed.zip"

echo  Trying NPMMirror (China)...
curl -L -o "%PY_ZIP%" "https://registry.npmmirror.com/-/binary/python/3.11.9/python-3.11.9-embed-amd64.zip" --connect-timeout 10 -s -f
if exist "%PY_ZIP%" goto :PY_VERIFY

echo  Trying Huawei Cloud mirror...
curl -L -o "%PY_ZIP%" "https://repo.huaweicloud.com/python/3.11.9/python-3.11.9-embed-amd64.zip" --connect-timeout 10 -s -f
if exist "%PY_ZIP%" goto :PY_VERIFY

echo  Trying official python.org (may be slow in China)...
curl -L -o "%PY_ZIP%" "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip" --connect-timeout 15
if exist "%PY_ZIP%" goto :PY_VERIFY

goto :PY_DOWNLOAD_FAIL

:PY_VERIFY
for %%A in ("%PY_ZIP%") do set "PY_SIZE=%%~zA"
if %PY_SIZE% LSS 5000000 goto :PY_DOWNLOAD_FAIL

echo  Download OK (%PY_SIZE% bytes)
echo  Extracting Python...
mkdir "%USB_ROOT%\python" 2>nul
powershell -Command "Expand-Archive -Path '%PY_ZIP%' -DestinationPath '%USB_ROOT%\python' -Force"

if not exist "%USB_ROOT%\python\python.exe" goto :PY_EXTRACT_FAIL

del "%PY_ZIP%" 2>nul

REM Enable pip - modify python311._pth
echo  Configuring pip support...
echo python311.zip> "%USB_ROOT%\python\python311._pth"
echo.>> "%USB_ROOT%\python\python311._pth"
echo .>> "%USB_ROOT%\python\python311._pth"
echo Lib>> "%USB_ROOT%\python\python311._pth"
echo Lib\site-packages>> "%USB_ROOT%\python\python311._pth"
echo import site>> "%USB_ROOT%\python\python311._pth"

mkdir "%USB_ROOT%\python\Lib" 2>nul
mkdir "%USB_ROOT%\python\Lib\site-packages" 2>nul

REM Install pip from mirror
echo  Installing pip (Tsinghua mirror)...
curl -L -o "%USB_ROOT%\python\get-pip.py" "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/packages/source/p/pip/pip-24.0-py3-none-any.whl" --connect-timeout 10 -s 2>nul
if not exist "%USB_ROOT%\python\get-pip.py" curl -L -o "%USB_ROOT%\python\get-pip.py" "https://bootstrap.pypa.io/get-pip.py"
"%USB_ROOT%\python\python.exe" "%USB_ROOT%\python\get-pip.py" --no-warn-script-location -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
del "%USB_ROOT%\python\get-pip.py" 2>nul

echo  OK - Portable Python installed.
goto :PY_DONE

:PY_EXTRACT_FAIL
echo  [ERROR] Extraction failed.
del "%PY_ZIP%" 2>nul
pause
exit /b 1

:PY_DOWNLOAD_FAIL
echo  [ERROR] Python download failed from all mirrors.
echo  Please download manually from: https://registry.npmmirror.com/-/binary/python/3.11.9/
del "%PY_ZIP%" 2>nul
pause
exit /b 1

:PY_DONE
echo.

:: Verify python
if not exist "%USB_ROOT%\python\python.exe" goto :PY_MISSING
goto :PY_VERIFY_OK
:PY_MISSING
echo  [ERROR] python.exe not found!
pause
exit /b 1
:PY_VERIFY_OK

:: =============================================
:: Step 3: Install QwenPaw (uv first, pip fallback)
:: =============================================
echo  [3/6] Installing QwenPaw...

"%USB_ROOT%\python\python.exe" -c "import qwenpaw" >nul 2>&1
if %errorlevel%==0 goto :QP_DONE

set "QP_PKG_MGR=none"

REM --- Try uv first ---
if not defined UV_BIN goto :TRY_PIP
if not exist "%UV_BIN%" goto :TRY_PIP

echo  Installing with uv (10-100x faster than pip)...
echo  Mirror: Aliyun

"%UV_BIN%" pip install qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :QP_UV_OK

echo  uv + Aliyun failed, trying uv + Tsinghua...
"%UV_BIN%" pip install qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :QP_UV_OK

echo  uv + Tsinghua failed, trying uv + Huawei Cloud...
"%UV_BIN%" pip install qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :QP_UV_OK

echo  uv + all mirrors failed, falling back to pip...
goto :TRY_PIP

:QP_UV_OK
set "QP_PKG_MGR=uv"
echo  OK - QwenPaw installed via uv.
goto :QP_DONE

REM --- Fallback to pip ---
:TRY_PIP
echo  Installing with pip (fallback)...
echo  Mirror order: Aliyun -^> Tsinghua -^> Huawei -^> Official

"%USB_ROOT%\python\python.exe" -m pip install qwenpaw -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :QP_PIP_OK

echo  Aliyun mirror failed, trying Tsinghua...
"%USB_ROOT%\python\python.exe" -m pip install qwenpaw -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :QP_PIP_OK

echo  Tsinghua failed, trying Huawei Cloud...
"%USB_ROOT%\python\python.exe" -m pip install qwenpaw -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :QP_PIP_OK

echo  All Chinese mirrors failed, trying official...
"%USB_ROOT%\python\python.exe" -m pip install qwenpaw
if %errorlevel%==0 goto :QP_PIP_OK

echo  [ERROR] QwenPaw installation failed! Check your network.
pause
exit /b 1

:QP_PIP_OK
set "QP_PKG_MGR=pip"
echo  OK - QwenPaw installed via pip.

:QP_DONE
echo.

:: =============================================
:: Step 4: Create directory structure
:: =============================================
echo  [4/6] Creating portable directories...
mkdir "%USB_ROOT%\data" 2>nul
mkdir "%USB_ROOT%\config" 2>nul
mkdir "%USB_ROOT%\models" 2>nul
mkdir "%USB_ROOT%\logs" 2>nul
mkdir "%USB_ROOT%\scripts" 2>nul
mkdir "%USB_ROOT%\bin" 2>nul
echo  OK - Directories created.
echo.

:: =============================================
:: Step 5: Generate config
:: =============================================
echo  [5/6] Generating portable config...

if exist "%USB_ROOT%\config\portable.env" goto :CFG_DONE

echo # Q-Paw Portable Config> "%USB_ROOT%\config\portable.env"
echo QP_PORTABLE_MODE=1>> "%USB_ROOT%\config\portable.env"
echo QP_DATA_DIR=%USB_ROOT%\data>> "%USB_ROOT%\config\portable.env"
echo QP_CONFIG_DIR=%USB_ROOT%\config>> "%USB_ROOT%\config\portable.env"
echo QP_MODELS_DIR=%USB_ROOT%\models>> "%USB_ROOT%\config\portable.env"
echo QP_LOG_DIR=%USB_ROOT%\logs>> "%USB_ROOT%\config\portable.env"
echo # Package manager: uv or pip>> "%USB_ROOT%\config\portable.env"
echo QP_PKG_MGR=%QP_PKG_MGR%>> "%USB_ROOT%\config\portable.env"
echo # Model mode: online or local>> "%USB_ROOT%\config\portable.env"
echo QP_MODEL_MODE=online>> "%USB_ROOT%\config\portable.env"
echo # Pip mirror for faster installs>> "%USB_ROOT%\config\portable.env"
echo QP_PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple/>> "%USB_ROOT%\config\portable.env"
echo  OK - Config generated.
goto :CFG_END

:CFG_DONE
echo  OK - Config already exists, skipping.

:CFG_END
echo.

:: =============================================
:: Step 6: Initialize QwenPaw workspace
:: =============================================
echo  [6/6] Initializing QwenPaw workspace...

set "QWENPAW_WORKING_DIR=%USB_ROOT%\data"
set "QWENPAW_SECRET_DIR=%USB_ROOT%\data\.secret"
set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"

if exist "%QWENPAW_WORKING_DIR%\config.json" goto :INIT_DONE

echo  Running qwenpaw init --defaults...
echo  Working directory: %QWENPAW_WORKING_DIR%
"%USB_ROOT%\python\python.exe" -m qwenpaw init --defaults
if %errorlevel%==0 goto :INIT_OK

echo  [WARN] qwenpaw init --defaults failed, trying interactive mode...
"%USB_ROOT%\python\python.exe" -m qwenpaw init
if %errorlevel%==0 goto :INIT_OK

echo  [WARN] QwenPaw init failed. You can run it manually later:
echo         set QWENPAW_WORKING_DIR=%USB_ROOT%\data
echo         python -m qwenpaw init
goto :INIT_DONE

:INIT_OK
echo  OK - QwenPaw workspace initialized.
:INIT_DONE
echo.

:: =============================================
:: Done
:: =============================================
echo  =============================================
echo    Setup Complete!
echo  =============================================
echo.
if defined UV_BIN if exist "%UV_BIN%" (
echo  Package manager: uv (fast mode)
) else (
echo  Package manager: pip (uv not available)
)
echo  Run Windows\launch.bat to start QwenPaw
echo  Run Windows\model-manager.bat to manage models
echo.
echo  [TIP] uv is 10-100x faster than pip.
echo        If uv failed to install, pip works fine too.
echo.
pause

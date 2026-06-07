@echo off
:: Q-Paw Update Script for Windows
:: Updates QwenPaw and modelscope using existing uv or pip
:: uv is NOT updated — keep the bundled version stable
:: Uses Chinese mirrors for faster downloads

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

chcp 65001 >nul 2>&1

echo.
echo  =============================================
echo    Q-Paw Update
echo    Package manager: uv (fast) / pip (fallback)
echo    Mirrors: China-first
echo  =============================================
echo.

:: --- Check Python ---
if not exist "%USB_ROOT%\python\python.exe" goto :NO_PYTHON

set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages;%USB_ROOT%\qwenpaw-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"
set "QWENPAW_WORKING_DIR=%USB_ROOT%\data"
set "QP_PORTABLE_MODE=1"
set "QP_MODELS_DIR=%USB_ROOT%\models"

:: Detect package manager (use bundled uv, don't update it)
set "UV_EXE=%USB_ROOT%\bin\uv.exe"
set "PKG_CMD=pip"
if exist "%UV_EXE%" (
    set "PKG_CMD=uv"
    echo  uv detected:
    "%UV_EXE%" --version
) else (
    echo  uv not found, using pip.
)
echo  Package manager: %PKG_CMD%
echo.

:: --- Step 1: Update QwenPaw ---
echo  [1/2] Updating QwenPaw...

echo  Current version:
"%USB_ROOT%\python\python.exe" -c "import importlib.metadata; print(importlib.metadata.version('qwenpaw'))" 2>nul || echo  (not installed)

if not "%PKG_CMD%"=="uv" goto :UPDATE_QP_PIP

echo  Updating with uv (fast)...
"%UV_EXE%" pip install --upgrade qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :QP_UPDATED

echo  uv + Aliyun failed, trying uv + Tsinghua...
"%UV_EXE%" pip install --upgrade qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :QP_UPDATED

echo  uv + Tsinghua failed, trying uv + ZJU...
"%UV_EXE%" pip install --upgrade qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.zju.edu.cn/pypi/simple/ --trusted-host mirrors.zju.edu.cn
if %errorlevel%==0 goto :QP_UPDATED

echo  uv + ZJU failed, trying uv + Tencent...
"%UV_EXE%" pip install --upgrade qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.cloud.tencent.com/pypi/simple/ --trusted-host mirrors.cloud.tencent.com
if %errorlevel%==0 goto :QP_UPDATED

echo  uv + Tencent failed, trying uv + Huawei Cloud...
"%UV_EXE%" pip install --upgrade qwenpaw --python "%USB_ROOT%\python\python.exe" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :QP_UPDATED

echo  uv failed, falling back to pip...
goto :UPDATE_QP_PIP

:UPDATE_QP_PIP
echo  Updating with pip (fallback)...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :QP_UPDATED

echo  Aliyun mirror failed, trying Tsinghua...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :QP_UPDATED

echo  Tsinghua failed, trying ZJU...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw -i https://mirrors.zju.edu.cn/pypi/simple/ --trusted-host mirrors.zju.edu.cn
if %errorlevel%==0 goto :QP_UPDATED

echo  ZJU failed, trying Tencent...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw -i https://mirrors.cloud.tencent.com/pypi/simple/ --trusted-host mirrors.cloud.tencent.com
if %errorlevel%==0 goto :QP_UPDATED

echo  Tencent failed, trying Huawei Cloud...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :QP_UPDATED

echo  All Chinese mirrors failed, trying official...
"%USB_ROOT%\python\python.exe" -m pip install --upgrade qwenpaw
if %errorlevel%==0 goto :QP_UPDATED

echo  [ERROR] QwenPaw update failed! Check your network.
pause
exit /b 1

:QP_UPDATED
echo.
echo  New version:
"%USB_ROOT%\python\python.exe" -c "import importlib.metadata; print(importlib.metadata.version('qwenpaw'))" 2>nul || echo  (unknown)
echo  OK - QwenPaw updated.
echo.

:: --- Step 2: Update modelscope ---
echo  [2/2] Updating modelscope...

if not "%PKG_CMD%"=="uv" goto :UPDATE_MS_PIP

"%UV_EXE%" pip install --upgrade modelscope --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :MS_UPDATED

"%UV_EXE%" pip install --upgrade modelscope --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :MS_UPDATED

"%UV_EXE%" pip install --upgrade modelscope --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.zju.edu.cn/pypi/simple/ --trusted-host mirrors.zju.edu.cn
if %errorlevel%==0 goto :MS_UPDATED

"%UV_EXE%" pip install --upgrade modelscope --python "%USB_ROOT%\python\python.exe" --index-url https://mirrors.cloud.tencent.com/pypi/simple/ --trusted-host mirrors.cloud.tencent.com
if %errorlevel%==0 goto :MS_UPDATED

"%UV_EXE%" pip install --upgrade modelscope --python "%USB_ROOT%\python\python.exe" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :MS_UPDATED

echo  uv failed, falling back to pip...

:UPDATE_MS_PIP
"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
if %errorlevel%==0 goto :MS_UPDATED

"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn
if %errorlevel%==0 goto :MS_UPDATED

"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope -i https://mirrors.zju.edu.cn/pypi/simple/ --trusted-host mirrors.zju.edu.cn
if %errorlevel%==0 goto :MS_UPDATED

"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope -i https://mirrors.cloud.tencent.com/pypi/simple/ --trusted-host mirrors.cloud.tencent.com
if %errorlevel%==0 goto :MS_UPDATED

"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com
if %errorlevel%==0 goto :MS_UPDATED

"%USB_ROOT%\python\python.exe" -m pip install --upgrade modelscope
if %errorlevel%==0 goto :MS_UPDATED

echo  [WARN] modelscope update failed, but QwenPaw should still work.

:MS_UPDATED
echo  OK - modelscope updated.
echo.

:: --- Done ---
echo  =============================================
echo    Update Complete!
echo  =============================================
echo.
echo  You can now run Windows\launch.bat to start QwenPaw.
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

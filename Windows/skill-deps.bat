@echo off
setlocal enabledelayedexpansion

:: Q-Paw Skill Dependencies Installer
:: Auto-installs Python packages needed by QwenPaw's default skills
:: Package manager: uv (preferred) / pip (fallback)
:: Mirrors: China-first

set "USB_ROOT=%~dp0.."
if "%USB_ROOT:~-1%"=="\" set "USB_ROOT=%USB_ROOT:~0,-1%"

set "PYTHONHOME=%USB_ROOT%\python"
set "PYTHONPATH=%USB_ROOT%\python\Lib;%USB_ROOT%\python\Lib\site-packages"
set "PATH=%USB_ROOT%\python;%USB_ROOT%\python\Scripts;%USB_ROOT%\bin;%PATH%"

:: Redirect caches to USB
set "PIP_CACHE_DIR=%USB_ROOT%\cache\pip"
set "UV_CACHE_DIR=%USB_ROOT%\cache\uv"

:: Detect package manager
set "UV_EXE=%USB_ROOT%\bin\uv.exe"
set "PKG_CMD=pip"
if exist "%UV_EXE%" set "PKG_CMD=uv"

chcp 65001 >nul 2>&1

echo.
echo  ═══════════════════════════════════════════
echo    Q-Paw Skill Dependencies Installer
echo    Package manager: %PKG_CMD%
echo  ═══════════════════════════════════════════
echo.

:: =============================================
:: Define skill dependency groups
:: =============================================

echo  Scanning QwenPaw default skills...
echo.

set "TOTAL_INSTALL=0"
set "TOTAL_SKIP=0"
set "TOTAL_FAIL=0"

:: --- PDF Skill ---
echo  [PDF Skill] pypdf, pdfplumber, reportlab, pdf2image
call :INSTALL_PKG "pypdf"
call :INSTALL_PKG "pdfplumber"
call :INSTALL_PKG "reportlab"
call :INSTALL_PKG "pdf2image"

:: --- DOCX Skill ---
echo.
echo  [DOCX Skill] defusedxml, lxml
call :INSTALL_PKG "defusedxml"
call :INSTALL_PKG "lxml"

:: --- PPTX Skill ---
echo.
echo  [PPTX Skill] markitdown[pptx]
call :INSTALL_PKG "markitdown[pptx]"

:: --- XLSX Skill ---
echo.
echo  [XLSX Skill] openpyxl, pandas
call :INSTALL_PKG "openpyxl"
call :INSTALL_PKG "pandas"

:: --- Common office dependencies (shared by docx/pptx/xlsx) ---
:: defusedxml and lxml already installed above

:: --- Optional: System tools check ---
echo.
echo  ───────────────────────────────────────────
echo  System Tool Check (optional, for full skill support):
echo  ───────────────────────────────────────────
echo.

where pdftotext >nul 2>&1 && (
  echo    pdftotext:   OK
) || (
  echo    pdftotext:   NOT FOUND - install poppler-utils for PDF text extraction
)
where pdftoppm >nul 2>&1 && (
  echo    pdftoppm:    OK
) || (
  echo    pdftoppm:    NOT FOUND - install poppler-utils for PDF/image conversion
)
where soffice >nul 2>&1 && (
  echo    LibreOffice:  OK
) || (
  echo    LibreOffice:  NOT FOUND - install for DOCX/PPTX/XLSX conversion
)
where qpdf >nul 2>&1 && (
  echo    qpdf:        OK
) || (
  echo    qpdf:        NOT FOUND - install for PDF merge/split/decrypt
)
where pandoc >nul 2>&1 && (
  echo    pandoc:      OK
) || (
  echo    pandoc:      NOT FOUND - install for text extraction
)

:: =============================================
:: Summary
:: =============================================
echo.
echo  ═══════════════════════════════════════════
echo    Installation Summary
echo  ═══════════════════════════════════════════
echo.
echo    Installed: %TOTAL_INSTALL%
echo    Skipped:   %TOTAL_SKIP%  (already installed)
echo    Failed:    %TOTAL_FAIL%
echo.
if "%TOTAL_FAIL%"=="0" (
  echo    All Python dependencies installed successfully!
) else (
  echo    Some packages failed. Try running this script again.
)
echo.
echo  NOTE: System tools (LibreOffice, poppler, etc.) need to be
echo        installed separately on the host OS. They are optional
echo        but recommended for full document skill support.
echo.
pause
exit /b 0

:: =============================================
:: Function: Install a Python package
:: =============================================
:INSTALL_PKG
set "PKG=%~1"
:: Check if already installed
"%PYTHONHOME%\python.exe" -c "import %PKG:[=.%" >nul 2>&1 && (
  for /f "tokens=*" %%v in ('"%PYTHONHOME%\python.exe" -c "import %PKG:[=.%; print(%PKG:[=.%.__version__)" 2^>nul') do set "PKG_VER=%%v"
  echo    [SKIP] %PKG% already installed !PKG_VER!
  set /a TOTAL_SKIP+=1
  exit /b 0
)

echo    Installing %PKG% ...

if not "%PKG_CMD%"=="uv" goto :INSTALL_PIP_PKG

:: Try uv first (fast)
"%UV_EXE%" pip install %PKG% --python "%PYTHONHOME%\python.exe" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

"%UV_EXE%" pip install %PKG% --python "%PYTHONHOME%\python.exe" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

"%UV_EXE%" pip install %PKG% --python "%PYTHONHOME%\python.exe" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

echo    uv failed, trying pip fallback...

:INSTALL_PIP_PKG
"%PYTHONHOME%\python.exe" -m pip install %PKG% -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

"%PYTHONHOME%\python.exe" -m pip install %PKG% -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

"%PYTHONHOME%\python.exe" -m pip install %PKG% -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

"%PYTHONHOME%\python.exe" -m pip install %PKG% >nul 2>&1
if %errorlevel%==0 goto :INSTALL_PKG_OK

echo    [FAIL] %PKG% installation failed!
set /a TOTAL_FAIL+=1
exit /b 1

:INSTALL_PKG_OK
echo    [OK]   %PKG% installed
set /a TOTAL_INSTALL+=1
exit /b 0

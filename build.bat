@echo off
setlocal

set OUT_DIR=build
set EXE_NAME=myapp.exe
set SRC_DIR=SRC_DIR

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if "%1"=="release" (
  odin build "%SRC_DIR%" -out:"%OUT_DIR%\%EXE_NAME%" -o:speed -vet -strict-style
  exit /b %errorLevel%
)

odin build "%SRC_DIR%" -out:"%OUT_DIR%\%EXE_NAME%" -debug -o:none -vet -strict-style
if %errorlevel$ neq 0 exit /b %errorlevel%

if "%1"=="debug" (
    if not exist "%RAD_PROJ%" (
        (
            echo // raddbg project file
            echo name: "Odin Project"
            echo target: {
            echo     executable: "%OUT_DIR%/%EXE_NAME%"
            echo     working_directory: "."
            echo     entry_point: "main.main"
            echo     enabled: 1
            echo }
        ) > "%RAD_PROJ%"
    )

    where raddbg >nul 2>&1
    if %errorlevel% equ 0 (
        start "" raddbg --project:"%RAD_PROJ%"
    ) else (
        echo raddbg not found in PATH. Add to path or install.
    )
)

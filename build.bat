@echo off
setlocal

cd /d "%~dp0" || exit /b 1

set "OUT_DIR=build"
set "EXE_NAME=myapp.exe"
set "SRC_DIR=src"
set "RAD_PROJ=myapp.windows.raddbg"

set "OPTIMIZATION=-o:none"
set "SYMBOLS=-debug"
set "RELEASE=0"
set "ACTION=build"

:parse_args
if "%~1"=="" goto configure

if /i "%~1"=="release" (
    set "RELEASE=1"
) else if /i "%~1"=="run" (
    if /i "%ACTION%"=="debug" goto conflicting_args
    set "ACTION=run"
) else if /i "%~1"=="debug" (
    if /i "%ACTION%"=="run" goto conflicting_args
    set "ACTION=debug"
) else (
    echo Unknown argument: %~1 >&2
    exit /b 1
)

shift
goto parse_args

:configure
if "%RELEASE%"=="1" (
    set "OPTIMIZATION=-o:speed"
    set "SYMBOLS="
)

if "%ACTION%"=="debug" set "SYMBOLS=-debug"

:build
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
if errorlevel 1 exit /b %errorlevel%

odin build "%SRC_DIR%" -out:"%OUT_DIR%\%EXE_NAME%" %OPTIMIZATION% %SYMBOLS% -vet -strict-style

if errorlevel 1 exit /b %errorlevel%

if "%ACTION%"=="run" goto run
if "%ACTION%"=="debug" goto debug

exit /b 0

:run
"%OUT_DIR%\%EXE_NAME%"
exit /b %errorlevel%

:debug
where raddbg >nul 2>&1

if errorlevel 1 (
    echo raddbg not found in PATH. >&2
    exit /b 1
)

if not exist "%RAD_PROJ%" (
    (
        echo // raddbg project file
        echo name: "Odin Project"
        echo target: {
        echo     executable: "%OUT_DIR%/%EXE_NAME%"
        echo     working_directory: "."
        echo     enabled: 1
        echo }
    ) > "%RAD_PROJ%"
)

start "" raddbg "%RAD_PROJ%"

exit /b %errorlevel%

:conflicting_args
echo Cannot combine run and debug. >&2
exit /b 1

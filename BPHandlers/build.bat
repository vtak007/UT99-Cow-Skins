@echo off
setlocal EnableExtensions

REM ============================================================================
REM  build.bat - Compile BP1H / BP4H bonus-pack skin handlers for InstaGibPlus
REM
REM  Usage:
REM     build.bat "C:\UnrealTournament" [InstaGibPlus_next-netcode-ef237853]
REM
REM  Arg 1 = UT99 (GOTY, patched to 469) install root - must contain System\ucc.exe
REM  Arg 2 = IG+ package name exactly as on the server (default below).
REM          The handler package names are derived from it, because IG+ looks
REM          for BP1H<PackageVersion> / BP4H<PackageVersion> at runtime.
REM
REM  Requirements inside <UT_ROOT>\System before running:
REM     - ucc.exe from the 469 patch
REM     - <IGP_PACKAGE>.u and its companions from the IG+ release zip
REM       (InstaGibPlusAssets_v2.u, BaseCylinder.u, BaseCylinder2.u,
REM        HeadCylinder.u)
REM     - Stock GOTY files: MultiMesh.u, EpicCustomModels.u, SkeletalChars.u
REM ============================================================================

set "UT=%~1"
set "IGP=%~2"
if "%UT%"=="" (
    echo ERROR: Pass the UT root directory as the first argument.
    echo Example: build.bat "C:\UnrealTournament"
    exit /b 1
)
if "%IGP%"=="" set "IGP=InstaGibPlus_next-netcode-ef237853"

if not exist "%UT%\System\ucc.exe" (
    echo ERROR: "%UT%\System\ucc.exe" not found.
    exit /b 1
)
if not exist "%UT%\System\%IGP%.u" (
    echo ERROR: "%UT%\System\%IGP%.u" not found.
    echo Copy the IG+ release System files into "%UT%\System" first.
    exit /b 1
)

REM Derive the version suffix: InstaGibPlus_next-netcode-ef237853 -> next-netcode-ef237853
set "VER=%IGP:InstaGibPlus_=%"
set "BP1=BP1H%VER%"
set "BP4=BP4H%VER%"
set "SRC=%~dp0Source"
set "OUT=%~dp0Output"
set "MAKEINI=BPHMake.ini"

echo.
echo === Building %BP1%.u and %BP4%.u against %IGP% ===
echo.

REM --- Stage sources into package folders named after the IG+ version ---
if exist "%UT%\%BP1%" rmdir /s /q "%UT%\%BP1%"
if exist "%UT%\%BP4%" rmdir /s /q "%UT%\%BP4%"
mkdir "%UT%\%BP1%\Classes"
mkdir "%UT%\%BP4%\Classes"
copy /y "%SRC%\BP1H\Classes\*.uc" "%UT%\%BP1%\Classes\" >nul
copy /y "%SRC%\BP4H\Classes\*.uc" "%UT%\%BP4%\Classes\" >nul

REM --- Remove stale outputs (ucc make skips packages that already exist) ---
if exist "%UT%\System\%BP1%.u" del "%UT%\System\%BP1%.u"
if exist "%UT%\System\%BP4%.u" del "%UT%\System\%BP4%.u"

REM --- Generate a minimal make ini ---
(
    echo [Engine.Engine]
    echo EditorEngine=Editor.EditorEngine
    echo.
    echo [Core.System]
    echo CachePath=..\Cache
    echo CacheExt=.uxx
    echo Paths=..\System\*.u
    echo Paths=..\Maps\*.unr
    echo Paths=..\Textures\*.utx
    echo Paths=..\Sounds\*.uax
    echo Paths=..\Music\*.umx
    echo.
    echo [Editor.EditorEngine]
    echo CacheSizeMegs=32
    echo EditPackages=Core
    echo EditPackages=Engine
    echo EditPackages=Editor
    echo EditPackages=UWindow
    echo EditPackages=Fire
    echo EditPackages=IpDrv
    echo EditPackages=UWeb
    echo EditPackages=UBrowser
    echo EditPackages=UnrealShare
    echo EditPackages=UnrealI
    echo EditPackages=UMenu
    echo EditPackages=IpServer
    echo EditPackages=Botpack
    echo EditPackages=UTServerAdmin
    echo EditPackages=UTMenu
    echo EditPackages=UTBrowser
    echo EditPackages=MultiMesh
    echo EditPackages=EpicCustomModels
    echo EditPackages=SkeletalChars
    echo EditPackages=%IGP%
    echo EditPackages=%BP1%
    echo EditPackages=%BP4%
) > "%UT%\System\%MAKEINI%"

REM --- Compile ---
pushd "%UT%\System"
"%UT%\System\ucc.exe" make ini=%MAKEINI%
set "RC=%ERRORLEVEL%"
popd

if not exist "%UT%\System\%BP1%.u" (
    echo.
    echo BUILD FAILED - %BP1%.u was not produced. Check "%UT%\System\ucc.log".
    exit /b 1
)
if not exist "%UT%\System\%BP4%.u" (
    echo.
    echo BUILD FAILED - %BP4%.u was not produced. Check "%UT%\System\ucc.log".
    exit /b 1
)

REM --- Collect output + make .uz files for the redirect server ---
if not exist "%OUT%" mkdir "%OUT%"
copy /y "%UT%\System\%BP1%.u" "%OUT%\" >nul
copy /y "%UT%\System\%BP4%.u" "%OUT%\" >nul

pushd "%UT%\System"
"%UT%\System\ucc.exe" compress %BP1%.u
"%UT%\System\ucc.exe" compress %BP4%.u
popd
if exist "%UT%\System\%BP1%.u.uz" copy /y "%UT%\System\%BP1%.u.uz" "%OUT%\" >nul
if exist "%UT%\System\%BP4%.u.uz" copy /y "%UT%\System\%BP4%.u.uz" "%OUT%\" >nul

echo.
echo === SUCCESS ===
echo Compiled files copied to: %OUT%
echo   %BP1%.u  (+ .uz for the redirect)
echo   %BP4%.u  (+ .uz for the redirect)
echo.
echo Next steps: see README.md (server ini changes + upload).
exit /b 0

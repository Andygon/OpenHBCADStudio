@ECHO OFF
REM ======================================================================
REM OpenHBCADStudio - build64.bat
REM Construye OpenHBCADStudio.exe (GUI x64) con Harbour + FiveWin64 + MSVC22.
REM Receta basada en samples\buildh64.bat oficial de FiveTech Software.
REM Uso: build64.bat [clean]
REM ======================================================================
setlocal
call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
if ERRORLEVEL 1 goto NOENV
cd /d "%~dp0"
if "%HBDIR%" == "" set "HBDIR=C:\PRG\HB\HB_64_MSVC22"
if "%FWDIR%" == "" set "FWDIR=C:\PRG\FWH\fwh2605\fwh64"
set "HDIR=%HBDIR%"
set "HDIRL=%HDIR%\lib\win\msvc64"
set "FWI=%FWDIR%"
if /i "%1" == "clean" goto CLEAN

if not exist obj mkdir obj
set HBERR=0
for /f "usebackq delims=" %%F in ("SOURCES.lst") do call :COMPILE "%%F"
if not "%HBERR%" == "0" goto CERR
echo --- C kernel (MSVC22, O2) ---
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 -D__FLAT__ -I%FWI%\include csrc\ocad_geom.c -Foobj\ocad_geom.obj
if ERRORLEVEL 1 goto CERR
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 -D__FLAT__ -I%FWI%\include csrc\ocad_dxf.c -Foobj\ocad_dxf.obj
if ERRORLEVEL 1 goto CERR
echo --- Recursos ---
rc -r -D__64__ resources\OpenHBCADStudio.rc
if ERRORLEVEL 1 goto CERR
echo --- Enlazando OpenHBCADStudio.exe ---
call :LINK OpenHBCADStudio.exe windows
if ERRORLEVEL 1 goto LERR
echo * OpenHBCADStudio.exe construido correctamente *
goto END

:COMPILE
set "REL=%~1"
set "OBJ=%REL:\=_%"
set "OBJ=%OBJ:.prg=%.obj%"
if exist "obj\%OBJ%" goto UP2DATE
echo [%REL%]
%HDIR%\bin\win\msvc64\harbour "%REL%" /n /iinclude;%FWI%\include;%HDIR%\include /w /p /d__64__ /dFWH_CC_MSVC64 /oobj\ > comp_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
goto CLONE
:UP2DATE
if exist "obj\%OBJ%" goto :eof
:CLONE
set "CFILE=%~n1.c"
if not exist "obj\%CFILE%" goto CERR_MISS
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 -D__FLAT__ -I%FWI%\include "obj\%CFILE%" -Fo"obj\%OBJ%" > cl_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
del "obj\%CFILE%" >NUL 2>&1
goto :eof
:CERR_ONE
echo * ERROR compilando %REL% *
type comp_one.log
type cl_one.log
set HBERR=1
goto :eof
:CERR_MISS
echo * Falta obj\%CFILE% para %REL% *
set HBERR=1
goto :eof

:LINK
set "OUT=%~1"
set "SUB=%~2"
echo obj\ohbcad.obj > msvc.tmp
for %%O in (obj\*.obj) do echo %%O | findstr /V /I "ohbcad tests_smoke tscan" >> msvc.tmp
echo %FWI%\lib\FiveH64.lib %FWI%\lib\FiveHC64.lib %FWI%\lib\libmariadb64.lib >> msvc.tmp
echo %FWI%\lib\hbhpdf64.lib >> msvc.tmp
echo %FWI%\lib\libhpdf64.lib >> msvc.tmp
echo %HDIRL%\hbrtl.lib  >> msvc.tmp
echo %HDIRL%\hbvm.lib  >> msvc.tmp
echo %HDIRL%\gtgui.lib  >> msvc.tmp
echo %HDIRL%\hblang.lib  >> msvc.tmp
echo %HDIRL%\hbmacro.lib  >> msvc.tmp
echo %HDIRL%\hbrdd.lib  >> msvc.tmp
echo %HDIRL%\rddntx.lib  >> msvc.tmp
echo %HDIRL%\rddcdx.lib  >> msvc.tmp
echo %HDIRL%\rddfpt.lib  >> msvc.tmp
echo %HDIRL%\hbsix.lib  >> msvc.tmp
echo %HDIRL%\hbdebug.lib  >> msvc.tmp
echo %HDIRL%\hbcommon.lib  >> msvc.tmp
echo %HDIRL%\hbpp.lib  >> msvc.tmp
echo %HDIRL%\hbcpage.lib  >> msvc.tmp
echo %HDIRL%\hbwin.lib  >> msvc.tmp
echo %HDIRL%\hbct.lib  >> msvc.tmp
echo %HDIRL%\hbziparc.lib >> msvc.tmp
echo %HDIRL%\hbmzip.lib >> msvc.tmp
echo %HDIRL%\hbzlib.lib >> msvc.tmp
echo %HDIRL%\hbpcre.lib >> msvc.tmp
echo %HDIRL%\minizip.lib >> msvc.tmp
echo %HDIRL%\xhb.lib >> msvc.tmp
echo %HDIRL%\hbcplr.lib >> msvc.tmp
echo %HDIRL%\png.lib >> msvc.tmp
echo %HDIRL%\hbtip.lib >> msvc.tmp
echo %HDIRL%\hbzebra.lib >> msvc.tmp
echo %HDIRL%\hbcurl.lib >> msvc.tmp
echo %HDIRL%\libcurl.lib >> msvc.tmp
echo kernel32.lib  >> msvc.tmp
echo user32.lib    >> msvc.tmp
echo gdi32.lib     >> msvc.tmp
echo winspool.lib  >> msvc.tmp
echo comctl32.lib  >> msvc.tmp
echo comdlg32.lib  >> msvc.tmp
echo advapi32.lib  >> msvc.tmp
echo shell32.lib   >> msvc.tmp
echo ole32.lib     >> msvc.tmp
echo oleaut32.lib  >> msvc.tmp
echo uuid.lib      >> msvc.tmp
echo odbc32.lib    >> msvc.tmp
echo odbccp32.lib  >> msvc.tmp
echo iphlpapi.lib  >> msvc.tmp
echo mpr.lib       >> msvc.tmp
echo version.lib   >> msvc.tmp
echo wsock32.lib   >> msvc.tmp
echo msimg32.lib   >> msvc.tmp
echo oledlg.lib    >> msvc.tmp
echo psapi.lib     >> msvc.tmp
echo gdiplus.lib   >> msvc.tmp
echo winmm.lib     >> msvc.tmp
echo vfw32.lib     >> msvc.tmp
echo ws2_32.lib    >> msvc.tmp
echo strmiids.lib  >> msvc.tmp
echo ucrt.lib      >> msvc.tmp
echo UxTheme.lib   >> msvc.tmp
if exist resources\OpenHBCADStudio.res echo resources\OpenHBCADStudio.res >> msvc.tmp
link @msvc.tmp /OUT:%OUT% /nologo /subsystem:%SUB% /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
goto :eof

:CLEAN
del /q obj\*.obj obj\*.c 2>NUL
del /q msvc.tmp comp_one.log cl_one.log 2>NUL
del /q resources\*.res 2>NUL
del /q OpenHBCADStudio.exe smoke.exe 2>NUL
echo * Limpio *
goto END
:NOENV
echo * No se pudo inicializar MSVC22 (vcvarsall) *
goto END
:CERR
echo * ERRORES DE COMPILACION *
goto END
:LERR
echo * ERROR DE ENLAZADO *
goto END
:END
endlocal

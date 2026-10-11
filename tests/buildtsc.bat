@ECHO OFF
REM Mini-test del escaner DXF en C
setlocal
call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
cd /d "%~dp0\.."
if "%HBDIR%" == "" set "HBDIR=C:\PRG\HB\HB_64_MSVC22"
set "HDIR=%HBDIR%"
set "HDIRL=%HDIR%\lib\win\msvc64"
if not exist obj mkdir obj
%HDIR%\bin\win\msvc64\harbour tests\tscan.prg /n /iinclude;%HDIR%\include /w /p /d__64__ /oobj\ > comp_one.log 2>&1
if ERRORLEVEL 1 goto CERR
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 "obj\tscan.c" -Fo"obj\tscan.obj" > cl_one.log 2>&1
if ERRORLEVEL 1 goto CERR
del "obj\tscan.c" >NUL 2>&1
echo obj\tscan.obj > ts.tmp
echo obj\ocad_dxf.obj >> ts.tmp
echo obj\ocad_geom.obj >> ts.tmp
echo %HDIRL%\hbrtl.lib >> ts.tmp
echo %HDIRL%\hbvm.lib >> ts.tmp
echo %HDIRL%\gtwin.lib >> ts.tmp
echo %HDIRL%\gtgui.lib >> ts.tmp
echo %HDIRL%\hblang.lib >> ts.tmp
echo %HDIRL%\hbmacro.lib >> ts.tmp
echo %HDIRL%\hbrdd.lib >> ts.tmp
echo %HDIRL%\rddntx.lib >> ts.tmp
echo %HDIRL%\rddfpt.lib >> ts.tmp
echo %HDIRL%\hbsix.lib >> ts.tmp
echo %HDIRL%\hbcommon.lib >> ts.tmp
echo %HDIRL%\hbpp.lib >> ts.tmp
echo %HDIRL%\hbpcre.lib >> ts.tmp
echo %HDIRL%\xhb.lib >> ts.tmp
echo kernel32.lib >> ts.tmp
echo user32.lib >> ts.tmp
echo gdi32.lib >> ts.tmp
echo advapi32.lib >> ts.tmp
echo shell32.lib >> ts.tmp
echo ole32.lib >> ts.tmp
echo version.lib >> ts.tmp
echo winmm.lib >> ts.tmp
echo ucrt.lib >> ts.tmp
link @ts.tmp /OUT:tscan.exe /nologo /subsystem:console /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
if ERRORLEVEL 1 goto LERR
echo --- run ---
tscan.exe
goto END
:CERR
echo * COMPILE ERROR *
type comp_one.log
type cl_one.log
goto END
:LERR
echo * LINK ERROR *
:END
endlocal

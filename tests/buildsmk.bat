@ECHO OFF
REM ======================================================================
REM OpenHBCADStudio - tests/buildsmk.bat : test consola smoke.exe (x64)
REM Misma receta MSVC22 que ..\build64.bat, subsistema consola.
REM ======================================================================
setlocal
call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
if ERRORLEVEL 1 goto NOENV
cd /d "%~dp0\.."
if "%HBDIR%" == "" set "HBDIR=C:\PRG\HB\HB_64_MSVC22"
if "%FWDIR%" == "" set "FWDIR=C:\PRG\FWH\fwh2605\fwh64"
set "HDIR=%HBDIR%"
set "HDIRL=%HDIR%\lib\win\msvc64"
set "FWI=%FWDIR%"
if not exist obj mkdir obj
set HBERR=0
call :ONE tests\smoke.prg
call :ONE src\sys_core.prg
call :ONE src\geom.prg
call :ONE src\entities\ent_base.prg
call :ONE src\entities\ent_draw.prg
call :ONE src\entities\ent_extra.prg
call :ONE src\scene\doc.prg
call :ONE src\io\dxf_io.prg
call :ONE src\ui\cad_canvas.prg
call :ONE src\ui\cmdline.prg
call :ONE src\ui\mainwin.prg
call :ONE src\app\commands.prg
call :ONE src\modules\draw\draw_cmds.prg
call :ONE src\modules\draw\modify_cmds.prg
call :ONE src\modules\draw\inquiry_cmds.prg
if not "%HBERR%" == "0" goto CERR
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 -D__FLAT__ -I%FWI%\include csrc\ocad_geom.c -Foobj\ocad_geom.obj
if ERRORLEVEL 1 goto CERR
cl -TC -W3 -O2 -c -I%HDIR%\include -D_WIN64 -D__FLAT__ -I%FWI%\include csrc\ocad_dxf.c -Foobj\ocad_dxf.obj
if ERRORLEVEL 1 goto CERR
echo obj\tests_smoke.obj > smk.tmp
echo obj\src_sys_core.obj >> smk.tmp
echo obj\src_geom.obj >> smk.tmp
echo obj\src_entities_ent_base.obj >> smk.tmp
echo obj\src_entities_ent_draw.obj >> smk.tmp
echo obj\src_entities_ent_extra.obj >> smk.tmp
echo obj\src_scene_doc.obj >> smk.tmp
echo obj\src_io_dxf_io.obj >> smk.tmp
echo obj\src_ui_cad_canvas.obj >> smk.tmp
echo obj\src_ui_cmdline.obj >> smk.tmp
echo obj\src_ui_mainwin.obj >> smk.tmp
echo obj\src_app_commands.obj >> smk.tmp
echo obj\src_modules_draw_draw_cmds.obj >> smk.tmp
echo obj\src_modules_draw_modify_cmds.obj >> smk.tmp
echo obj\src_modules_draw_inquiry_cmds.obj >> smk.tmp
echo obj\ocad_geom.obj >> smk.tmp
echo obj\ocad_dxf.obj >> smk.tmp
echo %FWI%\lib\FiveH64.lib %FWI%\lib\FiveHC64.lib >> smk.tmp
echo %HDIRL%\hbrtl.lib >> smk.tmp
echo %HDIRL%\hbvm.lib >> smk.tmp
echo %HDIRL%\gtgui.lib >> smk.tmp
echo %HDIRL%\hblang.lib >> smk.tmp
echo %HDIRL%\hbmacro.lib >> smk.tmp
echo %HDIRL%\hbrdd.lib >> smk.tmp
echo %HDIRL%\rddntx.lib >> smk.tmp
echo %HDIRL%\rddcdx.lib >> smk.tmp
echo %HDIRL%\rddfpt.lib >> smk.tmp
echo %HDIRL%\hbsix.lib >> smk.tmp
echo %HDIRL%\hbdebug.lib >> smk.tmp
echo %HDIRL%\hbcommon.lib >> smk.tmp
echo %HDIRL%\hbpp.lib >> smk.tmp
echo %HDIRL%\hbcpage.lib >> smk.tmp
echo %HDIRL%\hbwin.lib >> smk.tmp
echo %HDIRL%\hbct.lib >> smk.tmp
echo %HDIRL%\hbziparc.lib >> smk.tmp
echo %HDIRL%\hbmzip.lib >> smk.tmp
echo %HDIRL%\hbzlib.lib >> smk.tmp
echo %HDIRL%\hbpcre.lib >> smk.tmp
echo %HDIRL%\minizip.lib >> smk.tmp
echo %HDIRL%\xhb.lib >> smk.tmp
echo %HDIRL%\hbcplr.lib >> smk.tmp
echo %HDIRL%\png.lib >> smk.tmp
echo kernel32.lib >> smk.tmp
echo user32.lib >> smk.tmp
echo gdi32.lib >> smk.tmp
echo winspool.lib >> smk.tmp
echo comctl32.lib >> smk.tmp
echo comdlg32.lib >> smk.tmp
echo advapi32.lib >> smk.tmp
echo shell32.lib >> smk.tmp
echo ole32.lib >> smk.tmp
echo oleaut32.lib >> smk.tmp
echo uuid.lib >> smk.tmp
echo odbc32.lib >> smk.tmp
echo odbccp32.lib >> smk.tmp
echo iphlpapi.lib >> smk.tmp
echo mpr.lib >> smk.tmp
echo version.lib >> smk.tmp
echo wsock32.lib >> smk.tmp
echo ws2_32.lib >> smk.tmp
echo msimg32.lib >> smk.tmp
echo oledlg.lib >> smk.tmp
echo psapi.lib >> smk.tmp
echo gdiplus.lib >> smk.tmp
echo winmm.lib >> smk.tmp
echo ucrt.lib >> smk.tmp
echo UxTheme.lib >> smk.tmp
link @smk.tmp /OUT:smoke.exe /nologo /subsystem:console /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
if ERRORLEVEL 1 goto LERR
echo --- ejecutando smoke.exe ---
smoke.exe
goto END

:ONE
set "REL=%~1"
set "OBJ=%REL:\=_%"
set "OBJ=%OBJ:.prg=%.obj%"
echo [%REL%]
%HDIR%\bin\win\msvc64\harbour "%REL%" /n /iinclude;%FWI%\include;%HDIR%\include /w /p /d__64__ /dFWH_CC_MSVC64 /oobj\ > comp_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
set "CFILE=%~n1.c"
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

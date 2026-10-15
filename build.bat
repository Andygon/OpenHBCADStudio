@ECHO OFF
REM ======================================================================
REM OpenHBCADStudio - build.bat
REM Equivalente Windows de build.sh: compila y enlaza la SUITE DE TESTS
REM (tests\t_main.prg + src\codec, src\geom2d, src\space, src\tessellation,
REM csrc\ocx_math.c) con Harbour + MSVC 2022 x64 y la ejecuta.
REM Con USE_FW=1 compila en cambio la APLICACION GUI completa (ohbcad.prg +
REM todos los .prg de SOURCES.lst + csrc\*.c) y la enlaza con FiveWin 64
REM (obj_a\, OpenHBCADStudio.exe). No se ejecuta (es GUI).
REM Resultado esperado al final:  RESULTADO: N ok, 0 fallos  /  OCX-ALL-OK
REM
REM Uso (desde cualquier carpeta):  build.bat [clean] [norun] [USE_FW=1]
REM   GUI:    build.bat USE_FW=1 norun   ->  OpenHBCADStudio.exe en la raiz del repo
REM   Tests:  build.bat                  ->  t_ocx.exe en la raiz (se ejecuta)
REM
REM VARIABLES A AJUSTAR (se pueden definir antes de llamar al .bat, o editar
REM los valores por defecto de abajo):
REM   HBROOT   Harbour compilado con MSVC64. Debe contener
REM            bin\win\msvc64\harbour.exe, include\ y lib\win\msvc64\*.lib
REM            (por defecto C:\PRG\HB\HB_64_MSVC22; tambien se acepta
REM            HARBOUR_DIR / HBDIR si estan definidas y HBROOT no).
REM   FWH_DIR  FiveWin 26.03 64 bit (carpeta fwh64, con include\ y lib\)
REM            (por defecto C:\PRG\FWH\fwh2605\fwh64; tambien FWDIR).
REM            Sus cabeceras se anaden al /i de Harbour. Las pruebas son
REM            consola pura y NO necesitan las lib de FiveWin: por defecto
REM            USE_FW=0. Con USE_FW=1 se enlazan ademas FiveH64.lib y
REM            FiveHC64.lib (carpeta FWH_DIR\lib).
REM   VSVARS   vcvarsall.bat de Visual Studio 2022
REM            (por defecto Community; ajustar a Professional/Enterprise/
REM            BuildTools si hace falta). Si ya estas en un "x64 Native Tools
REM            Command Prompt" (cl en el PATH) se omite.
REM   HBGT     WIN (por defecto: salida en la ventana de consola) o STD (salida
REM            por stdout, redirigible: "build.bat > log.txt"; necesario bajo Wine).
REM   OUTEXE   ejecutable resultante (por defecto t_ocx.exe en la raiz; con
REM            USE_FW=1, OpenHBCADStudio.exe)
REM
REM LIBRERIAS QUE DEBE TENER EL HARBOUR DEL USUARIO (HBROOT\lib\win\msvc64):
REM   Siempre:  hbvm hbrtl gtwin gtstd hblang hbmacro hbrdd rddntx rddcdx rddfpt
REM             hbsix hbdebug hbcommon hbpp hbcpage hbpcre hbzlib
REM   USE_FW=1 (ademas, contribs compiladas con MSVC64): hbcplr hbct hbwin xhb
REM             hbziparc hbmzip (+ gtgui). xhb lo exige la propia FiveH64.lib
REM             (I18N, NOTIFY, TXMLDOCUMENT); hbct aporta SIN/COS/FLOOR/TOKEN...;
REM             hbwin las WAPI_* y OLE; hbmzip/hbziparc las HB_UNZIP*.
REM   Y de FWH_DIR\lib: FiveH64.lib FiveHC64.lib libmariadb64.lib hbhpdf64.lib
REM             libhpdf64.lib.
REM Notas: fuentes en UTF-8 (/ku). Los tests leen tests\fixtures\*.dxf con
REM rutas relativas: el .bat ya hace cd a la raiz del repo. Para ver bien los
REM acentos en consola: chcp 65001 antes de ejecutar.
REM Los objetos van a obj_t\ (se reutilizan; usar "clean" para rehacerlos).
REM ======================================================================
setlocal
cd /d "%~dp0"
if "%HBROOT%" == "" if not "%HARBOUR_DIR%" == "" set "HBROOT=%HARBOUR_DIR%"
if "%HBROOT%" == "" if not "%HBDIR%" == "" set "HBROOT=%HBDIR%"
if "%HBROOT%" == "" set "HBROOT=C:\PRG\HB\HB_64_MSVC22"
if "%FWH_DIR%" == "" if not "%FWDIR%" == "" set "FWH_DIR=%FWDIR%"
if "%FWH_DIR%" == "" set "FWH_DIR=C:\PRG\FWH\fwh2605\fwh64"
if /i "%1" == "USE_FW=1" set "USE_FW=1"
if /i "%2" == "USE_FW=1" set "USE_FW=1"
if /i "%3" == "USE_FW=1" set "USE_FW=1"
if "%USE_FW%" == "" set "USE_FW=0"
if "%OUTEXE%" == "" if "%USE_FW%" == "1" set "OUTEXE=OpenHBCADStudio.exe"
if "%OUTEXE%" == "" set "OUTEXE=t_ocx.exe"
set "HBW=/w3 /es2"
if "%HBGT%" == "" set "HBGT=WIN"
if "%VSVARS%" == "" set "VSVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
set "HBBIN=%HBROOT%\bin\win\msvc64"
set "HBINC=%HBROOT%\include"
set "HBLIB=%HBROOT%\lib\win\msvc64"
set "OBJD=obj_t"
if "%USE_FW%" == "1" set "OBJD=obj_a"
if "%USE_FW%" == "1" set "HBW=/w0"

if /i "%1" == "clean" goto CLEAN
set "NORUN=0"
if /i "%1" == "norun" set "NORUN=1"
if /i "%2" == "norun" set "NORUN=1"
if /i "%3" == "norun" set "NORUN=1"

if not exist "%HBBIN%\harbour.exe" goto NOHB
cl /? >NUL 2>&1
if not ERRORLEVEL 1 goto HAVECL
if not exist "%VSVARS%" goto NOENV
call "%VSVARS%" amd64
if ERRORLEVEL 1 goto NOENV
:HAVECL
if not exist "%OBJD%" mkdir "%OBJD%"
set HBERR=0
set "FWINC="
if exist "%FWH_DIR%\include" set "FWINC=;%FWH_DIR%\include"

echo === Harbour + cl: fuentes ===
if "%USE_FW%" == "1" goto APPSRC
for %%F in (tests\*.prg) do call :ONE "%%F"
call :ONE "src\tessellation.prg"
for %%F in (src\space\*.prg) do call :ONE "%%F"
for %%F in (src\geom2d\*.prg) do call :ONE "%%F"
for %%F in (src\codec\*.prg) do call :ONE "%%F"
for %%F in (src\view\*.prg) do call :ONE "%%F"
if not "%HBERR%" == "0" goto CERR
if /i not "%HBGT%" == "STD" del "%OBJD%\obj_t_gtstub.obj" >NUL 2>&1
if /i "%HBGT%" == "STD" call :GTSTUB
if not "%HBERR%" == "0" goto CERR
goto CSRC
:APPSRC
for /f "usebackq delims=" %%F in ("SOURCES.lst") do call :ONE "%%F"
call :ONE "src\tessellation.prg"
for %%F in (src\space\*.prg) do call :ONE "%%F"
for %%F in (src\geom2d\*.prg) do call :ONE "%%F"
for %%F in (src\codec\*.prg) do call :ONE "%%F"
for %%F in (src\view\*.prg) do call :ONE "%%F"
if not "%HBERR%" == "0" goto CERR
:CSRC

echo === C: csrc\*.c ===
for %%C in (ocx_math ocad_geom ocad_dxf ocad_win) do call :ONEC %%C
if not "%HBERR%" == "0" goto CERR

echo === Enlazando %OUTEXE% ===
if exist lnk_t.tmp del lnk_t.tmp
for %%O in (%OBJD%\*.obj) do echo %%O>> lnk_t.tmp
if "%USE_FW%" == "1" goto LNKAPP
for %%L in (hbvm hbrtl gtwin gtstd hblang hbmacro hbrdd rddntx rddcdx rddfpt hbsix hbdebug hbcommon hbpp hbcpage hbpcre hbzlib) do echo "%HBLIB%\%%L.lib">> lnk_t.tmp
for %%L in (kernel32 user32 gdi32 winspool comctl32 comdlg32 advapi32 shell32 ole32 oleaut32 uuid odbc32 odbccp32 iphlpapi mpr version wsock32 ws2_32 msimg32 oledlg psapi gdiplus winmm ucrt UxTheme) do echo %%L.lib>> lnk_t.tmp
link @lnk_t.tmp /OUT:%OUTEXE% /nologo /subsystem:console /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
if ERRORLEVEL 1 goto LERR
goto LNKOK
:LNKAPP
for %%L in (FiveH64 FiveHC64 libmariadb64 hbhpdf64 libhpdf64) do echo "%FWH_DIR%\lib\%%L.lib">> lnk_t.tmp
for %%L in (xhb hbct hbwin hbziparc hbmzip hbcplr hbvm hbrtl gtwin gtgui gtstd hblang hbmacro hbrdd rddntx rddcdx rddfpt hbsix hbdebug hbcommon hbpp hbcpage hbpcre hbzlib) do echo "%HBLIB%\%%L.lib">> lnk_t.tmp
for %%L in (kernel32 user32 gdi32 winspool comctl32 comdlg32 advapi32 shell32 ole32 oleaut32 uuid odbc32 odbccp32 iphlpapi mpr version wsock32 ws2_32 msimg32 oledlg psapi gdiplus winmm ucrt UxTheme) do echo %%L.lib>> lnk_t.tmp
link @lnk_t.tmp /OUT:%OUTEXE% /nologo /subsystem:windows /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
if ERRORLEVEL 1 goto LERR
echo * %OUTEXE% (GUI, FiveWin) construido *
goto END
:LNKOK
echo * %OUTEXE% construido *
if "%NORUN%" == "1" goto END
echo === Ejecutando la bateria de tests ===
"%OUTEXE%"
echo (codigo de salida %ERRORLEVEL%: 0 = OCX-ALL-OK)
goto END

:GTSTUB
echo ANNOUNCE HB_GTSYS> "%OBJD%\gtstub.prg"
echo REQUEST HB_GT_STD_DEFAULT>> "%OBJD%\gtstub.prg"
call :ONE "%OBJD%\gtstub.prg"
goto :eof

:ONE
set "REL=%~1"
set "OBJ=%REL:\=_%"
set "OBJ=%OBJ:.prg=%"
if /i "%~nx1" == "smoke.prg" goto :eof
if /i "%~nx1" == "tscan.prg" goto :eof
if exist "%OBJD%\%OBJ%.obj" goto :eof
echo [%REL%]
"%HBBIN%\harbour.exe" "%REL%" /n /ku %HBW% /iinclude%FWINC%;%HBINC% /d__64__ /dFWH_CC_MSVC64 /o%OBJD%\ > comp_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
cl -nologo -TC -W3 -O2 -c -I"%HBINC%" -D_WIN64 -D__FLAT__ "%OBJD%\%~n1.c" -Fo"%OBJD%\%OBJ%.obj" > cl_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
del "%OBJD%\%~n1.c" >NUL 2>&1
goto :eof
:ONEC
if exist "%OBJD%\%1.obj" goto :eof
cl -nologo -TC -W3 -O2 -c -I"%HBINC%" -D_WIN64 -D__FLAT__ csrc\%1.c -Fo"%OBJD%\%1.obj" > cl_one.log 2>&1
if ERRORLEVEL 1 type cl_one.log
if ERRORLEVEL 1 set HBERR=1
goto :eof
:CERR_ONE
echo * ERROR compilando %REL% *
type comp_one.log
type cl_one.log
del "%OBJD%\%OBJ%.obj" >NUL 2>&1
set HBERR=1
goto :eof

:CLEAN
del /q obj_t\*.obj obj_t\*.c obj_a\*.obj obj_a\*.c 2>NUL
del /q lnk_t.tmp comp_one.log cl_one.log t_ocx.exe OpenHBCADStudio.exe 2>NUL
echo * Limpio *
goto END
:NOHB
echo * No se encuentra %HBBIN%\harbour.exe - ajusta HBROOT *
goto END
:NOENV
echo * No se pudo inicializar MSVC22 (VSVARS=%VSVARS%) - ajusta VSVARS o usa el x64 Native Tools prompt *
goto END
:CERR
echo * ERRORES DE COMPILACION *
goto END
:LERR
echo * ERROR DE ENLAZADO *
goto END
:END
endlocal

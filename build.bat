@ECHO OFF
REM ======================================================================
REM OpenHBCADStudio - build.bat
REM Equivalente Windows de build.sh: compila y enlaza la SUITE DE TESTS
REM (tests\t_main.prg + src\codec, src\geom2d, src\space, src\tessellation,
REM csrc\ocx_math.c) con Harbour + MSVC 2022 x64 y la ejecuta.
REM Resultado esperado al final:  RESULTADO: N ok, 0 fallos  /  OCX-ALL-OK
REM
REM Uso (desde cualquier carpeta):  build.bat [clean] [norun]
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
REM   OUTEXE   ejecutable resultante (por defecto t_ocx.exe en la raiz)
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
if "%USE_FW%" == "" set "USE_FW=0"
if "%OUTEXE%" == "" set "OUTEXE=t_ocx.exe"
if "%VSVARS%" == "" set "VSVARS=%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
set "HBBIN=%HBROOT%\bin\win\msvc64"
set "HBINC=%HBROOT%\include"
set "HBLIB=%HBROOT%\lib\win\msvc64"
set "OBJD=obj_t"

if /i "%1" == "clean" goto CLEAN
set "NORUN=0"
if /i "%1" == "norun" set "NORUN=1"
if /i "%2" == "norun" set "NORUN=1"

if not exist "%HBBIN%\harbour.exe" goto NOHB
where cl >NUL 2>&1
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
for %%F in (tests\*.prg) do call :ONE "%%F"
call :ONE "src\tessellation.prg"
for %%F in (src\space\*.prg) do call :ONE "%%F"
for %%F in (src\geom2d\*.prg) do call :ONE "%%F"
for %%F in (src\codec\*.prg) do call :ONE "%%F"
if not "%HBERR%" == "0" goto CERR

echo === C: csrc\ocx_math.c ===
cl -nologo -TC -W3 -O2 -c -I"%HBINC%" -D_WIN64 -D__FLAT__ csrc\ocx_math.c -Fo"%OBJD%\ocx_math.obj" > cl_one.log 2>&1
if ERRORLEVEL 1 type cl_one.log
if ERRORLEVEL 1 goto CERR

echo === Enlazando %OUTEXE% ===
if exist lnk_t.tmp del lnk_t.tmp
for %%O in (%OBJD%\*.obj) do echo %%O>> lnk_t.tmp
if "%USE_FW%" == "1" echo "%FWH_DIR%\lib\FiveH64.lib" "%FWH_DIR%\lib\FiveHC64.lib">> lnk_t.tmp
for %%L in (hbvm hbrtl gtwin hblang hbmacro hbrdd rddntx rddcdx rddfpt hbsix hbdebug hbcommon hbpp hbcpage hbct hbpcre hbzlib) do echo "%HBLIB%\%%L.lib">> lnk_t.tmp
for %%L in (kernel32 user32 gdi32 winspool comctl32 comdlg32 advapi32 shell32 ole32 oleaut32 uuid odbc32 odbccp32 iphlpapi mpr version wsock32 ws2_32 msimg32 oledlg psapi gdiplus winmm ucrt UxTheme) do echo %%L.lib>> lnk_t.tmp
link @lnk_t.tmp /OUT:%OUTEXE% /nologo /subsystem:console /NODEFAULTLIB:libucrt /NODEFAULTLIB:msvcrt
if ERRORLEVEL 1 goto LERR
echo * %OUTEXE% construido *
if "%NORUN%" == "1" goto END
echo === Ejecutando la bateria de tests ===
"%OUTEXE%"
echo (codigo de salida %ERRORLEVEL%: 0 = OCX-ALL-OK)
goto END

:ONE
set "REL=%~1"
set "OBJ=%REL:\=_%"
set "OBJ=%OBJ:.prg=%"
if /i "%~nx1" == "smoke.prg" goto :eof
if /i "%~nx1" == "tscan.prg" goto :eof
if exist "%OBJD%\%OBJ%.obj" goto :eof
echo [%REL%]
"%HBBIN%\harbour.exe" "%REL%" /n /ku /w3 /es2 /iinclude%FWINC%;%HBINC% /d__64__ /dFWH_CC_MSVC64 /o%OBJD%\ > comp_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
cl -nologo -TC -W3 -O2 -c -I"%HBINC%" -D_WIN64 -D__FLAT__ "%OBJD%\%~n1.c" -Fo"%OBJD%\%OBJ%.obj" > cl_one.log 2>&1
if ERRORLEVEL 1 goto CERR_ONE
del "%OBJD%\%~n1.c" >NUL 2>&1
goto :eof
:CERR_ONE
echo * ERROR compilando %REL% *
type comp_one.log
type cl_one.log
del "%OBJD%\%OBJ%.obj" >NUL 2>&1
set HBERR=1
goto :eof

:CLEAN
del /q %OBJD%\*.obj %OBJD%\*.c 2>NUL
del /q lnk_t.tmp comp_one.log cl_one.log t_ocx.exe 2>NUL
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

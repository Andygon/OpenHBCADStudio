# Instalar MSVC 2022 y compilar OpenHBCADStudio en Windows

Este documento explica cómo instalar el compilador de Microsoft (MSVC 2022) de forma legal y cómo compilar con él la batería de tests del proyecto usando `build.bat`. El anexo B describe cómo se validó el mismo flujo bajo Wine en Linux.

Nota de licencia: el compilador de Microsoft no se puede redistribuir (ni subir a este repositorio). Cada persona debe descargarlo desde Microsoft y aceptar su licencia.

## 1. Descargar Build Tools for Visual Studio 2022

- Página oficial de descargas: https://visualstudio.microsoft.com/downloads/ (sección "Herramientas para Visual Studio" > "Build Tools para Visual Studio 2022").
- Enlace directo del instalador (redirige al sitio de Microsoft): https://aka.ms/vs/17/release/vs_BuildTools.exe

## 2. Instalar los componentes necesarios

Con el instalador gráfico, marca la carga de trabajo **Desarrollo para el escritorio con C++** (Desktop development with C++) y comprueba que en "Componentes individuales" están marcados:

- **MSVC v143 - VS 2022 C++ x64/x86 build tools** (cl.exe, link.exe)
- **Windows 11 SDK** (o Windows 10 SDK) - cabeceras y librerías de Windows

Alternativa por línea de comandos (administrador):

```bat
vs_BuildTools.exe --passive --wait --norestart ^
  --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
```

Se instala por defecto en `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools`.

## 3. Tener Harbour 64 bits (MSVC) y, opcionalmente, FiveWin

- **Harbour** compilado para MSVC 64 bits, con esta estructura: `bin\win\msvc64\harbour.exe`, `include\`, `lib\win\msvc64\*.lib`. Ejemplo: `C:\PRG\HB\HB_64_MSVC22`.
- **FiveWin 26.03 64 bits** (carpeta `fwh64`, con `include\` y `lib\`). Las pruebas son de consola y no necesitan las librerías de FiveWin, pero sus cabeceras se añaden al include de Harbour.

## 4. Compilar y ejecutar los tests con build.bat

1. Clona o actualiza el repositorio y colócate en `main`.
2. Abre el **x64 Native Tools Command Prompt for VS 2022** (menú Inicio). Así `cl` ya está en el PATH. Si usas un cmd normal, `build.bat` intenta llamar a `vcvarsall.bat` según la variable `VSVARS`.
3. Define las variables si tus rutas no son las de por defecto (o edita los valores al inicio de `build.bat`):

```bat
set HBROOT=C:\PRG\HB\HB_64_MSVC22
set FWH_DIR=C:\PRG\FWH\fwh2605\fwh64
set VSVARS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat
build.bat
```

Variables disponibles: `HBROOT` (también `HARBOUR_DIR`/`HBDIR`), `FWH_DIR` (también `FWDIR`), `VSVARS`, `USE_FW` (0 por defecto; 1 enlaza FiveH64.lib y FiveHC64.lib), `HBGT` (`WIN` por defecto, `STD` para salida por stdout redirigible) y `OUTEXE` (por defecto `t_ocx.exe`). Opciones: `build.bat clean` borra los objetos; `build.bat norun` compila sin ejecutar.

Resultado esperado al final: `RESULTADO: 2068 ok, 0 fallos` y `OCX-ALL-OK`. Si algo falla, los detalles quedan en `comp_one.log` y `cl_one.log`.

## 5. Problemas habituales

- `No se pudo inicializar MSVC22`: ajusta `VSVARS` (BuildTools, Community, Professional o Enterprise) o usa el x64 Native Tools prompt.
- `No se encuentra ...harbour.exe`: ajusta `HBROOT`.
- Error de enlace por una `.lib` de Harbour que falta: comprueba que tu Harbour trae las de la lista del `for %%L in (...)` de `build.bat`.

---

## Anexo A. Verificación de referencia

`build.bat` se ejecutó de principio a fin (Harbour a C, `cl`, `link`, tests) con MSVC 14.44 (VS 2022 17.14) y Windows SDK 10.0.26100, con el resultado 2068 ok, 0 fallos. Esa ejecución fue bajo Wine (anexo B), no en Windows real; la parte GUI y las librerías de FiveWin no se han probado.

## Anexo B. Cómo se montó bajo Wine en Linux (sin root)

Sirve para reproducir la prueba en un Linux sin Windows. Todo se hace en el directorio del usuario.

1. **Wine 64 bits.** Wine 6.0.3 de Ubuntu jammy: descargar los `.deb` (`apt-get download wine64 libwine wine ...` y sus dependencias) y extraerlos con `dpkg -x` en `~/wine`. El script `lib/wine/wineserver` llama a `/usr/lib/wine/wineserver64`: se sustituye copiando `wineserver64` encima. Se exportan `WINEPREFIX`, `WINEDLLPATH` (`~/wine/usr/lib/x86_64-linux-gnu/wine`), `LD_LIBRARY_PATH` y `WINESERVER`. Solo funciona 64 bits (no hay wine32).
2. **MSVC sin instalador.** El instalador de Visual Studio no funciona bien bajo Wine. Se usa el proyecto `msvc-wine` (https://github.com/mstorsjo/msvc-wine): su `vsdownload.py` baja los paquetes del manifiesto oficial de Microsoft y los extrae sin instalar. Los MSI del SDK se extraen con `msiextract` (paquete `msitools`).

```sh
git clone https://github.com/mstorsjo/msvc-wine && cd msvc-wine
python3 vsdownload.py --major 17 --accept-license --dest ~/msvc \
  --architecture x64 --host-arch x64 --only-host yes \
  --with-asan no --with-atl no --with-dia no --with-msbuild no
./install.sh ~/msvc      # genera ~/msvc/bin/x64/{cl,link,lib,rc,...} y msvcenv.sh
```

   Con `--accept-license` se aceptan las condiciones de licencia de Microsoft: léelas antes. Resultado: MSVC 14.44.35207 y Windows SDK 10.0.26100 (unos 3,3 GB). `cl.exe` y `link.exe` de 64 bits arrancan bajo Wine.
3. **Harbour msvc64.** Se compila desde las fuentes (`https://github.com/harbour/core`) con `cl` bajo Wine. `win-make.exe` es de 32 bits y no corre en Wine 64 bits, así que se usa `make` de Linux con un Harbour de Linux como host:

```sh
export PATH=~/msvc/bin/x64:$PATH
export HB_PLATFORM=win HB_COMPILER=msvc64 HB_HOST_BIN=/ruta/harbour/linux/bin
export HB_BUILD_CONTRIBS=no HB_BUILD_DYN=no
export HB_WITH_PNG=local HB_WITH_ZLIB=local HB_WITH_PCRE=local HB_WITH_BZIP2=local
make -j2
```

   Se obtiene `bin/win/msvc64/harbour.exe` y `lib/win/msvc64/*.lib` (misma estructura que `HBROOT`).
4. **Ejecutar build.bat bajo Wine.**

```sh
. ~/msvc/bin/x64/msvcenv.sh        # define PATH/INCLUDE/LIB para cl
cat > wrun.bat <<'BAT'
set HBROOT=Z:\ruta\hbmsvc
set FWH_DIR=Z:\no\existe
set HBGT=STD
call build.bat
BAT
wine cmd /c wrun.bat
```

   Tarda unos 4 minutos. Con `HBGT=STD` la salida de los tests va por stdout y se puede redirigir. Bajo Wine, `gtwin` no escribe en stdout redirigido.
5. **Diferencias con Windows real que se corrigieron en `build.bat`:** Wine 6 no trae `where.exe` (se usa `cl /?`) y el Harbour de la prueba no tenía `hbct.lib` (no hace falta para estos tests).

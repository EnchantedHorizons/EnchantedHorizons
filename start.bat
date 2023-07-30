@echo off
set MC_VER=1.19.2
set FRG_VER=43.2.21
:: To use a specific Java runtime, set an environment variable named JAVA to the full path of java.exe.
:: To disable automatic restarts, set an environment variable named RESTART to false.
:: To install the pack without starting the server, set an environment variable named INSTALL_ONLY to true.
set MIRROR=https://maven.minecraftforge.net/
set INSTALLER="%~dp0forge-%MC_VER%-%FRG_VER%-installer.jar"
set FORGE_URL=%MIRROR%net/minecraftforge/forge/%MC_VER%-%FRG_VER%/forge-%MC_VER%-%FRG_VER%-installer.jar

:JAVA
if not defined JAVA (
    set JAVA=java
)

"%JAVA%" -version 1>nul 2>nul || (
   echo Minecraft %MC_VER% requires Java 17 - Java not found
   pause
   exit /b 1
)

:FORGE
setlocal
cd /D "%~dp0"
if not exist "libraries" (
    echo Forge not installed, installing now.
    if not exist %INSTALLER% (
        echo No Forge installer found, downloading from %FORGE_URL%
        bitsadmin.exe /rawreturn /nowrap /transfer forgeinstaller /download /priority FOREGROUND %FORGE_URL% %INSTALLER%
    )
    
    echo Running Forge installer.
    "%JAVA%" -jar %INSTALLER% -installServer -mirror %MIRROR%
)

if not exist "server.properties" (
    (
        echo allow-flight=true
        echo motd=EnchantedHorizons
        echo max-tick-time=180000
    )> "server.properties"
)

if "%INSTALL_ONLY%" == "true" (
    echo INSTALL_ONLY: complete
    goto:EOF
)

for /f tokens^=2-5^ delims^=.-_^" %%j in ('"%JAVA%" -fullversion 2^>^&1') do set "jver=%%j"
if not %jver% geq 17  (
    echo Minecraft %MC_VER% requires Java 17 - found Java %jver%
    pause
    exit /b 1
) 

:START
"%JAVA%" @user_jvm_args.txt @libraries/net/minecraftforge/forge/%MC_VER%-%FRG_VER%/win_args.txt nogui

if "%RESTART%" == "false" ( 
    goto:EOF 
)

echo Restarting automatically in 10 seconds (press Ctrl + C to cancel)
timeout /t 10 /nobreak > NUL
goto:START

#!/bin/sh
set -eu
FRG_VER=1.19.2
MC_VER=43.2.21
# To use a specific Java runtime, set an environment variable named JAVA to the full path of java.exe.
# To disable automatic restarts, set an environment variable named RESTART to false.
# To install the pack without starting the server, set an environment variable named INSTALL_ONLY to true.
MIRROR="https://maven.minecraftforge.net/"
INSTALLER="forge-$MC_VER-$FRG_VER-installer.jar"
FORGE_URL="${MIRROR}net/minecraftforge/forge/$MC_VER-$FRG_VER/forge-$MC_VER-$FRG_VER-installer.jar"

pause() {
    printf "%s\n" "Press enter to continue..."
    read ans
}

if ! command -v "${JAVA:-java}" >/dev/null 2>&1; then
    echo "Minecraft $MC_VER requires Java 17 - Java not found"
    pause
    exit 1
fi

cd "$(dirname "$0")"
if [ ! -d libraries ]; then
    echo "Forge not installed, installing now."
    if [ ! -f "$INSTALLER" ]; then
        echo "No Forge installer found, downloading now."
        if command -v wget >/dev/null 2>&1; then
            echo "DEBUG: (wget) Downloading $FORGE_URL"
            wget -O "$INSTALLER" "$FORGE_URL"
        else
            if command -v curl >/dev/null 2>&1; then
                echo "DEBUG: (curl) Downloading $FORGE_URL"
                curl -o "$INSTALLER" -L "$FORGE_URL"
            else
                echo "Neither wget or curl were found on your system. Please install one and try again"
                pause
                exit 1
            fi
        fi
    fi

    echo "Running Forge installer."
    "${JAVA:-java}" -jar "$INSTALLER" -installServer -mirror "$MIRROR"
fi

if [ ! -e server.properties ]; then
    printf "allow-flight=true\nmotd=EnchantedHorizons\nmax-tick-time=180000" > server.properties
fi

if [ "${INSTALL_ONLY:-false}" = "true" ]; then
    echo "INSTALL_ONLY: complete"
    exit 0
fi

JAVA_VERSION=$("${JAVA:-java}" -fullversion 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ ! "$JAVA_VERSION" -ge 17 ]; then
    echo "Minecraft $MC_VER requires Java 17 - found Java $JAVA_VERSION"
    pause
    exit 1
fi

while true
do
    "${JAVA:-java}" @user_jvm_args.txt @libraries/net/minecraftforge/forge/$MC_VER-$FRG_VER/unix_args.txt nogui

    if [ "${RESTART:-true}" = "false" ]; then
        exit 0
    fi

    echo "Restarting automatically in 10 seconds (press Ctrl + C to cancel)"
    sleep 10
done

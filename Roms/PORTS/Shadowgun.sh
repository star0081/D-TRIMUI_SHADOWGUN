#!/bin/sh
# TrimUI Smart Pro 1.1.1 POSIX. Stock has no bash.
# Do not change framebuffer.
# Shadowgun is 32-bit Unity 5.3 GLES2. A 64-bit presenter owns the
# PowerVR window; the game talks GLES over a unix socket (NFS MW path).

if [ -f /mnt/SDCARD/System/etc/ex_config ]; then
  . /mnt/SDCARD/System/etc/ex_config
fi

export PATH="/mnt/SDCARD/System/bin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"

GAMEDIR="/mnt/SDCARD/Data/ports/shadowgun"
SYS="$GAMEDIR/armhf"
LD="$SYS/lib/ld-linux-armhf.so.3"
LIB="$GAMEDIR/glbridge:$GAMEDIR/host-libs:$SYS/lib/arm-linux-gnueabihf:$SYS/lib"
LOGDIR="$GAMEDIR/logs"
LOG="$LOGDIR/shadowgun.log"
PM="/mnt/SDCARD/Apps/PortMaster/PortMaster"
PRES=0
PKG="com.madfingergames.shadowgun"
APK="$GAMEDIR/gamedata/SHADOWGUN_1.7.0_PowerVR_RU_MOD_sign.apk"
OBB="$GAMEDIR/Android/obb/$PKG/main.170300014.$PKG.obb"
LIBS="$GAMEDIR/gamefiles/android-libs"

mkdir -p "$LOGDIR" "$GAMEDIR/files" "$GAMEDIR/cache" \
  "$GAMEDIR/Android/data/$PKG" "$GAMEDIR/Android/obb/$PKG" /tmp || exit 1

if [ -f "$LOG" ]; then
  mv -f "$LOG" "$LOG.1" 2>/dev/null || true
fi

echo "===== shadowgun tsp start =====" > "$LOG"
date >> "$LOG" 2>/dev/null
echo "uname=$(uname -a)" >> "$LOG"
echo "id=$(id)" >> "$LOG"

cd "$GAMEDIR" || {
  echo "cannot cd $GAMEDIR" >> "$LOG"
  exit 1
}

if [ ! -f "$OBB" ] && [ -f "$GAMEDIR/gamedata/main.170300014.$PKG.obb" ]; then
  cp -f "$GAMEDIR/gamedata/main.170300014.$PKG.obb" "$OBB" 2>/dev/null || true
fi

if [ ! -f "$APK" ] || [ ! -f "$OBB" ] || [ ! -f "$LIBS/libunity.so" ]; then
  echo "missing Shadowgun 1.7.0 PowerVR data" >> "$LOG"
  echo "need: $APK" >> "$LOG"
  echo "need: $OBB" >> "$LOG"
  echo "need: $LIBS/libunity.so (run setup.sh on a PC)" >> "$LOG"
  echo "===== shadowgun tsp end =====" >> "$LOG"
  sync
  exit 1
fi

rm -f /tmp/nfsmw.present.ready /tmp/tsp-glbridge.sock
chmod a+x "$GAMEDIR/shadowgun_present" "$GAMEDIR/shadowgun_runtime" "$LD" 2>/dev/null || true
chmod a+rw /dev/dri/card0 /dev/dri/renderD128 /dev/fb0 2>/dev/null || true

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null
echo 1800000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null
echo 1800000 >/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null

if [ ! -x "$GAMEDIR/shadowgun_present" ] || [ ! -f "$GAMEDIR/glbridge/libGLESv2.so.2" ]; then
  echo "missing GLES2 glbridge" >> "$LOG"
  echo "===== shadowgun tsp end =====" >> "$LOG"
  sync
  exit 1
fi

if [ ! -f "$LD" ] || [ ! -x "$GAMEDIR/shadowgun_runtime" ]; then
  echo "missing armhf ld.so or shadowgun_runtime" >> "$LOG"
  echo "===== shadowgun tsp end =====" >> "$LOG"
  sync
  exit 1
fi

echo "----- tsp-glbridge server -----" >> "$LOG"
(
  unset LD_PRELOAD
  unset SDL_VIDEODRIVER
  unset LIBGL_ALWAYS_SOFTWARE
  unset GALLIUM_DRIVER
  unset MESA_LOADER_DRIVER_OVERRIDE
  unset LIBGL_DRIVERS_PATH
  unset __EGL_VENDOR_LIBRARY_FILENAMES
  unset SDL_VIDEO_EGL_DRIVER
  export LD_LIBRARY_PATH="/usr/trimui/lib:/usr/lib"
  export SDL_VIDEO_GL_DRIVER=libGLESv2.so
  export SDL_OPENGL_ES_DRIVER=1
  export SDL_GAMECONTROLLERCONFIG_FILE="$PM/gamecontrollerdb.txt"
  export XDG_RUNTIME_DIR=/tmp
  export TMPDIR=/tmp
  export TSPGL_WIDTH="${TSPGL_WIDTH:-640}"
  export TSPGL_HEIGHT="${TSPGL_HEIGHT:-480}"
  if command -v setsid >/dev/null 2>&1; then
    exec setsid "$GAMEDIR/shadowgun_present"
  else
    exec "$GAMEDIR/shadowgun_present"
  fi
) >> "$LOG" 2>&1 &
PRES=$!
n=0
while [ "$n" -lt 15 ]; do
  if [ -f /tmp/nfsmw.present.ready ]; then
    break
  fi
  n=$((n + 1))
  sleep 1
done
echo "present_ready=$n pid=$PRES" >> "$LOG"

export PORT_32BIT=Y
export XDG_RUNTIME_DIR=/tmp
export TMPDIR=/tmp
export SDL_VIDEODRIVER=offscreen
export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-alsa}"
export SDL_VIDEO_GL_DRIVER=libGLESv2.so.2
export SDL_VIDEO_EGL_DRIVER=libEGL.so.1
export SDL_OPENGL_ES_DRIVER=1
export SDL_GAMECONTROLLERCONFIG_FILE="$PM/gamecontrollerdb.txt"
export SDL_NO_SIGNAL_HANDLERS=1
export SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS=1
export MALLOC_ARENA_MAX=2
export NFSMW_WIDTH="${TSPGL_WIDTH:-640}"
export NFSMW_HEIGHT="${TSPGL_HEIGHT:-480}"
export SG_ROOT="$GAMEDIR"
export SG_PACKAGE="$PKG"
export SG_APK="$APK"
export SG_OBB="$OBB"
export SG_FACE_LAYOUT="${SG_FACE_LAYOUT:-nintendo}"
unset LIBGL_ALWAYS_SOFTWARE
unset GALLIUM_DRIVER
unset MESA_LOADER_DRIVER_OVERRIDE
unset LIBGL_DRIVERS_PATH
unset __EGL_VENDOR_LIBRARY_FILENAMES
unset EGL_PLATFORM
unset LD_PRELOAD

echo "ld=$LD" >> "$LOG"
echo "lib=$LIB" >> "$LOG"
echo "----- shadowgun_runtime -----" >> "$LOG"
"$LD" --library-path "$LIB" "$GAMEDIR/shadowgun_runtime" "$LIBS" >> "$LOG" 2>&1
RC=$?

if [ "$PRES" -ne 0 ]; then
  kill "$PRES" 2>/dev/null || true
  wait "$PRES" 2>/dev/null || true
fi
rm -f /tmp/nfsmw.present.ready /tmp/tsp-glbridge.sock
echo "exit_code=$RC" >> "$LOG"
echo "===== shadowgun tsp end =====" >> "$LOG"
sync
exit $RC

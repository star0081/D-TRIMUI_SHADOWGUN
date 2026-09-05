#!/bin/sh
# Run on a PC (has unzip). TrimUI 1.1.1 has no python3.
set -u

GAMEDIR=${1:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
GAMEDATA="$GAMEDIR/gamedata"
LIBDIR="$GAMEDIR/gamefiles/android-libs"
OBBDIR="$GAMEDIR/Android/obb/com.madfingergames.shadowgun"
PKG=com.madfingergames.shadowgun
OBB_NAME=main.170300014.$PKG.obb
APK_SHA=aa8e1863d90de72ea0fd80fdee748e6f37695cfd2703a9295da14a523c3caada
OBB_SHA=a61516f5a0fe2b138ebcfd88ad9b065c53f6426775c4f14e16e6d3de6f9766e3

command -v unzip >/dev/null 2>&1 || {
    echo "setup: unzip is required" >&2
    exit 1
}

APK=
for candidate in "$GAMEDATA"/*.apk; do
    [ -f "$candidate" ] || continue
    hash=$(sha256sum "$candidate" 2>/dev/null | awk '{print $1}')
    if [ "$hash" = "$APK_SHA" ]; then
        APK=$candidate
        break
    fi
done
[ -n "$APK" ] || {
    echo "setup: Shadowgun 1.7.0 PowerVR APK was not found in gamedata/" >&2
    exit 1
}

OBB="$GAMEDATA/$OBB_NAME"
if [ ! -s "$OBB" ]; then
    for candidate in "$GAMEDATA"/*.zip "$GAMEDATA"/*.obb; do
        [ -f "$candidate" ] || continue
        if unzip -l "$candidate" 2>/dev/null | grep -q "$OBB_NAME"; then
            mkdir -p "$GAMEDATA/tmpobb" || exit 1
            unzip -p "$candidate" "*/$OBB_NAME" >"$OBB" 2>/dev/null || \
                unzip -p "$candidate" "$OBB_NAME" >"$OBB" || exit 1
            break
        fi
    done
fi
[ -s "$OBB" ] || {
    echo "setup: $OBB_NAME was not found" >&2
    exit 1
}
obb_hash=$(sha256sum "$OBB" 2>/dev/null | awk '{print $1}')
[ "$obb_hash" = "$OBB_SHA" ] || echo "setup: warning OBB hash differs ($obb_hash)"

TMP="$GAMEDIR/gamefiles/android-libs.new"
rm -rf -- "$TMP"
mkdir -p "$TMP" "$GAMEDIR/files" "$GAMEDIR/cache" \
    "$GAMEDIR/Android/data/$PKG" "$OBBDIR" || exit 1
for library in libmain.so libunity.so libil2cpp.so; do
    unzip -p "$APK" "lib/armeabi-v7a/$library" >"$TMP/$library" || exit 1
    [ -s "$TMP/$library" ] || exit 1
done
rm -rf -- "$LIBDIR"
mv -- "$TMP" "$LIBDIR" || exit 1
cp -f -- "$OBB" "$OBBDIR/$OBB_NAME" || exit 1
unzip -o "$APK" "assets/*" -d "$GAMEDIR" >/dev/null || true
printf '%s\n' "Shadowgun 1.7.0 PowerVR RU 170300014" >"$GAMEDIR/gamefiles/.ready-1.7.0"
echo "setup: ok"
exit 0

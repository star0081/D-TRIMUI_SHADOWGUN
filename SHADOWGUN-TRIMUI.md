# Shadowgun → TrimUI Smart Pro — handoff

Документ для **нового чата**. Открыть воркспейс `D:\SHADOWGUN`. Не начинать порт с нуля: скелет уже собран, бинарники скомпилированы, на SD уже заливался.

Пользователь: **Star**. Порты на TSP 1.1.1 делались в том же стиле:

- https://github.com/star0081/D-TRIMUI_NFSMW_PORTMASTER
- https://github.com/star0081/D-TRIMUI_DEAD_SPACE_PORTMASTER

Целевой девайс: **TrimUI Smart Pro, сток 1.1.1** (TinaLinux, Allwinner A133P, PowerVR GE8300, 1280×720). Запуск через PortMaster / TRIMUI_EX. GUI PortMaster на 1.1.1 **не обновлять**. Framebuffer стока (`1280×13107` virtual) **не менять**. POSIX `/bin/sh`, не bash. Лаунчеры только **LF**. FAT32 — без симлинков. На консоли нет python3.

## Статус

**WIP. На карте будет SG-BUILD 31.**

Билд 30: патчи IsObbFileAccessible/GetDataFileStatus встали, `PERMISSIONS CHECK` больше нет. Всё равно InvalidDataError: MenuLoader делает `dataBinded = Application.dataPath.EndsWith(".obb")`. Unity не примонтировал OBB, dataPath = APK → False. В 31: NOP этой ветки, InvalidDataError → DataDownloaded/LoadScene. Ищи `SG-BUILD 31`, `SG-PATCH Start`, нет экрана broken.

Билд 29: prefs encode/getValue уже ок (`LastRequestState='1'`), но `{0}` всё равно False — `GetWorstState` не читает prefs, поле Pending. Проверку OBB/permissions отключаем патчем `libil2cpp`: `IsObbFileAccessible`→true, `GetWorstState`→1, `GetDataFileStatus`→Bind(2).

Билд 28: снова «broken». `test.tmp` уже size=3, IsFileReadable/IsDirectoryWritable True, но `{0}` False. Unity апгрейдит PlayerPrefs: `getValue` отдавал Integer (GetStringUTFChars=''), `Uri.encode/decode` возвращали пустую строку → C# `LastRequestState` остаётся Pending. В 29: getValue="1", encode/decode pass-through.

Билд 27: снова «broken». forName и prefs next ок. `FSTAT …/Android/obb/…/test.tmp size=0`. IsDirectoryWritable True (файл создали), но он пустой — C# File.Create без записи. В 28: `test.tmp` сидируется `"RRR"`.

Билд 26: снова «broken». WWW stub ок, сеть не нужна. `PERMISSIONS CHECK: False` без GetBooleanField/getInt ключей — C# `LastRequestState` по умолчанию Pending: `Class.forName` всегда отдавал `Object`, `SharedPreferences.getAll` был пустой (`hasNext=0`). В 27: forName с реальным именем класса, prefs iterator с OBB_PERMISSIONS=1. Ищи `SG-BUILD 27`, `forName '`, `prefs next`, `PERMISSIONS CHECK: True`.

Билд 25: снова «broken». WWW URL для https уже парсится (`stats.unity3d.com`, `uca.cloud`) — серверы мертвые, в сеть не ходим. `PERMISSIONS CHECK: False` без `file://`: GetBooleanField всегда 0, getInt prefs всегда 0 (LastRequestState=Pending). В 26: boolean field → 1, prefs getInt Granted, WWW http = локальный stub `{}` без сокетов. Ищи `SG-BUILD 26`, `WWW local stub`, `PERMISSIONS CHECK: True`.

Билд 24: снова «Data file is broken». Краша нет, `SDK_INT=8`. `WWW ctor handle=… url=''` — Unity зовёт `NewObjectV` (packed ARM: handle+url), мы читали 8-байтный `jvalue`, URL пустой, `file://test.tmp` не читался. В 25: разбор packed va_list, сканируем args на String. Ищи `SG-BUILD 25`, `WWW ctor` с `file://` или `/mnt/…/test.tmp`, `PERMISSIONS CHECK: True`.

Билд 23: чёрный экран, SIGSEGV 139 на старте. `runOnUiThread runnable=0x29800000` — `CallVoidMethodV` не прокидывал jvalue, `as_object` читал дыру. В 24: реестр fake-object (без deref мусора), `runOnUiThreadV` берёт `jvalue[0]`. WWW/Froyo из 23 на месте. Ищи `SG-BUILD 24`, нет краша на `runOnUiThread`.

Билд 22: та же «Data file is broken». `SDK_INT=22` **не** переключил `ANDROID PERMISSIONS CHECK` в True. OBB читается (`fstat 266458983`), `IsFileReadable`/`IsDirectoryWritable` True. False — это Unity `WWW file://…/test.tmp`: `nativeInitWWW` получил dummy `java/lang/Object`, `CallVoid start` не вызывал `doneCallback`. В 23: `SDK_INT=8` (Froyo 2.2, как оригинал 2011), `WWW` ctor/start читает `file://` и зовёт `headerCallback`/`readCallback`/`doneCallback`. Ищи `SG-BUILD 23`, `SG-JNI SDK_INT -> 8`, `SG-JNI WWW ctor`, `PERMISSIONS CHECK: True`.

Билд 21: та же «Data file is broken». `PERMISSIONS CHECK: False` **до** `checkPermissions` — C# `IsObbFileAccessible` при `SDK_INT=27` требует runtime permission (Marshmallow+). `Manifest.permission.*` и `*_SERVICE` были пустыми строками. В 22: `SDK_INT=22` (без runtime perms), permission/service константы, `PERMISSION_DENIED=-1`. Ищи `SG-BUILD 22`, `GetIntField SDK_INT` не 27, `PERMISSIONS CHECK: True`.

Билд 20: OBB нашёлся (`getPath` = `$SG_ROOT`, `fstat size=266458983`, `versionCode` ok). Экран «Data file is broken or in invalid version». Это `InvalidDataError` у MenuLoader: `IsObbFileAccessible` пишет `ANDROID PERMISSIONS CHECK: False` — `checkPermissions` вернул пустой `[I]`. Плюс UNKNOWN на `CallNonvirtualVoidMethod` (`init`) и `GetByteArrayRegion` (SALT). В 21: checkPermissions → 4× GRANTED, CallNonvirtual*, SALT/BASE64 поля. Ищи `SG-BUILD 21`, `checkPermissions granted`, `PERMISSIONS CHECK: True`.

Билд 19: после сплэша Unity UI «Network is not reachable! Application is not able to download data!». Это **MenuLoader / GooglePlayDownloader**, не краш. OBB на карте есть (`Android/obb/…/main.170300014.…obb`), но игра его не видит: `getExternalStorageDirectory` = `$SG_ROOT/Android` (получается `…/Android/Android/obb/…`), `PackageInfo.versionCode` = **0** (файл `main.0.…obb`). C# `File.Exists` мимо → FetchOBB → нет сети. В 20: sdcard = `$SG_ROOT`, versionCode **170300014**, NetworkInfo connected, rewrite `Android/Android/obb` и любой `.obb` → `$SG_OBB`. Ищи `SG-BUILD 20`, `GetMainOBBPath`, `GetIntField versionCode`, `G8-PATH`.

Билд 18: сплэш Anniversary прошёл (`swap 1`, `stopActivityIndicator`), потом crash 139 после `ReflectionHelper.getMethodID`. Слоты JNI 7/8/9 (`FromReflectedMethod` / `FromReflectedField` / `ToReflectedMethod`) были `unknown` → NULL jmethodID → SIGSEGV `address=0x8`. В 19: parse args `getMethodID`/`getFieldID`/`getConstructorID`, stash interned id на fake Method, `FromReflectedMethod` его возвращает. Плюс `GetIntArrayElements` для `getDeviceIds`. Ищи `SG-BUILD 19`, `SG-JNI reflect`, `FromReflectedMethod`, нет `UNKNOWN` сразу после `getMethodID`.

Билд 17: сплэш Anniversary Edition нарисовался (`swap 1`), потом зависание, kill 137. `libunity` импортирует `ALooper_pollAll`; заглушка возвращала **0** (= ident fd 0 / stdin) — Unity читает stdin и блокируется. В 18: `pollAll` → `ALOOPER_POLL_TIMEOUT` (−3). Ищи `SG-BUILD 18`, `SG-ALOOPER`, `SG-WATCH`, `SG-JNI frames`.

Билд 16: nativeRender крутится, `exit_code=137` (убили). Экран — зелёная полоса + куски атласа. Две причины: (1) Unity берёт GLES через `dlsym` и получает hardfp `glClearColor`/`glUniform*f`; (2) презентер с `fb_fetch=1` переписывает **все** шейдеры в `#version 300 es` + `layout(location=0)` — vertex splash не компилируется (`COMPILE FAIL id=76`). В 17: softfp-thunks из `dlsym`/`eglGetProcAddress`; ES3-rewrite только для fragment + framebuffer fetch. Нужны runtime **и** `shadowgun_present`. Ищи `SG-BUILD 17`, `G8-DLSYM SOFTFP glClearColor`, нет `COMPILE FAIL`.

Билд 15: `glGetString` нашли (`G8-DLSYM glGetString -> ненулевой`). Unity прочитал extensions и GetIntegerv, потом снова `pc=0` / `lr` libunity `+0x4c7b00` (`blx r12`). В таблице GfxDevice NULL на extension-алиасах: `glDebugMessage*KHR`, `glTexImage3DOES`, `glMapBufferRangeEXT` (`tspgl: missing …`). В 16: эти entry points + stub `eglGetProcAddress`. Ищи `SG-BUILD 16` и отсутствие `tspgl: missing` без `(stub)`.

Билд 14: metadata `fstat` ok (`size=2949084`). Unity дошёл до GLES и упал `pc=0` / `lr` в libunity `+0x4c9698`: `glGetString(GL_EXTENSIONS)` через NULL в таблице GfxDevice. `libunity` не импортирует `glGetString` по PLT — только `dlopen`/`dlsym`/`eglGetProcAddress`. ~100× `dlopen("libGLESv2.so")` (RTLD_LOCAL) + `dlsym(RTLD_DEFAULT)` не видит символы glbridge. В 15: `dlopen` GLES/EGL с `RTLD_GLOBAL`, `dlsym(gl*)` через закэшированный handle + `eglGetProcAddress`. Ищи `SG-BUILD 15` и `G8-DLSYM glGetString`.

Билд 13: `global-metadata.dat` открылся (`files/il2cpp/Metadata/... ok`). Падение в `strcmp` при разборе metadata: `GetStringFromIndex` дал мусорный указатель. `libil2cpp` импортирует `fstat`, заглушка писала glibc `stat`, а Unity ждёт bionic 104 байта — `st_size` кривой. В 14: `fstat`/`fstat64` через `SYS_fstat64`. Ищи `SG-BUILD 14` и `G8-FSTAT`.

Билд 12: `getPath`/`getParent`/`GetStringUTFChars` прошли. Падение в `Assembly::GetImage(NULL)` — `Assembly::Load` не нашёл сборку. В `assets/` не было `global-metadata.dat`, `AAssetManager` не был реализован. В 13: чтение APK assets + metadata на карте. Ищи `SG-BUILD 13` и `SG-ASSET`.

Билд 11: после `GetMethodID java/io/File getPath` / `getParent` тот же NULL. Сами `CallObject getPath/getParent` в 11 не печатались. В 12 лог на каждый CallObject и GetStringUTFChars. Ищи `SG-BUILD 12`.

Билд 10: после `FindClass java/io/File` тот же NULL в il2cpp (`pc` в thunk `ldr r0,[r0]`), без `CallObject` и без `UNKNOWN`. Следующий JNI, скорее всего, молчал (`GetMethodID` / `NewObject` / `GetSuperclass`). В 11: `GetSuperclass`, UTF-16 String, `Class.getName` с точками, лог `GetMethodID`. В логе ищи `SG-BUILD 11`.

| SG-BUILD | Лог TSP | Что сломалось |
|---|---|---|
| 1 | SIGSEGV 139, нет `enter` | ET_EXEC vs PIE |
| 2 | `FAIL map: stat … EINVAL` | `__fxstat(_STAT_VER=0)` |
| 3 | SIGSEGV `putInt`, addr `0x4444c` | Editor как CallObject |
| 4 | `System.load` + `dlopen("")` exit 1 | `findLibrary` → ClassLoader |
| 5 | `CallBoolean loadLibrary -> 0` exit 1 | boolean false |
| 6 | `G8-DLOPEN il2cpp` exit 1 | короткое имя, не `libil2cpp` |
| 7 | G-CRASH NULL после `MEDIA_MOUNTED` | static String field = NULL |
| 8 | G-CRASH addr `0x1` на `FindClass Object` | NewObject va_arg мусор |
| 9 | G-CRASH NULL на `getParent` | File.getParent → File, не String |
| 10 | G-CRASH NULL сразу после `FindClass File` | getParent уже String; следующий JNI молчал |
| 11 | G-CRASH NULL после `GetMethodID File.getParent` | getPath/getParent молчали |
| 12 | G-CRASH после 3× getPath/GetStringUTFChars | `Assembly::Load` → NULL, нет metadata |
| 13 | G-CRASH в strcmp после fopen metadata | glibc `fstat` vs bionic `stat` |
| 14 | `pc=0` после ~100× `dlopen libGLESv2.so` | `glGetString` слот GfxDevice = NULL |
| 15 | `pc=0` после GLES init / Build.INCREMENTAL | NULL слоты `*KHR`/`*OES`/`*EXT` |
| 16 | зелёный экран, `COMPILE FAIL` шейдера, kill 137 | hardfp GLES + ES3 rewrite всех шейдеров |
| 17 | сплэш ок, дальше тишина, kill 137 | `ALooper_pollAll` вернул 0 = stdin |
| 18 | сплэш ок, crash 139 после getMethodID | FromReflectedMethod слот = unknown |
| 19 | сплэш ок, UI «Network is not reachable» | OBB path + versionCode=0 |
| 20 | OBB найден, UI «Data file is broken» | checkPermissions пустой `[I]` |
| 21 | та же «broken», PERMISSIONS False до JNI | SDK_INT=27 → runtime perms |
| 22 | та же «broken», PERMISSIONS False при SDK 22 | WWW file:// test.tmp не complete |
| 23 | чёрный экран, SIGSEGV 139 на runOnUiThread | as_object deref 0x29800000 |
| 24 | снова «broken», WWW url='' | NewObjectV packed vs jvalue |
| 25 | снова «broken», PERMISSIONS False, WWW только https | GetBooleanField=0, getInt prefs=0 |
| 26 | снова «broken», PERMISSIONS False, prefs пустые | forName=Object, hasNext=0 |
| 27 | снова «broken», test.tmp size=0 | File.Create пустой файл |
| 28 | снова «broken», test.tmp size=3, {0} False | PlayerPrefs getValue/encode пустые |
| 29 | снова «broken», prefs='1', {0} всё равно False | GetWorstState не из prefs |
| 30 | снова «broken», патч permissions ок | dataPath.EndsWith(.obb) = false |
| 31 | ещё не гоняли | NOP bind-check, InvalidDataError→LoadScene |

## Донор (только эта сборка)

Путь: `D:\SHADOWGUN\ORIG GAME\`

| Файл | Размер | SHA-256 |
|---|---|---|
| `SHADOWGUN_1.7.0_PowerVR_RU_MOD_sign.apk` | 15 629 353 | `aa8e1863d90de72ea0fd80fdee748e6f37695cfd2703a9295da14a523c3caada` |
| внутренний OBB `main.170300014.com.madfingergames.shadowgun.obb` (лежит внутри `SHADOWGUN_1.7.0_PowerVR_RU_OBB.zip`) | 266 458 983 | `a61516f5a0fe2b138ebcfd88ad9b065c53f6426775c4f14e16e6d3de6f9766e3` |

- Пакет: `com.madfingergames.shadowgun`
- versionName **1.7.0**, versionCode **170300014**
- Activity: `com.madfingergames.unityplayer.MFUnityPlayerActivity`
- `settings.xml`: `useObb=True`
- GLES: **2.0** (`glEsVersion 0x00020000`)
- Текстуры: **`GL_IMG_texture_compression_pvrtc`** (PowerVR) — родной формат GE8300
- ABI: только **armeabi-v7a** (32-bit). arm64 нет
- Движок: **Unity 5.3.8f1 IL2CPP** (`libunity.so` + `libil2cpp.so` + `global-metadata.dat`). Это не оригинальный Unity 3.x/Mono 2011 года, а PowerVR RU MOD
- `.so`: `libmain.so`, `libunity.so`, `libil2cpp.so`. Есть ещё `libHellCPU.so` (мод-патчер `PatchData` / `mprotect`) — **не грузить**, пока лицензию закрываем JNI-заглушкой
- В метаданных уже есть геймпад: OUYA, GameStick, Xbox 360, DualShock, Xperia Play, `Texts_gpad` / `Texts_touch`, `DummyLicenseChecker`
- Интро: `assets/introHD.mp4` ~73 МиБ в OBB — на стоке лучше скип, не декодировать
- Кампания в OBB: `level1`–`level19`, GI, sharedassets. В APK только boot `level0` + splash + metadata

В git игру / APK / OBB / `.so` **не класть** (см. `.gitignore`).

## Архитектура (как NFS MW, не как Dead Space)

Сток 1.1.1 — 64-битный Linux. 32-bit EGL/GLES на PowerVR нет. Рабочий путь тех же двух портов:

1. 32-битный процесс через свой `armhf` (`ld-linux-armhf.so.3 --library-path …`)
2. **glbridge**: 32-bit `libEGL.so` / `libGLESv2.so` → unix socket + mmap → 64-bit `*_present` с окном SDL GLES 3.0 на PowerVR
3. Аудио: 32-bit SDL2 + ALSA из `host-libs/`
4. FBO по умолчанию **640×480**, stretch на 1280×720

| | NFS MW | Dead Space | **Shadowgun** |
|---|---|---|---|
| GLES | 2.0 | 1.1 fixed | **2.0** → брать glbridge **NFS**, не DS |
| Текстуры | свои | ATC | **PVRTC** (прокинуть compressed tex; в клиенте уже добавлены GL_IMG строки) |
| Движок | Nimble | IronMonkey | **Unity 5.3 IL2CPP** (лоадер новый) |
| Аудио | FMOD | SDL | OpenSLES / AudioTrack → мост NFS OpenSL |

Презентер пока **тот же бинарник NFS** (`nfsmw_present` скопирован как `shadowgun_present`). Сокет **`/tmp/tsp-glbridge.sock`**, ready-файл **`/tmp/nfsmw.present.ready`**. NFS и Shadowgun одновременно не запускать. Позже переименовать сокет в `/tmp/sg-glbridge.sock`, когда пересоберёте `server.c`.

`glCompressedTexImage2D` в NFS-glbridge уже есть. Клиент пересобран с:

- `GL_IMG_texture_compression_pvrtc`
- `GL_IMG_texture_compression_pvrtc2`

иначе Unity уйдёт в CPU-декомпресс / чёрные текстуры.

## Дерево проекта

```
D:\SHADOWGUN\
  ORIG GAME\                          донор, gitignore
  README.md                           коротко для GitHub
  SHADOWGUN-TRIMUI.md                 этот handoff
  LICENSE                             MIT (код совместимости)
  Roms/PORTS/Shadowgun.sh             лаунчер PortMaster (LF)
  Imgs/PORTS/Shadowgun.png            splash из APK
  Data/ports/shadowgun/
    shadowgun_runtime                 armhf ELF, Zig 0.13 (~112 КиБ)
    shadowgun_present                 aarch64, копия NFS present (~54 КиБ)
    glbridge/                         32-bit клиент (все имена — копии одного .so)
    armhf/                            sysroot из NFS
    host-libs/                        SDL2+ALSA из Dead Space (без LLVM)
    gamefiles/android-libs/           libmain / libunity / libil2cpp
    gamedata/                         APK (+ README). OBB на SD только в Android/obb
    Android/obb/com.madfingergames.shadowgun/main.170300014….obb
    assets/                           распакованный APK assets (fallback)
    src/                              исходники
    setup.sh                          извлечение libs/OBB на ПК
    src/build.ps1                     сборка
```

На SD (когда карта в ПК — диск **G:**) заливалось:

| На карте | Файл |
|---|---|
| `Roms/PORTS/Shadowgun.sh` | LF |
| `Imgs/PORTS/Shadowgun.png` | обложка |
| `Data/ports/shadowgun/` | runtime, present, glbridge, armhf, host-libs, APK, OBB, `.so` |

На карту **не** копировали: `src/`, `ORIG GAME`, дубль OBB в `gamedata/`, `libHellCPU.so`.

Лог на девайсе: `Data/ports/shadowgun/logs/shadowgun.log`.

## Исходники лоадера (что своё)

Скопировано из NFS MW runtime (префиксы `nfsmw_*` оставлены специально, меньше дифф):

`elf32_loader`, `compat_bridge`, `crash_trace`, `initializer_trace`, `softfp_*`, `symbol_probe`, `relocation_probe`, `opensl_bridge`, `platform_probe`, `bionic_setjmp.S`, `screen_size.h` (`NFSMW_WIDTH`/`NFSMW_HEIGHT`, лаунчер ставит 640×480).

Новое:

| Файл | Роль |
|---|---|
| `src/runtime/main.c` | map `libmain` → `libunity` → `libil2cpp`, reloc, ctor, JNI |
| `src/runtime/jni_unity.c` | фейковый JNIEnv/JavaVM, `RegisterNatives` (слот 215), lifecycle Unity 5.3 |
| `src/runtime/android_native.c` | `ANativeWindow_*`, заглушки ALooper/ASensor/AMotion |

Порядок Unity 5.3, который зовёт лоадер:

`JNI_OnLoad` (main, unity, il2cpp) → `initJni(activity)` → `nativeFile(apk)` → `nativeInitWWW` / `nativeInitWebRequest` → `nativeRecreateGfxState(0, surface)` → `nativeResume` → `nativeFocusChanged(true)` → цикл `nativeRender`.

`ANativeWindow_fromSurface` возвращает окно 640×480.  
`GetMainOBBPath` / `SG_OBB` → `Android/obb/com.madfingergames.shadowgun/main.170300014.com.madfingergames.shadowgun.obb`.  
Лицензия: `CheckIfLicensed` / `getLicensed` → true.  
`libandroid.so` перехватывается в `compat_dlopen`.

Сборка (Zig 0.13 уже стоит):

```
D:\PortMaster\tsp-eaprules\zig-windows-x86_64-0.13.0\zig.exe
powershell -File D:\SHADOWGUN\Data\ports\shadowgun\src\build.ps1
```

Цель: `arm-linux-gnueabihf -mcpu=cortex_a7 -D_GNU_SOURCE`. Клиент: `client.c` + `client_xport.c` → копируется в `libEGL.so`, `libEGL.so.1`, `libGLESv2.so`, `libGLESv2.so.2`.

Презентер 64-bit пока не пересобирали (нужен `-target aarch64-linux-gnu.2.17`, `src/glbridge/server.c`). Имеет смысл, когда будете менять сокет/ready-файл.

## Лаунчер

`Roms/PORTS/Shadowgun.sh` — копия схемы Dead Space / NFS:

- governor `performance`, 1.8 GHz
- старт `shadowgun_present` с `LD_LIBRARY_PATH=/usr/trimui/lib:/usr/lib`
- ждёт `/tmp/nfsmw.present.ready` до 15 с
- 32-bit: `ld-linux-armhf.so.3 --library-path glbridge:host-libs:armhf … shadowgun_runtime gamefiles/android-libs`
- `SDL_VIDEODRIVER=offscreen` у 32-bit процесса
- env: `SG_ROOT`, `SG_PACKAGE`, `SG_APK`, `SG_OBB`, `NFSMW_WIDTH=640`, `NFSMW_HEIGHT=480`

Проверка перед стартом: APK, OBB, `libunity.so`, `shadowgun_runtime`, `glbridge/libGLESv2.so.2`.

## Что делать в следующем чате

1. **Первый лог с TSP.** Без `shadowgun.log` не гадать. Типичные обрывы: unresolved reloc (`libandroid` / `AMotion*`), `JNI_OnLoad` без `RegisterNatives`, `nativeFile` не видит APK, OBB path, `eglCreateWindowSurface`, отсутствие `nativeRender`.
2. **Добить JNI** по логу `SG-JNI FindClass` / `CallObject` / `UNKNOWN table call`. Unity 5.3 дергает `ApplicationInfo`, `Environment`, `DisplayMetrics`, `SharedPreferences`, `Build.SDK_INT=27`, `CPU_ABI=armeabi-v7a`.
3. **Ввод.** Сейчас только `nfsmw_platform_runtime_input` и грубый Select+Start (`buttons[8]+[9]`). Нужен `nativeInjectEvent` (KeyEvent/MotionEvent) и/или оси Unity joystick. Раскладка лиц как в Dead Space: `nintendo` (A справа). В игре уже есть `GamepadKeys` / `Xperia_Layout` / `Texts_gpad`.
4. **Аудио.** OpenSL-мост NFS в линковке. `platform_runtime_start` пытается создать SDL GL-окно — на offscreen может упасть, тогда звука не будет. Возможно, SDL_Init только audio+joystick, без VIDEO/GL.
5. **Переименовать glbridge** (`/tmp/sg-glbridge.sock`, `shadowgun.present.ready`) и пересобрать `server.c`, чтобы не пересекаться с NFS.
6. **Интро/видео** — заглушка `VideoPlayer` / skip `introHD.mp4`.
7. **GitHub** по образцу NFS/DS: без APK/OBB/`.so` игры, README + LICENSE MIT. Репо ещё не создавали.

## Жёсткие правила с прошлых портов

- Не трогать framebuffer стока.
- Не обновлять GUI PortMaster на 1.1.1.
- Не bash, только POSIX `sh`, LF.
- Не симлинки на FAT32 — дублировать `.so` файлами.
- Игру в git не коммитить.
- Коммиты только по просьбе Star, автор `star0081`, без Co-authored-by Cursor.
- Проверка UI в браузере тут не применима; проверка = лог с TSP + запуск с карты.

## Полезные абсолютные пути на ПК

- Воркспейс порта: `D:\SHADOWGUN`
- Донор: `D:\SHADOWGUN\ORIG GAME`
- Исходники NFS (glbridge/runtime): `D:\PortMaster\D-TRIMUI_NFSMW_PORTMASTER\Data\ports\nfsmw\src`
- Готовый NFS на диске: `D:\NFS\SD`
- Готовый Dead Space: `D:\DEADSPACE\SD`
- Zig 0.13: `D:\PortMaster\tsp-eaprules\zig-windows-x86_64-0.13.0\zig.exe`
- Карта TrimUI, когда вставлена в ПК: **G:** (`Roms`, `Data`, `Apps`, `Imgs`, `System`)

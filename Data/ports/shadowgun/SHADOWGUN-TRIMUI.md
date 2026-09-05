# Shadowgun → TrimUI Smart Pro — статус порта (BUILD 76)

Документ фиксирует состояние на **SG-BUILD 76** (сентябрь 2026). Рабочий снимок бинарников: `D:\SHADOWGUN\BUILD 76\` (на карте: `Data/ports/shadowgun` + `Roms/PORTS/Shadowgun.sh`).

Автор / контрибутор: **star0081**.  
Целевое устройство: **TrimUI Smart Pro, сток 1.1.1** (TinaLinux, Allwinner A133P, PowerVR GE8300, 1280×720).  
Репозиторий: https://github.com/star0081/D-TRIMUI_SHADOWGUN  

Связанные порты того же стиля:

- https://github.com/star0081/D-TRIMUI_NFSMW_PORTMASTER
- https://github.com/star0081/D-TRIMUI_DEAD_SPACE_PORTMASTER

---

## Краткий вердикт

**Игра запускается и проходится по управлению достаточно для геймплея.** BUILD 76 — текущий финальный снимок этой ветки отладки.

Работает:

- запуск Unity 5.3.8f1 IL2CPP через armhf + glbridge GLES2 / PVRTC
- аудио (FMOD через SDL)
- меню: D-pad + A (подтверждение)
- движение — левый стик (без заметного дрейфа)
- обзор / прицел — правый стик
- стрельба — R2
- прыжок / рывок — L1
- чувствительность камеры сохраняется между уровнями (`prefs.txt`)
- переназначение осей/кнопок без пересборки (`controls.txt`)

Не доведено:

1. **Точное прицеливание** (отдельная кнопка/биндинг)
2. **Соотношение сторон** — картинка чуть выползает за края экрана
3. **Видео в катсценах** (`introHD.mp4` и in-game video)

---

## Донор (в git не кладётся) ru🚚er or 4pda

| Файл | SHA-256 |
|---|---|
| `SHADOWGUN_1.7.0_PowerVR_RU_MOD_sign.apk` | `aa8e1863d90de72ea0fd80fdee748e6f37695cfd2703a9295da14a523c3caada` |
| OBB `main.170300014.com.madfingergames.shadowgun.obb` | `a61516f5a0fe2b138ebcfd88ad9b065c53f6426775c4f14e16e6d3de6f9766e3` |

- Пакет: `com.madfingergames.shadowgun`, versionCode **170300014**
- Unity **5.3.8f1 IL2CPP**, GLES **2.0**, текстуры **PVRTC**, ABI только **armeabi-v7a**
- `.so` игры: `libmain.so`, `libunity.so`, `libil2cpp.so` (`libHellCPU.so` не грузим)

---

## Архитектура

1. 32-bit процесс через свой `armhf` (`ld-linux-armhf.so.3`)
2. **glbridge**: 32-bit `libEGL`/`libGLESv2` → unix socket + mmap → 64-bit `shadowgun_present` (SDL GLES 3.0 на PowerVR)
3. Аудио: SDL2 + ALSA из `host-libs/`
4. FBO по умолчанию **640×480**, stretch на 1280×720
5. JNI-эмуляция в `jni_unity.c` (фейковый `JNIEnv` / `JavaVM`, `nativeInjectEvent`)

Сокет пока общий с NFS: `/tmp/tsp-glbridge.sock`, ready `/tmp/nfsmw.present.ready` — NFS и Shadowgun одновременно не запускать.

---

## Что сделано (хронология по сути)

### Запуск и стабильность

- ELF32-лоадер + Bionic-compat
- Unity lifecycle: `JNI_OnLoad` → `initJni` → `nativeFile` → gfx → `nativeRender`
- OBB path, лицензия-заглушка, отказ от `libHellCPU.so`
- FMOD / аудио без GL-окна у 32-bit процесса
- Снятие зависания на Xperia Play `navigationHidden` (перестали спуфить `R800i`)

### Ввод (главная линия отладки)

Долгая цепочка, пока оси реально дошли до Unity и встали на правильные слоты профиля:

| Проблема | Фикс |
|---|---|
| softfp/hardfp: `getAxisValue` всегда 0 | `SG_JNI_SOFTFP` — float return в `r0` |
| `MotionEvent.obtain` отдавал не-MotionEvent | копия остаётся `android/view/MotionEvent` |
| source `JOYSTICK\|GAMEPAD` → Unity recycle | только `SOURCE_JOYSTICK` |
| `SDK_INT=8` режет joystick API | `SDK_INT=16`, target SDK отдельно = 8 |
| «новый геймпад» / пустой конфиг | имя `Microsoft X-Box 360 pad`, очистка `Gamepad*` prefs |
| `OptionsSensitivity=0` | дефолт + позже персистентный `prefs.txt` |
| обзор «мертвый» при живых осях | проба BUILD 70: Unity читал Z, но вид не на ней |
| BUILD 71: 8 осей (RX/RY) | обзор заработал (слоты 3/4 и/или 7/8) |
| триггеры / раскладка | нормализация 0…32767 → 0…1; карта в `controls.txt` |

Подтверждённый порядок опроса Unity (слоты 1…8):  
**X, Y, RX, RY, LTRIGGER, RTRIGGER, Z, RZ**.

Известные бинды профиля (по логам + тестам):

- Axis 1/2 — движение  
- Axis 3/4 — обзор (дублируется и на 7/8 в дефолтной карте)  
- Axis 6+ — стрельба (R2)  
- Axis 5+ — кандидат на перезарядку (в BUILD 76 питается от R1 как `btn10`)  
- Axis 5− и кнопка L2 — **не** прицел (проверено)  
- Button11 (R3) — кандидат на прицел; на TrimUI физической кнопки нет → в 76 L2 шлёт `thumbr`

### Настройки

- `prefs.txt` — реальное SharedPreferences-хранилище (чувствительность больше не слетает)
- Служебные ключи (`PLUGIN*`, permissions, OBB…) **не** сохраняются — иначе Google Play Games INIT=0 вешал загрузку (BUILD 73)
- `controls.txt` — карта slot/button без пересборки

### Раскладка по умолчанию (BUILD 76 / `controls.txt`)

| Действие | Управление |
|---|---|
| Ходьба | левый стик |
| Обзор | правый стик |
| Стрельба | R2 |
| Прыжок / рывок | L1 |
| Перезарядка | R1 → Axis 5+ (`slot5 = btn10`) |
| Прицел (кандидат) | L2 → keycode R3 (`l2key = thumbr`) |
| Меню | D-pad + A |

---

## Трудности в процессе

1. **Диагностика врала сама себе.** Общий лимит логов на `getAxisValue LIVE` съедался левым стиком/триггерами — казалось, что правый стик «не отдаёт» значения. Фикс: бюджет **на каждый слот**.
2. **Угадывание биндов без подписей.** Экран настроек пустой (локализация/тексты UI не подгружаются) — только `Axis N ±` / `ButtonN`. Пришлось выводить карту экспериментами + метаданными.
3. **Дублирование стика на слоты 3–4 и 7–8.** BUILD 71 случайно «попал» в обзор; последующие попытки «развести» оси ломали стрельбу/перезарядку (BUILD 73–74).
4. **Prefs слишком жадные.** Сохранение INIT=0 для отсутствующего Google Play плагина → бесконечная загрузка.
5. **ABI softfp Unity vs hardfp runtime** — классика для этого стека, проявилась именно на float-осях.
6. **Нет тача на TrimUI** — нельзя опереться на touchpad-aim как на Xperia Play.

---

## Что осталось

### 1. Точное прицеливание

Кандидат BUILD 76 (`L2 → Button11/R3`) нужно подтвердить на устройстве. Если не сработает — прицел, скорее всего, не заведён во встроенном Xbox-профиле и требует:

- либо ручного бинда в UI (сначала починить **пустые подписи** / загрузку строк),
- либо явной записи профиля в `prefs.txt` / `Gamepad*` (осторожно: игра валидирует длину строк).

### 2. Соотношение сторон / край экрана

Игра чуть вылезает за края. Скорее всего letterbox / viewport / `ANativeWindow` size / presenter stretch (сейчас 640×480 → 1280×720). Нужна подгонка scale/safe area, **не** трогая framebuffer стока `1280×13107`.

### 3. Видео катсцен

`introHD.mp4` в OBB и in-game VideoPlayer. На стоке нет нормального Android MediaCodec пути в нашем JNI. Варианты: skip/stub VideoPlayer, внешний SDL/FFmpeg декодер, или принудительный skip интро (как уже планировалось в раннем handoff).

### 4. Мелкий долг (не блокеры)

- Переименовать glbridge sock/ready в `sg-*`, чтобы не конфликтовать с NFS
- Пустые тексты UI (локализация) — мешает и меню, и биндам
- Сообщение Unity `More then 1 gamepad` иногда ещё мелькает в логе (на геймплей не влияет после фикса prefs)

---

## Файлы порта (без игры)

```
Roms/PORTS/Shadowgun.sh
Imgs/PORTS/Shadowgun.png
Data/ports/shadowgun/
  shadowgun_runtime          # armhf, BUILD 76
  shadowgun_present          # aarch64 presenter
  controls.txt               # карта ввода
  glbridge/                  # 32-bit EGL/GLES client
  armhf/                     # sysroot
  host-libs/                 # SDL2 + ALSA …
  src/                       # исходники runtime + glbridge
  setup.sh, port.json, gameinfo.xml
  gamedata/README.txt        # куда класть APK/OBB (сами файлы — gitignore)
```

Игнорируются: APK, OBB, `gamefiles/android-libs/*.so`, `logs/`, `cache/`, `files/`, `assets/`, `Android/obb`, `prefs.txt`, `ORIG GAME/`.

Сборка:

```
powershell -File Data/ports/shadowgun/src/build.ps1
```

Лог на устройстве: `Data/ports/shadowgun/logs/shadowgun.log` (искать `SG-BUILD 76`, `SG-CTL`, `SG-PREFS`).

---

## Жёсткие правила

- Не трогать framebuffer стока 1.1.1  
- Не обновлять GUI PortMaster на 1.1.1  
- Лаунчеры — POSIX `sh`, только **LF**  
- FAT32 — без симлинков (дубли `.so` файлами)  
- Игру / APK / OBB / game `.so` в git не класть  

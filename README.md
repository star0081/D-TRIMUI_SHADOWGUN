# Shadowgun — порт для TrimUI Smart Pro (PortMaster)

Порт Android-версии *Shadowgun* (Madfinger Games) для **TrimUI Smart Pro**, стоковая прошивка **1.1.1** (TinaLinux, Allwinner A133P, PowerVR GE8300, 1280×720). Запуск через PortMaster / TRIMUI_EX.

Поддерживается только сборка **1.7.0 PowerVR RU** (`com.madfingergames.shadowgun`, versionCode **170300014**): Unity **5.3.8f1 IL2CPP**, GLES 2.0, текстуры **PVRTC**.

**Текущий снимок: SG-BUILD 76** (рабочий билд из `BUILD 76/`). Подробный отчёт: [`Data/ports/shadowgun/SHADOWGUN-TRIMUI.md`](Data/ports/shadowgun/SHADOWGUN-TRIMUI.md).

> В репозитории **нет** игры, APK, OBB, `libunity.so` / `libil2cpp.so`. Их нужно положить самостоятельно.

## Статус BUILD 76

Работает: запуск, звук, ходьба (левый стик), обзор (правый стик), стрельба (R2), прыжок/рывок (L1), меню (D-pad + A), сохранение чувствительности (`prefs.txt`), карта ввода без пересборки (`controls.txt`).

Ещё открыто:

- точное прицеливание
- лёгкий overflow по краям экрана (aspect / letterbox)
- видео в катсценах

## Раскладка по умолчанию

| Действие | Кнопка / ось |
|---|---|
| Ходьба | левый стик |
| Обзор | правый стик |
| Стрельба | R2 |
| Прыжок / рывок | L1 |
| Перезарядка | R1 |
| Прицел (кандидат) | L2 |
| Меню | D-pad, A |

Переназначение: правьте `Data/ports/shadowgun/controls.txt` и перезапустите игру.

## Установка

1. APK и OBB → `Data/ports/shadowgun/gamedata/` (см. `gamedata/README.txt`)
2. На ПК: `Data/ports/shadowgun/setup.sh` (достанет `libmain` / `libunity` / `libil2cpp` и положит OBB в `Android/obb/...`)
3. Скопировать на SD: `Roms/PORTS`, `Imgs/PORTS`, `Data/ports/shadowgun`
4. PortMaster → Shadowgun. Лог: `Data/ports/shadowgun/logs/shadowgun.log`

## Архитектура

Как NFS MW на том же стоке:

1. **glbridge GLES2** + PVRTC в строке расширений клиента
2. **armhf sysroot** внутри порта
3. **host-libs** — 32-bit SDL2 + ALSA
4. **Лоадер** `shadowgun_runtime` — ELF32 + Bionic-мост, JNI под Unity 5.3

Сборка: `powershell -File Data/ports/shadowgun/src/build.ps1` (Zig 0.13).

## SHA-256 донора

| Файл | SHA-256 |
|---|---|
| APK 1.7.0 PowerVR RU | `aa8e1863d90de72ea0fd80fdee748e6f37695cfd2703a9295da14a523c3caada` |
| OBB `main.170300014.com.madfingergames.shadowgun.obb` | `a61516f5a0fe2b138ebcfd88ad9b065c53f6426775c4f14e16e6d3de6f9766e3` |

## Благодарности

- Detoy / EapRules — ELF-лоадер и Bionic-мост
- Порты NFS MW и Dead Space на TrimUI 1.1.1 — glbridge и схема PortMaster

Автор: **star0081**.

Shadowgun является торговой маркой Madfinger Games. Это неофициальный проект совместимости.

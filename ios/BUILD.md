# Building Source Engine for legacy iOS (armv7, iOS 5/6+)

*Русская версия ниже — [перейти к русскому](#сборка-source-engine-под-легаси-ios-armv7-ios-56).*

---

## English

This is a fork of [nillerusr/source-engine](https://github.com/nillerusr/source-engine)
(itself based on the leaked Source SDK / TF2 2018 leak) whose goal is to run
**Half-Life 2**, **Lost Coast** and **Portal 1** on *very old* iOS devices:

| Device        | iOS      | CPU         |
|---------------|----------|-------------|
| iPad 2        | 6.1.3    | armv7 (A5)  |
| iPhone 4S     | 6.1.x    | armv7 (A5)  |
| iPhone 5      | 6.x      | armv7s      |
| iPad 4        | 6.x      | armv7s      |

> **This is a challenge/hobby port, not a polished product.** The engine ships
> *no* Valve assets — you must own the games on Steam and copy your own game
> files onto the device. The engine is just the "car without wheels".

### Why armv7 / iOS 6 and not arm64?

Arm64 iOS is already covered by other forks (e.g.
[ksagameng2/source-engine](https://github.com/ksagameng2/source-engine)).
This fork exists to push the engine down to **32-bit armv7** and **iOS 5/6**,
the last OS versions that run on the A5 devices above.

### What makes legacy iOS tricky

* **No modern Xcode toolchain targets iOS 6.** We cross-compile from Linux
  using a [cctools-port](https://github.com/tpoechtrager/cctools-port) `ld64`
  linker plus an unpacked iOS SDK.
* **SDL version matters.** SDL2 **2.0.7** is the *last* release that supports
  iOS 6.1+. SDL 2.0.8 raised the minimum to iOS 8.0. (For a future iOS 5.1.1
  target, SDL 2.0.6 is the last that works.)
* **C++ standard library.** The engine is C++11. We force `-stdlib=libc++`
  and ship a tiny `libcxx/__config_site` shim so a modern clang doesn't bake
  in availability annotations the old runtime lacks.
* **`libBlocksRuntime`** is required to build cctools-port's `ld64` on Linux.

### One-time setup: build the cross toolchain

```bash
# from the repo root, on a Linux machine (Debian/Ubuntu recommended)
sudo apt-get install -y clang llvm llvm-dev libc++-dev libc++abi-dev \
    cmake make wget tar xz-utils libssl-dev pkg-config git python3 \
    ccache uuid-dev libblocksruntime-dev

./ios/setup_toolchain.sh
```

This downloads an armv7-capable iOS SDK (iPhoneOS 9.3, still builds for
armv7) and builds, into `ios/build/work/toolchain/`:

* `libdispatch` + `libBlocksRuntime` (needed by ld64 on Linux)
* `libtapi` (so ld64 can read the SDK's `.tbd` text stubs)
* `cctools-port` → `ld64`, `lipo`, `strip`, `ranlib`, `ar`, …
* `ldid` (to fake-sign the resulting binary)

It runs once and caches everything. Re-running is a no-op if the tools exist.

### Build a game

```bash
./ios/build.sh hl2        # Half-Life 2 (also serves Lost Coast)
./ios/build.sh portal     # Portal 1
./ios/build.sh episodic   # HL2: Episodes
```

Useful flags:

```bash
./ios/build.sh hl2 --configure-only   # just run waf configure, don't build
./ios/build.sh hl2 --jobs 8           # parallel build with 8 jobs
```

The build targets `armv7-apple-ios6.0` and uses the **OpenGL ES 2** render
path (`--togles`, the DX→GL abstraction layer built for GLES). Output
libraries/binaries land in `build/`.

### How the pieces fit together

```
ios/
├── BUILD.md              ← this file
├── setup_toolchain.sh    ← builds the Linux→iOS cross toolchain (run once)
├── build.sh              ← configures + builds a chosen game for armv7 iOS
├── compat/
│   └── ios_legacy_compat.h   ← force-included POSIX/Target shims
└── libcxx/
    └── __config_site         ← libc++ site-config shim for the old SDK
```

The waf build system (`wscript`, `scripts/waifulib/xcompile.py`) was patched
so that `--ios` selects a cross-compile `iOS` toolchain class driven by the
`NBC_*` environment variables that `build.sh` exports — no macOS / `xcrun`
required.

### Current status

See the git log for the up-to-date state. In short: the cross toolchain
builds, `waf configure` reaches the iOS code paths, and the low-level engine
libraries compile for armv7. Getting a full, launchable `.ipa` is ongoing.

---

## Сборка Source Engine под легаси iOS (armv7, iOS 5/6+)

Это форк [nillerusr/source-engine](https://github.com/nillerusr/source-engine)
(который сам основан на утёкшем Source SDK / ликнутом TF2 2018), а цель —
запустить **Half-Life 2**, **Lost Coast** и **Portal 1** на *очень старых*
устройствах iOS:

| Устройство    | iOS      | Процессор   |
|---------------|----------|-------------|
| iPad 2        | 6.1.3    | armv7 (A5)  |
| iPhone 4S     | 6.1.x    | armv7 (A5)  |
| iPhone 5      | 6.x      | armv7s      |
| iPad 4        | 6.x      | armv7s      |

> **Это порт-челлендж, хобби, а не готовый продукт.** Движок **не содержит**
> ресурсов Valve — игры нужно легально купить в Steam и скопировать свои
> файлы игры на устройство. Движок — это «машина без колёс».

### Почему armv7 / iOS 6, а не arm64?

Arm64-iOS уже закрыт другими форками (например
[ksagameng2/source-engine](https://github.com/ksagameng2/source-engine)).
Смысл этого форка — опустить движок до **32-битного armv7** и **iOS 5/6**,
последних версий ОС для A5-устройств выше.

### В чём сложность легаси iOS

* **Ни один современный Xcode не таргетит iOS 6.** Мы кросс-компилируем из-под
  Linux, используя линкер `ld64` из
  [cctools-port](https://github.com/tpoechtrager/cctools-port) плюс
  распакованный iOS SDK.
* **Версия SDL важна.** SDL2 **2.0.7** — *последний* релиз с поддержкой
  iOS 6.1+. SDL 2.0.8 поднял минимум до iOS 8.0. (Для будущего таргета
  iOS 5.1.1 последний рабочий — SDL 2.0.6.)
* **Стандартная библиотека C++.** Движок на C++11. Мы принудительно ставим
  `-stdlib=libc++` и кладём крошечный шим `libcxx/__config_site`, чтобы
  современный clang не встраивал availability-аннотации, которых нет в старом
  рантайме.
* **`libBlocksRuntime`** нужен, чтобы собрать `ld64` из cctools-port под Linux.

### Разовая настройка: сборка кросс-тулчейна

```bash
# из корня репозитория, на Linux-машине (лучше Debian/Ubuntu)
sudo apt-get install -y clang llvm llvm-dev libc++-dev libc++abi-dev \
    cmake make wget tar xz-utils libssl-dev pkg-config git python3 \
    ccache uuid-dev libblocksruntime-dev

./ios/setup_toolchain.sh
```

Скрипт скачивает armv7-совместимый iOS SDK (iPhoneOS 9.3, ещё умеет armv7) и
собирает в `ios/build/work/toolchain/`:

* `libdispatch` + `libBlocksRuntime` (нужны для ld64 под Linux)
* `libtapi` (чтобы ld64 читал текстовые стабы `.tbd` из SDK)
* `cctools-port` → `ld64`, `lipo`, `strip`, `ranlib`, `ar`, …
* `ldid` (для фейковой подписи итогового бинарника)

Выполняется один раз и кэширует всё. Повторный запуск ничего не делает, если
инструменты уже собраны.

### Сборка игры

```bash
./ios/build.sh hl2        # Half-Life 2 (и Lost Coast — та же папка игры)
./ios/build.sh portal     # Portal 1
./ios/build.sh episodic   # HL2: Episodes
```

Полезные флаги:

```bash
./ios/build.sh hl2 --configure-only   # только waf configure, без сборки
./ios/build.sh hl2 --jobs 8           # параллельная сборка в 8 потоков
```

Сборка идёт под `armv7-apple-ios6.0` и использует рендер-путь **OpenGL ES 2**
(`--togles` — слой абстракции DX→GL, собранный под GLES). Итоговые
библиотеки/бинарники появляются в `build/`.

### Как всё устроено

```
ios/
├── BUILD.md              ← этот файл
├── setup_toolchain.sh    ← собирает кросс-тулчейн Linux→iOS (один раз)
├── build.sh              ← конфигурит + собирает выбранную игру под armv7 iOS
├── compat/
│   └── ios_legacy_compat.h   ← принудительно включаемые POSIX/Target-шимы
└── libcxx/
    └── __config_site         ← шим site-config для libc++ на старом SDK
```

Система сборки waf (`wscript`, `scripts/waifulib/xcompile.py`) пропатчена так,
что флаг `--ios` выбирает класс кросс-компиляции `iOS`, управляемый
переменными окружения `NBC_*`, которые экспортирует `build.sh` — macOS и
`xcrun` не требуются.

### Текущий статус

Актуальное состояние смотрите в истории git. Коротко: кросс-тулчейн
собирается, `waf configure` доходит до iOS-веток, низкоуровневые библиотеки
движка компилируются под armv7. Полноценный запускаемый `.ipa` — в работе.

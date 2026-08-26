# Cardeck

[![CI](https://github.com/vahidismylv/Cardeck/actions/workflows/ci.yml/badge.svg)](https://github.com/vahidismylv/Cardeck/actions/workflows/ci.yml)

A loyalty-card wallet for iPhone. Cards live in a stack you can flick through;
opening one lifts it out of the deck and shows a scannable barcode.

## Build

Requires Xcode 26 and iOS 18. The card material is a Metal shader, and Xcode 26
does not ship its toolchain by default — install it once:

```
xcodebuild -downloadComponent MetalToolchain
```

Then open `Cardeck.xcodeproj` and run the `Cardeck` scheme.

## Architecture

MVVM plus a coordinator. View models never import UIKit, services sit behind
protocols, and every screen is laid out in code — Storyboard is used only for the
launch screen.

```
App/          Точка входа и координатор
Core/         Тема, материал карты, движение, хаптика, настройки, анимация
Models/       Модель SwiftData, снимок для UI, схема и миграции
Services/     Хранилище, штрихкоды, яркость, сортировка
Scenes/       Wallet, CardDetail, AddEdit, Settings
```

## Design notes

- **Card material** — a fragment shader draws the gradient, a tilt-driven
  holographic band, a specular streak and grain. Corners are computed in the
  shader so no layer mask is needed and nothing renders offscreen. Devices
  without Metal, or users who switch the effect off, get a CoreAnimation
  fallback built from the same tilt data.
- **Card stack** — a custom `UICollectionViewLayout`. Cards that scroll past the
  pin line compress into an accordion of at most four, with depth applied as a
  3D transform.
- **Transition** — the live material view is moved into the container, not a
  snapshot, so the hologram keeps reacting to tilt mid-flight. Dismissal is
  interactive, interruptible and hands the gesture velocity to the spring.

## Storage

SwiftData, versioned from day one (`CDKSchemaV1` with a migration plan ready).
If the store cannot be opened — a full disk, a damaged file — the app falls back
to an in-memory container and keeps working instead of refusing to launch.

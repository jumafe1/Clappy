# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Clappy** is a macOS utility app that lives in the MacBook's notch, providing quick access to media controls and clipboard history. Built with Swift 5.9+, SwiftUI, AppKit, and Combine. Requires macOS 14.0+.

**External dependency**: `media-control` CLI (install via Homebrew). Auto-detected at `/opt/homebrew/bin/media-control` (Apple Silicon) or `/usr/local/bin/media-control` (Intel). If missing, the media slot shows installation instructions instead of controls.

## Commands

```bash
swift build           # debug build
swift run Clappy      # run the app
swift build -c release
```

No tests exist. No linter configuration.

## Architecture

MVVM with a Facade at the top and Repository pattern for persistence. All state flows through Combine publishers — no singletons except `AnimationConstants`.

### Startup / Dependency Chain

```
ClappyApp.main()
  → AppDelegate.applicationDidFinishLaunching()
      ├─ NotchFacade (aggregates MediaController, ClipboardManager, SlotConfiguration)
      ├─ NotchWindowController (positions NSPanel over notch via NSScreen.auxiliaryTopLeft/RightArea)
      ├─ NotchHoverMonitor (dual-rect hover → isHovering CurrentValueSubject → NotchContentViewModel.isExpanded)
      └─ observeScreenChanges() (repositions panel on display changes)
```

### Layer Responsibilities

| Directory | Purpose |
|---|---|
| `App/` | Entry point (`ClappyApp`) + top-level orchestration (`AppDelegate`) |
| `Architecture/` | `NotchFacade` — single injection point aggregating all services |
| `Window/` | Panel positioning, `NotchPanel` (custom NSPanel), hover/click detection |
| `UI/` | Root SwiftUI view, its VM, background blur, `AnimationConstants` |
| `Settings/` | Preferences UI + VM |
| `Features/Slots/` | Slot enable/disable and ordering framework |
| `Features/Media/` | `MediaController` (subprocess) → VM → View |
| `Features/Clipboard/` | `ClipboardManager` (NSPasteboard polling) → VM → View |

Each feature strictly separates: data model → service → `@ObservableObject` VM → SwiftUI View.

### Key Mechanics

**Hover expansion** (`NotchHoverMonitor`) — two rectangles:
1. *Trigger rect*: ±5px around the physical notch → expand on entry when collapsed
2. *Panel rect*: full 420×280pt panel → collapse on exit when expanded

**Media subprocess** (`MediaController`) — spawns `media-control stream --no-diff`, reads JSON lines from stdout. Auto-restarts up to 3× with 2s delay on crash. Progress is computed client-side: `elapsed + (Date().timeIntervalSince(lastUpdated) * playbackRate)`.

**Clipboard polling** (`ClipboardManager`) — polls `NSPasteboard` every 0.5s. Deduplicates, optimizes images (TIFF → JPEG 0.7, max 256px), keeps last 20 items.

**Notch detection** — uses `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`. Falls back to centering at top of screen on non-notch Macs.

### Persistence (UserDefaults)

| Key | Content |
|---|---|
| `clappy.clipboard.items` | `[ClipboardItem]` JSON |
| `clappy.slots.config` | `[SlotConfig]` JSON (order + enabled) |
| `clappy.trigger.mode` | `"hover"` / `"click"` / `"both"` |

### UI Constants (`AnimationConstants`)

- Collapsed: 200 × 32 pt | Expanded: 420 × 280 pt
- Corner radius: 16 pt
- Spring: response=0.35, damping=0.72

## Adding a New Feature Slot

1. Create `Features/<Name>/` with: model struct, service class (`@Published` state), `@ObservableObject` VM, SwiftUI View
2. Register the slot type in `SlotConfig.swift` and `SlotConfiguration.swift`
3. Inject the service through `NotchFacade`
4. Pass the VM from `AppDelegate` into the view hierarchy

# Clappy

A macOS utility that lives inside the MacBook notch. Hover over the notch to expand a panel with media controls and clipboard history — without taking any permanent screen space.

**Requires macOS 14 (Sonoma) or later and a MacBook with a notch.**

---

## Features

- **Media Player** — play/pause, skip tracks, see title, artist, and progress for Apple Music, Spotify, and any other player
- **Clipboard History** — keeps the last 20 copied items (text and images), click any to re-copy it

---

## Installation

1. Download the latest `.zip` from the [Releases](../../releases) page
2. Unzip and move `Clappy.app` to your `/Applications` folder
3. Open it — macOS may ask you to confirm since the app is not notarized yet; go to **System Settings → Privacy & Security** and click **Open Anyway**

---

## Requirement: media-control

The media player feature requires one external tool installed via [Homebrew](https://brew.sh):

```bash
brew install ungive/tap/media-control
```

This is needed because macOS 15.4+ on Apple Silicon restricts direct access to the system media session — `media-control` is an open-source workaround. Without it, Clappy still works but the media slot will show an installation prompt instead of your player.

> If you don't have Homebrew: [brew.sh](https://brew.sh)

---

## Usage

- **Hover** over the notch → panel expands
- **Move mouse away** → panel collapses
- **Click the menu bar icon** → open Preferences or quit

In Preferences you can change the trigger mode (hover, click, or both) and reorder or disable slots.

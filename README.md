# MyLittleEasterProject
macOS rework

# 🌌 MacLiveEngine

A high-performance, feature-rich **live wallpaper engine for macOS**. Bring your desktop to life with videos, shaders, particle systems, web content, generative art, and more.

## ✨ Features

### Wallpaper Types
- **🎬 Video** — MP4, MOV, MKV, AVI, WebM with loop, speed, and volume control
- **🌐 Web / HTML5** — Any webpage or local HTML as your wallpaper, with JS API
- **🎨 Metal Shaders** — Write custom GPU shaders (Shadertoy-style) with live uniforms
- **✨ Particle Systems** — GPU-accelerated particles (starfield, snow, rain, fireflies, galaxy)
- **🖼 Image Slideshow** — Folders of images with crossfade, slide, zoom transitions
- **🎭 Quartz Composer** — Classic `.qtz` compositions
- **🧬 Generative Art** — Algorithmic art (flow fields, Voronoi, Julia fractals)

### Core Engine
- **Multi-monitor** — Independent wallpapers per display, or span across all
- **Desktop-level windows** — Sits behind all apps, works on all Spaces
- **Auto-pause** — Pauses when fullscreen app detected, on battery, or on sleep
- **Battery-aware** — Reduces FPS automatically on battery power
- **Configurable FPS** — 15, 24, 30, 60, or 120 FPS
- **CPU/Memory monitoring** — Real-time performance stats in the menu bar

### Audio Reactive
- **System audio capture** — Wallpapers react to music
- **FFT spectrum analysis** — Bass, mid, treble, and per-band data
- **Smoothing** — Configurable smoothing for fluid reactions
- **Forwarded to all renderers** — Shaders, particles, and web wallpapers all receive audio

### Playlist System
- **Auto-advancement** — Cycle through wallpapers on a timer
- **Shuffle mode** — Randomized playback order
- **Configurable intervals** — 30s to 1 hour
- **Directory scanning** — Add entire folders at once

### Scheduling
- **Day/Night cycle** — Different wallpapers for day and night
- **Configurable hours** — Set sunrise and sunset times

### Transitions
- Crossfade, Dissolve, Slide (L/R), Zoom In/Out, or None

### Weather Integration
- Fetches real weather via Open-Meteo (free, no API key)
- Suggests particle/shader presets based on current conditions

### Plugin System
- Load third-party `.bundle` plugins at runtime
- Full plugin API with host interface
- Plugins can provide custom renderers

### Scripting
- JSON-based script system for automation
- `onStart`, `onFrame`, `onAudio`, `onStop` hooks

### Global Hotkeys
| Shortcut | Action |
|---|---|
| `⌃⌥⌘P` | Play / Pause |
| `⌃⌥⌘N` | Next wallpaper |
| `⌃⌥⌘B` | Previous wallpaper |
| `⌃⌥⌘M` | Mute / Unmute |

### Other
- Menu bar app (no Dock icon)
- File change watching (hot-reload shaders)
- Wallpaper downloader with progress tracking
- Persistent JSON configuration
- Rotating log files
- Full unit test suite

## 🚀 Building

```bash
git clone https://github.com/yourusername/MacLiveEngine.git
cd MacLiveEngine
swift build -c release

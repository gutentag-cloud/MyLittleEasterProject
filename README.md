# MyLittleEasterProject
macOS rework

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=for-the-badge&logo=apple" />
  <img src="https://img.shields.io/badge/swift-5.9-orange?style=for-the-badge&logo=swift" />
  <img src="https://img.shields.io/badge/metal-GPU%20Accelerated-red?style=for-the-badge&logo=apple" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" />
</p>

<h1 align="center">🌌 MacLiveEngine</h1>

<p align="center">
  <strong>A professional-grade, GPU-accelerated live wallpaper engine for macOS.</strong>
  <br />
  Videos · Metal Shaders · Particles · Web Content · Generative Art · Audio Reactive
  <br /><br />
  <em>Transform your desktop into something extraordinary.</em>
</p>

---

## Table of Contents

- [Overview](#overview)
- [Screenshots & Demos](#screenshots--demos)
- [Feature List](#feature-list)
- [Supported Wallpaper Types](#supported-wallpaper-types)
  - [Video Wallpapers](#-video-wallpapers)
  - [Metal Shader Wallpapers](#-metal-shader-wallpapers)
  - [Particle System Wallpapers](#-particle-system-wallpapers)
  - [Web / HTML5 Wallpapers](#-web--html5-wallpapers)
  - [Image Slideshow Wallpapers](#-image-slideshow-wallpapers)
  - [Generative Art Wallpapers](#-generative-art-wallpapers)
  - [Quartz Composer Wallpapers](#-quartz-composer-wallpapers)
- [System Requirements](#system-requirements)
- [Installation](#installation)
  - [Build from Source](#build-from-source)
  - [Manual Installation](#manual-installation)
  - [First Launch](#first-launch)
- [Getting Started](#getting-started)
  - [Setting Your First Wallpaper](#setting-your-first-wallpaper)
  - [Menu Bar Controls](#menu-bar-controls)
  - [Quick Start Examples](#quick-start-examples)
- [Configuration Guide](#configuration-guide)
  - [General Settings](#general-settings)
  - [Wallpaper Settings](#wallpaper-settings)
  - [Performance Settings](#performance-settings)
  - [Audio Settings](#audio-settings)
  - [Playlist Settings](#playlist-settings)
  - [Schedule Settings](#schedule-settings)
  - [Shader Settings](#shader-settings)
  - [Particle Settings](#particle-settings)
  - [Slideshow Settings](#slideshow-settings)
  - [Generative Art Settings](#generative-art-settings)
  - [Configuration File Reference](#configuration-file-reference)
- [Multi-Monitor Support](#multi-monitor-support)
- [Audio Reactive System](#audio-reactive-system)
  - [How It Works](#how-it-works)
  - [Audio Data Format](#audio-data-format)
  - [Using Audio in Shaders](#using-audio-in-shaders)
  - [Using Audio in Web Wallpapers](#using-audio-in-web-wallpapers)
- [Playlist System](#playlist-system)
  - [Creating a Playlist](#creating-a-playlist)
  - [Playlist Controls](#playlist-controls)
  - [Shuffle Mode](#shuffle-mode)
  - [Transition Effects](#transition-effects)
- [Day/Night Scheduling](#daynight-scheduling)
- [Weather Integration](#weather-integration)
- [Performance & Power Management](#performance--power-management)
  - [FPS Control](#fps-control)
  - [Battery Optimization](#battery-optimization)
  - [Fullscreen App Detection](#fullscreen-app-detection)
  - [Sleep/Wake Handling](#sleepwake-handling)
  - [Performance Monitor](#performance-monitor)
  - [Resource Limits](#resource-limits)
- [Global Hotkeys](#global-hotkeys)
- [Writing Custom Metal Shaders](#writing-custom-metal-shaders)
  - [Shader Structure](#shader-structure)
  - [Available Uniforms](#available-uniforms)
  - [Example Shaders](#example-shaders)
  - [Hot-Reloading Shaders](#hot-reloading-shaders)
- [Creating Web Wallpapers](#creating-web-wallpapers)
  - [JavaScript API Reference](#javascript-api-reference)
  - [Sending Messages to Engine](#sending-messages-to-engine)
  - [Example Web Wallpapers](#example-web-wallpapers)
- [Plugin Development](#plugin-development)
  - [Plugin Architecture](#plugin-architecture)
  - [Creating a Plugin Bundle](#creating-a-plugin-bundle)
  - [Plugin Protocol Reference](#plugin-protocol-reference)
  - [Host API Reference](#host-api-reference)
  - [Installing Plugins](#installing-plugins)
  - [Example Plugin](#example-plugin)
- [Scripting System](#scripting-system)
  - [Script Format](#script-format)
  - [Available Actions](#available-actions)
  - [Example Scripts](#example-scripts)
- [File Locations](#file-locations)
- [Architecture](#architecture)
  - [Project Structure](#project-structure)
  - [Architecture Diagram](#architecture-diagram)
  - [Core Components](#core-components)
  - [Renderer Lifecycle](#renderer-lifecycle)
  - [Event Flow](#event-flow)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Log Files](#log-files)
  - [Debug Mode](#debug-mode)
  - [Reporting Bugs](#reporting-bugs)
- [FAQ](#faq)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
  - [Development Setup](#development-setup)
  - [Code Style](#code-style)
  - [Pull Request Guidelines](#pull-request-guidelines)
  - [Adding a New Renderer](#adding-a-new-renderer)
- [Acknowledgments](#acknowledgments)
- [License](#license)

---

## Overview

**MacLiveEngine** is a native macOS application that replaces your static desktop wallpaper with dynamic, animated, and interactive content. It runs as a lightweight menu bar app with no Dock icon, rendering content on a special window pinned behind all other windows at the desktop level.

Unlike simple video wallpaper apps, MacLiveEngine is a full **engine** — it supports seven distinct rendering backends, a GPU-accelerated particle system, real-time audio reactivity via FFT analysis, a playlist system with animated transitions, day/night scheduling, weather-aware wallpaper suggestions, a plugin architecture for third-party extensions, a scripting system, and comprehensive power management that automatically adapts to battery state and application focus.

Every component is designed for **minimal resource usage** — the engine automatically pauses when a fullscreen app is in use, reduces frame rates on battery power, and monitors its own CPU and memory consumption.

---

## Screenshots & Demos

> Since this is a terminal-built application without pre-built screenshots, here is what each mode looks like:

| Mode | Description |
|---|---|
| **Video** | Full-screen looping video with configurable speed, volume, and scaling |
| **Metal Shader** | Real-time GPU fragment shaders with plasma, fractals, and custom effects |
| **Particles** | Thousands of GPU-computed particles forming starfields, rain, snow, galaxies |
| **Web / HTML5** | Any webpage running as your wallpaper with full JavaScript interop |
| **Slideshow** | Image folders cycling with crossfade, slide, zoom, and dissolve transitions |
| **Generative Art** | Algorithmic visualizations — flow fields, Voronoi diagrams, Julia fractals |
| **Quartz Composer** | Classic macOS `.qtz` compositions rendered live |

---

## Feature List

### Rendering Engine (7 Backends)
- [x] **Video rendering** via AVFoundation (MP4, MOV, MKV, AVI, WebM)
- [x] **Web rendering** via WKWebView (HTML5, CSS3, WebGL, local files)
- [x] **Metal shader rendering** with Shadertoy-style fragment shaders
- [x] **GPU particle systems** with compute shaders (up to 100K+ particles)
- [x] **Image slideshows** with 6 transition effects
- [x] **Generative art** with 3 algorithmic presets
- [x] **Quartz Composer** composition playback

### Display Management
- [x] Multi-monitor support with per-display wallpaper control
- [x] Span wallpaper across all displays
- [x] Automatic display detection and reconfiguration
- [x] Proper desktop-level window management
- [x] Works across all Spaces/Desktops
- [x] Handles display connect/disconnect
- [x] Handles screen resolution changes
- [x] Space change re-assertion

### Audio Reactive System
- [x] Real-time audio capture from system input
- [x] 1024-point FFT frequency analysis
- [x] Hanning window preprocessing
- [x] 64-band frequency spectrum output
- [x] Bass / Mid / Treble frequency split
- [x] Overall audio level tracking
- [x] Configurable smoothing factor
- [x] Configurable sensitivity
- [x] Audio data forwarded to all renderer types
- [x] dB normalization with min/max scaling

### Playlist System
- [x] Add files or entire directories
- [x] Configurable advancement intervals (30s – 1 hour)
- [x] Shuffle mode with Fisher-Yates shuffling
- [x] Previous / Next navigation
- [x] Clear playlist
- [x] Persistent across restarts
- [x] Auto-detection of wallpaper type per file

### Transition Effects
- [x] None (instant switch)
- [x] Crossfade
- [x] Dissolve (CATransition)
- [x] Slide Left
- [x] Slide Right
- [x] Zoom In
- [x] Zoom Out
- [x] Configurable duration

### Scheduling
- [x] Day/Night wallpaper cycle
- [x] Configurable sunrise/sunset hours
- [x] Automatic switching every 60 seconds
- [x] Separate wallpaper files for day and night

### Weather Integration
- [x] Location-based weather fetching via CoreLocation
- [x] Free API (Open-Meteo, no API key required)
- [x] Weather condition detection (clear, cloudy, rain, snow, thunderstorm, fog, wind)
- [x] Temperature tracking
- [x] Day/Night detection from weather API
- [x] Particle preset suggestions per weather condition
- [x] Shader preset suggestions per weather condition
- [x] 30-minute auto-refresh

### Performance & Power Management
- [x] Configurable target FPS (15, 24, 30, 60, 120)
- [x] Battery state monitoring via IOKit
- [x] Automatic FPS reduction on battery
- [x] Automatic pause on battery (optional)
- [x] Fullscreen app detection and auto-pause
- [x] Sleep/Wake handling
- [x] Real-time FPS counter (CVDisplayLink)
- [x] CPU usage tracking per thread
- [x] Memory usage tracking (resident set size)
- [x] Configurable max CPU percentage
- [x] Configurable max memory limit

### Plugin System
- [x] Runtime `.bundle` loading
- [x] Plugin discovery from designated directory
- [x] Full plugin lifecycle (load/unload)
- [x] Plugin host API (logging, audio, config, wallpaper control)
- [x] Custom renderer support via plugins
- [x] Custom preferences UI via plugins
- [x] Duplicate plugin detection

### Scripting System
- [x] JSON-based script format
- [x] `onStart` / `onFrame` / `onAudio` / `onStop` hooks
- [x] Engine control actions (FPS, speed, next/previous)
- [x] Property setting actions
- [x] Logging from scripts

### User Interface
- [x] Menu bar app (no Dock icon, `NSStatusItem`)
- [x] Real-time status display (state, FPS, CPU, memory)
- [x] Playback controls (play/pause, next, previous)
- [x] Wallpaper type selector submenu
- [x] File open panel with type filtering
- [x] Display selector submenu with toggle per display
- [x] Performance submenu with FPS selection
- [x] Battery and fullscreen pause toggles
- [x] Audio reactive toggle
- [x] Playlist submenu (enable, shuffle, interval, add, clear)
- [x] Schedule submenu (day/night wallpapers, enable toggle)
- [x] Preferences window with tabs (General, Performance, Audio, Advanced)
- [x] Launch at login toggle

### Global Hotkeys
- [x] `⌃⌥⌘P` — Play / Pause
- [x] `⌃⌥⌘N` — Next wallpaper
- [x] `⌃⌥⌘B` — Previous wallpaper
- [x] `⌃⌥⌘M` — Mute / Unmute

### Networking
- [x] Wallpaper file downloader with progress tracking
- [x] Resume support via URLSession
- [x] Download directory management
- [x] Async/await and callback APIs

### File System
- [x] File change watching (DispatchSource)
- [x] Hot-reload for shader files
- [x] Directory scanning for slideshows and playlists
- [x] Automatic file type detection from extensions

### Logging
- [x] Unified logging via `os_log` and file output
- [x] Four log levels (DEBUG, INFO, WARN, ERROR)
- [x] Timestamps with millisecond precision
- [x] Source file and line number in each entry
- [x] Automatic log rotation at 10MB
- [x] Separate logging queue (non-blocking)

### Persistence
- [x] Full JSON configuration with 40+ keys
- [x] Auto-save on changes
- [x] Safe loading with defaults for missing keys
- [x] Application Support directory storage

### Built-in Content
- [x] Default plasma shader (no files needed to start)
- [x] 5 particle presets (starfield, fireflies, snow, rain, galaxy)
- [x] 3 generative art presets (flow field, Voronoi, Julia fractal)
- [x] Noise functions (hash, value noise, fBm) in shader library

### Testing
- [x] Configuration save/load test
- [x] Wallpaper type detection test
- [x] Audio spectrum data test
- [x] Playlist manager test
- [x] Display manager test
- [x] URL extension test
- [x] Math utility test
- [x] Safe subscript test
- [x] Scheduler test

**Total: 100+ individual features**

---

## Supported Wallpaper Types

### 🎬 Video Wallpapers

Play any video file as your desktop wallpaper using Apple's AVFoundation framework.

**Supported Formats:**
| Format | Extension | Notes |
|---|---|---|
| MPEG-4 | `.mp4`, `.m4v` | Best compatibility and performance |
| QuickTime | `.mov` | Native macOS format |
| AVI | `.avi` | Legacy format, transcoding recommended |
| Matroska | `.mkv` | Requires compatible codecs |
| WebM | `.webm` | VP8/VP9 support varies |

**Video Controls:**
| Control | Range | Default | Description |
|---|---|---|---|
| Volume | 0.0 – 1.0 | 0.0 (muted) | Audio volume of the video |
| Playback Speed | 0.1 – 4.0 | 1.0 | Speed multiplier |
| Loop | on/off | on | Seamless looping via `AVPlayerLooper` |
| Scale Mode | fill/fit/stretch/center | fill | How the video fits the screen |

**Implementation Details:**
- Uses `AVQueuePlayer` with `AVPlayerLooper` for gapless looping
- `AVPlayerLayer` for hardware-accelerated compositing
- `preventsDisplaySleepDuringVideoPlayback` set to `false` to allow sleep
- Seek support via `setProperty("position", value: seconds)`

---

### 🎨 Metal Shader Wallpapers

Write custom GPU fragment shaders that run at full screen resolution. The system provides a Shadertoy-compatible interface with time, resolution, mouse, and audio uniforms.

**How It Works:**
1. A fullscreen quad (two triangles as a triangle strip) is rendered each frame
2. The vertex shader passes UV coordinates to the fragment shader
3. The fragment shader computes the color for every pixel
4. Audio spectrum data is passed as uniform variables

**Performance:**
- Fragment shaders execute on the GPU, leaving the CPU nearly idle
- Typical GPU usage: 5-15% for complex shaders at 30 FPS / 1080p
- Metal's low-overhead API ensures minimal driver cost

See [Writing Custom Metal Shaders](#writing-custom-metal-shaders) for full documentation.

---

### ✨ Particle System Wallpapers

GPU-accelerated particle systems using Metal compute shaders. Particles are updated entirely on the GPU, then rendered as point sprites with distance-based alpha falloff.

**Built-in Presets:**

| Preset | Particles | Description |
|---|---|---|
| `starfield` | 5,000 | Twinkling stars with random drift |
| `fireflies` | 5,000 | Warm glowing dots floating upward |
| `snow` | 5,000 | Falling snowflakes with horizontal drift |
| `rain` | 5,000 | Fast-falling raindrops |
| `galaxy` | 5,000 | Orbital motion around center with color gradient |

**Particle Properties:**
Each particle stores: position (2D), velocity (2D), color (RGBA), size, current life, max life.

**Pipeline:**
1. **Compute Pass:** `updateParticles` kernel — updates position, velocity, life; respawns dead particles
2. **Render Pass:** `particleVertex` + `particleFragment` — renders particles as point sprites with circular falloff

**Audio Reactivity:**
- `audioLevel` multiplies velocity for beat-responsive movement
- Bass frequencies boost particle speed, treble affects brightness

---

### 🌐 Web / HTML5 Wallpapers

Use any webpage — local HTML files or live URLs — as your wallpaper. Full WebKit rendering with JavaScript API for engine communication.

**Features:**
- Full HTML5/CSS3/WebGL support via WKWebView
- JavaScript lifecycle callbacks
- Audio spectrum forwarding to JavaScript
- Custom property forwarding
- File access for local HTML files
- Background transparency support
- Autoplay for media elements (no user gesture required)

See [Creating Web Wallpapers](#creating-web-wallpapers) for the full JavaScript API.

---

### 🖼 Image Slideshow Wallpapers

Cycle through a directory of images with animated transitions.

**Supported Image Formats:**
PNG, JPEG, GIF, HEIC, TIFF, WebP, BMP

**Transition Effects:**
| Effect | Description |
|---|---|
| None | Instant switch |
| Crossfade | Both images blend simultaneously |
| Dissolve | CATransition-based pixel dissolve |
| Slide Left | New image slides in from right |
| Slide Right | New image slides in from left |
| Zoom In | New image grows from center |
| Zoom Out | Old image shrinks away |

**Configuration:**
- Interval: How long each image is shown (default: 10 seconds)
- Transition duration: How long the animation takes (default: 1.5 seconds)
- Shuffle: Randomize image order

---

### 🧬 Generative Art Wallpapers

Algorithmic, procedural visualizations rendered in real-time on the GPU.

**Built-in Presets:**

| Preset | Algorithm | Description |
|---|---|---|
| `flow_field` | Fractional Brownian Motion (fBm) | Flowing, organic color fields that shift over time |
| `voronoi` | Voronoi tessellation | Animated cell boundaries with distance-based coloring |
| `fractal` | Julia set | Continuously morphing Julia fractal with animated `c` parameter |

**Noise Library:**
All generative shaders have access to built-in noise functions:
- `hash(float2)` — Pseudo-random hash
- `noise(float2)` — Value noise with smooth interpolation
- `fbm(float2)` — 6-octave fractional Brownian motion

---

### 🎭 Quartz Composer Wallpapers

Render classic macOS Quartz Composer (`.qtz`) compositions as live wallpapers.

> ⚠️ Quartz Composer is deprecated by Apple but still functional. The `QCView` API is used for rendering.

**Audio Input Keys:**
If your composition has input ports named `audioLevel`, `audioBass`, `audioMid`, or `audioTreble`, they will automatically receive real-time audio data.

---

## System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| **macOS** | 13.0 Ventura | 14.0+ Sonoma |
| **CPU** | Any 64-bit Intel or Apple Silicon | Apple Silicon (M1+) |
| **GPU** | Metal-capable | Apple Silicon integrated or discrete AMD/NVIDIA |
| **RAM** | 4 GB | 8 GB+ |
| **Disk** | 50 MB (app) + wallpaper files | SSD recommended |
| **Swift** | 5.9 | 5.9+ |
| **Xcode** | 15.0 (for building) | 15.0+ |

**Notes:**
- Metal is required for shader and particle wallpapers; video and web wallpapers work without Metal
- Audio reactive features require microphone/audio input permission
- Weather features require location permission
- Global hotkeys require Accessibility permission

---

## Installation

### Build from Source

**Prerequisites:**
- Xcode 15+ or Swift 5.9+ toolchain
- macOS 13.0+
- Command Line Tools (`xcode-select --install`)

```bash
# Clone the repository
git clone https://github.com/CosmicCrusader23/MacLiveEngine.git
cd MacLiveEngine

# Build in release mode
swift build -c release

# The binary is at:
# .build/release/MacLiveEngine

# Run directly
.build/release/MacLiveEngine

# Or copy to /usr/local/bin for global access
cp .build/release/MacLiveEngine /usr/local/bin/

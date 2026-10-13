# 📱 FrameCount — Short-Form Video Counter & Digital Wellbeing HUD

<div align="center">

![FrameCount Banner](assets/girl_happy.png)

**A discreet, intelligent on-screen companion that tracks short-form video consumption across Instagram Reels, TikTok, and YouTube Shorts.**

[![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-Android_Native-7F52FF?logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![Platform](https://img.shields.io/badge/Platform-Android_8.0+-3DDC84?logo=android&logoColor=white)](https://android.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)

[Features](#-key-features) • [How It Works](#-how-it-works-under-the-hood) • [Reactive 3D Avatar](#-reactive-3d-model-companion) • [Screenshots](#-ui-preview) • [Installation](#-installation--setup) • [Architecture](#-architecture)

</div>

---

## 🎯 Overview

Short-form video algorithms intentionally eliminate clocks and friction to induce endless scrolling. **FrameCount** reintroduces conscious awareness through a persistent, floating on-screen HUD (Head-Up Display) with a **reactive 3D companion model** that visualizes your screen time in real-time.

---

## ✨ Key Features

- **⚡ Zero Extra Permission Prompts:** Uses Android's `TYPE_ACCESSIBILITY_OVERLAY` engine, completely bypassing the intrusive manual *"Display Over Other Apps"* requirement.
- **🔄 Smart Automation:** Automatically pops onto your screen when you launch **Instagram Reels**, **TikTok**, or **YouTube Shorts**, and hides when you switch to other apps.
- **🛡️ Anti-Twitch Stability:** Eliminates flickering during long video viewing sessions and internal app window transitions.
- **⏱️ 2.2s Debounce Protection:** Filters out rapid finger fidgeting, pause taps, and accidental gestures so only genuine video transitions increment the count.
- **🎭 Reactive 3D Character Avatar:**
  - **Happy & Winking** (`< 30 videos`): Energetic 3D animated companion celebrating mindful consumption.
  - **Sad & Crying** (`≥ 30 videos`): Expresses emotional fatigue when excessive doomscrolling thresholds are reached.
- **📊 Real-time Dashboard:** Track platform breakdowns, estimated minutes lost, and live session tallies.
- **🧹 Instant Data Reset:** One-tap **Clear All Data** button with native database wipe.

---

## 🛠️ How It Works Under The Hood

```
+-------------------------------------------------------------+
|                     Android Accessibility OS                |
+-------------------------------------------------------------+
                              │
            AccessibilityEvent.TYPE_VIEW_SCROLLED
                              ▼
+-------------------------------------------------------------+
|               FrameCountAccessibilityService                |
|  • Filters Target Packages (Instagram, TikTok, Shorts)      |
|  • Verifies active window hierarchy (rootInActiveWindow)    |
|  • 2,200ms Dwell / Debounce Filter                         |
+-------------------------------------------------------------+
                              │
               Updates Counter & Mood State
                              ▼
+-------------------------------------------------------------+
|              Floating Window HUD (WindowManager)            |
|  • TYPE_ACCESSIBILITY_OVERLAY (Zero-permission)             |
|  • Smooth Draggable & Repositionable Touch Listener         |
|  • Dynamic 3D Avatar (ic_girl_happy vs ic_girl_sad)         |
+-------------------------------------------------------------+
                              ▲
                 MethodChannel Sync Bridge
                              │
+-------------------------------------------------------------+
|                    Flutter Light UI (Dart)                  |
|  • Live Statistics Dashboard & Time Lost Calculator         |
|  • One-Tap Accessibility Activation                         |
|  • Clear All Data Reset Button                              |
+-------------------------------------------------------------+
```

---

## 🎭 Reactive 3D Model Companion

| Status | Threshold | 3D Companion Expression | Theme Accent |
| :--- | :--- | :--- | :--- |
| **Chill & Vibing** | `< 30 videos` | **Winking 3D Girl Avatar** | `#10B981` Emerald Green |
| **Limit Exceeded** | `≥ 30 videos` | **Crying Sad 3D Girl Avatar** | `#EF4444` Crimson Red |

---

## 📱 Supported Platforms

| Platform | Package Identifier | Supported Feed |
| :--- | :--- | :--- |
| **Instagram** | `com.instagram.android` | Instagram Reels |
| **TikTok** | `com.zhiliaoapp.musically` / `com.ss.android.ugc.trill` | For You Feed |
| **YouTube** | `com.google.android.youtube` | YouTube Shorts |

---

## 🚀 Installation & Setup

### Prerequisites
- Android device running **Android 8.0 (API 26)** or higher.
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.

### 1. Clone the Repository
```bash
git clone https://github.com/daniyal0mughal/FrameCount.git
cd FrameCount/frontend
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run on Connected Device
```bash
flutter run
```

### 4. Build APK for Distribution
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔒 Privacy & Local-First Philosophy

- **Zero Network Tracking:** No analytics, screen captures, or telemetry are ever sent to external servers.
- **100% On-Device:** All counters and session records are stored locally in Android's private `SharedPreferences`.
- **Accessibility Boundary:** The service exclusively listens to scroll gestures and active package names without capturing keystrokes or private messages.

---

## 👨‍💻 Author

**Daniyal Mughal**  
- GitHub: [@daniyal0mughal](https://github.com/daniyal0mughal)  
- Email: danialahmed005@gmail.com  

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

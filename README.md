# 🪐 Pluto — Hi-Fi Audio Note Workstation

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-4CAF50)](https://flutter.dev/multi-platform)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(7%2F7)-brightgreen)](#testing)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> **Pluto** is a cross-platform audio note-taking workstation engineered for recording, organizing, and syncing voice notes with uncompromising audio fidelity, instant responsiveness, and a bespoke studio dark aesthetic.

---

## ✨ Features at a Glance

### 🎙️ 48 kHz / 256 kbps Studio Audio Engine
* **Pristine Fidelity**: Native 48 kHz stereo recording encoded in high-bitrate Opus (256 kbps), preserving every nuance and frequency dynamic without muffling or pitch drift.
* **Low-Latency Monitoring**: Real-time microphone input metering with continuous amplitude polling.
* **Adaptive Platform Bridge**: Custom web, desktop (Windows, macOS, Linux), and mobile (Android, iOS) audio adapters with safe null-coerced lifecycle management.

### ⚡ Zero-Latency Playback Controller
* **Optimistic Response**: 0ms immediate UI state updates for play, pause, and seek interactions without UI thread stalling.
* **Variable Speed Control**: Instant playback speed cycling (`1.0x` • `1.25x` • `1.5x` • `2.0x`) with preserved audio pitch.
* **Interactive Waveform Scrubbing**: Precision position seeking with hardware-rendered waveform indicators and auto-rewind on completion.

### 🌊 Hardware-Accelerated Waveform Visualizer
* **CustomPainter Performance**: 60 / 120 FPS hardware-accelerated canvas rendering with anti-aliased gradient bars.
* **Tactile Studio Cursors**: Live playback progress scrub head with web mouse cursors, glowing playhead, and dynamic bar height modulation.

### 💾 Offline-First Architecture
* **Hive Local Database**: Blazing fast sub-millisecond local storage boxes for notes, categories, and settings.
* **Offline Recording**: Capture and manage audio notes anywhere without active network access.
* **Auto-Sync Queue**: Notes automatically queue for cloud replication the moment connectivity is restored.

### ☁️ Cloud Sync & Multi-Device Continuity
* **Firestore Replication**: Real-time bi-directional synchronization with Firebase Cloud Firestore.
* **Account Flexibility**: Seamless Google Sign-In with guest anonymous mode and non-destructive account merging.
* **Storage Telemetry**: Real-time cloud storage usage tracker and synchronization status indicators.

### 🏷️ Intelligent Organization
* **Category Tagging**: Color-coded category tags with custom creation, editing, and filtering.
* **Search & Filters**: Instant debounced full-text search across titles, summaries, and transcripts.
* **Soft-Delete Trash Bin**: Safe note deletion with 30-day trash retention, restore functionality, and permanent purge.

### 🎨 Obsidian Carbon & Studio Vermilion Design System
* **Bespoke Theme**: High-contrast dark palette built around Obsidian Carbon (`#0C0E14`), Studio Vermilion (`#FF5238`), and warm amber accents.
* **Tactile Micro-Interactions**: Custom interactive scale presses, haptic touches, and fluid spring animations.

---

## 🏗️ Architecture & Project Structure

Pluto follows a **Domain-Driven Feature-First Architecture** powered by **Flutter Riverpod** state management:

```
pluto/
├── android/                 # Android native runner & Gradle configs
├── ios/                     # iOS runner & Xcode workspace
├── web/                     # Web assembly / HTML5 shell
├── windows/                 # Windows C++ Win32 runner
├── macos/                   # macOS native runner
├── linux/                   # Linux GTK CMake runner
├── docs/
│   └── PRD.md               # Product Requirements Document
├── test/
│   ├── unit_and_component_test.dart  # Unit & domain test suite
│   └── widget_test.dart               # Widget rendering test
└── lib/
    ├── main.dart            # App entry point & initialization
    ├── firebase_options.dart # FlutterFire platform configurations
    ├── app_shell/
    │   └── pluto_home_shell.dart     # Responsive shell & navigation
    ├── core/
    │   ├── theme/           # AppColors & AppTheme design tokens
    │   ├── utils/           # Time, date, and audio formatters
    │   └── widgets/         # AudioWaveform, CategoryPill, SyncPill
    ├── features/
    │   ├── auth/            # Google Sign-In & Auth Sheet
    │   ├── categories/      # Category entity & management modal
    │   ├── notes/           # AudioNote entity, note list, cards, sheets
    │   ├── profile/         # User profile & storage telemetry
    │   ├── recorder/        # Studio Recording Orb & Live Waveform
    │   └── trash/           # Trash bin recovery sheet
    ├── pluto_audio_service.dart     # 48 kHz Opus audio engine
    ├── pluto_app_controller.dart    # Optimistic playback controller
    ├── pluto_note_repository.dart   # Hive + Firestore repository
    ├── pluto_local_store.dart       # Hive local boxes
    ├── pluto_cloud_sync_service.dart# Firestore synchronization engine
    └── pluto_auth_service.dart      # Firebase auth provider
```

---

## 🛠️ Technology Stack

| Component | Library / Framework | Purpose |
|---|---|---|
| **Core Framework** | [Flutter](https://flutter.dev) (Dart 3) | Multi-platform native UI engine |
| **State Management** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) | Declarative, compile-safe dependency injection |
| **Audio Playback** | [just_audio](https://pub.dev/packages/just_audio) | Gapless, pitch-preserved audio playback engine |
| **Audio Recording** | [record](https://pub.dev/packages/record) | 48 kHz stereo Opus microphone capture |
| **Local Storage** | [hive_flutter](https://pub.dev/packages/hive_flutter) | High-speed NoSQL key-value database |
| **Cloud Backend** | [cloud_firestore](https://pub.dev/packages/cloud_firestore) | Real-time cloud note synchronization |
| **Authentication** | [firebase_auth](https://pub.dev/packages/firebase_auth) & [google_sign_in](https://pub.dev/packages/google_sign_in) | Secure federated identity management |
| **Network Monitor** | [connectivity_plus](https://pub.dev/packages/connectivity_plus) | Real-time offline/online transition detection |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.10.8` or newer)
* [Dart SDK](https://dart.dev/get-dart) (`^3.10.8` or newer)
* Target platform toolchain:
  * **Android**: Android Studio with SDK build tools & NDK
  * **iOS / macOS**: Xcode 15+ (macOS only)
  * **Windows**: Visual Studio 2022 with C++ desktop workload
  * **Linux**: `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`
  * **Web**: Chrome or any modern HTML5 audio-compliant browser

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/BioSOnline/pluto.git
   cd pluto
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify analyzer & diagnostics:**
   ```bash
   dart analyze lib
   ```

4. **Run the test suite:**
   ```bash
   flutter test
   ```

---

## 📱 Running the Application

### Running on Chrome / Web
```bash
flutter run -d chrome
```

### Running on Android Device / Emulator
```bash
flutter run -d android
```

### Running on Windows Desktop
```bash
flutter run -d windows
```

### Running on macOS Desktop
```bash
flutter run -d macos
```

---

## 🧪 Testing

Pluto includes automated test suites covering audio note serialization, optimistic controller operations, and widget tree rendering:

```bash
flutter test
```

### Test Coverage Highlights
* **AudioNote Model Serialization**: Validates JSON conversion, copyWith immutable updates, and field integrity.
* **Category Model**: Verifies ID generation, default categories, and color formatting.
* **PlutoAppController**: Validates optimistic zero-latency audio play/pause, position scrubbing, and speed cycling.
* **UI Component Trees**: Ensures responsive card scaling, badges, and waveform canvas rendering.

---

## 🔒 Security & Privacy

* **Local Data Encryption**: Local Hive databases run sandboxed within the host application directory.
* **Cloud Security Rules**: Firestore documents are scoped strictly to the authenticated `userId`.
* **Zero Background Recording**: Microphone capture ceases immediately upon stopping, with active hardware release.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

Developed by **Adnan Irfan** ([@BioSOnline](https://github.com/BioSOnline))  
GitHub: [https://github.com/BioSOnline/pluto](https://github.com/BioSOnline/pluto)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/images/banner_dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/images/banner_light.png">
    <img alt="Poke: Iring" src="assets/images/banner_dark.png" width="420" />
  </picture>
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%2014%2B-4CAF50)](#supported-platform)
[![Status](https://img.shields.io/badge/Status-Planning%20Stage-orange)](#project-status)

> **Gotta Spot 'Em All.** A real-world feline exploration and discovery game for Android. Step outside, scan neighborhood cats with on-device machine learning, catalog sightings in your *Iring-dex*, and map feline waypoints with your community.

---

## Project Status

> **Current Phase: Planning & Design (Pre-Alpha)**  
> Poke: Iring is currently in active design and concept specification. The project structure, team workflow, governance policies, and initial Android boilerplate are established as the foundational base for feature development.

---

## The Concept

*Iring* is the Cebuano/Bisaya word for cat. Inspired by classic creature-collection games, **Poke: Iring** addresses sedentary routines by turning neighborhood walks into a gamified feline expedition.

Instead of hunting virtual monsters, players discover and catalog real-world neighborhood cats. Sightings are photographed and processed by an on-device machine learning model to classify breeds and patterns, encouraging physical activity and neighborhood exploration.

---

## Planned Core Features

- **AI Cat Scanner & Rarity Rater**: Point your device camera at a feline to classify its breed and coat pattern with an on-device machine learning model (TensorFlow Lite), generating a rarity score with zero cloud latency.
- **The Iring-dex**: A personal collection journal. Inspect documented cats, edit custom nicknames, record observations, and track breed completion milestones.
- **Crowdsourced Cat Map**: GPS-integrated interactive map displaying geolocated sighting pins submitted by community explorers to locate nearby cats.
- **Explorer Profiles & Leaderboards**: Track total distance walked, count unique species found, and compete on the local community leaderboard.

---

### Supported Platform

- **Android**: Android 14.0+ (API level 34+) (Target Platform)

---

<details>
<summary><b>Developer Quickstart & Local Setup</b></summary>
<br>

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.5`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.5.0`)
- Android Studio / Android SDK (API 34+)

### Setup and Execution

```bash
# Clone the repository
git clone https://github.com/Ractopen-Academic/Poke-Iring.git
cd Poke-Iring

# Fetch package dependencies
flutter pub get

# Run on your connected Android device or emulator
flutter run
```

### Static Analysis and Automated Tests

```bash
# Verify static analysis rules
flutter analyze

# Execute test suite
flutter test
```

</details>

---

<details>
<summary><b>Technical Architecture & Cloud Stack</b></summary>
<br>

```
+-------------------------------------------------------------+
|                         Poke: Iring                         |
|                    Flutter Android Client                   |
+------------------------------+------------------------------+
                               |
       +-----------------------+-----------------------+
       |                                               |
       v                                               v
[ On-Device Perception ]                     [ Cloud Services ]
+----------------------------+               +----------------------------+
| - Camera Hardware Overlay  |               | - Firebase Authentication  |
| - TensorFlow Lite Vision   |               | - Cloud Firestore (GeoDB)  |
| - Offline Inference Engine |               | - Cloud Storage (Photos)   |
+----------------------------+               +----------------------------+
```

### Repository Structure

```
pokeiring/
├── android/                 # Android native configuration and Gradle scripts
├── assets/                  # Application static assets (images and audio)
├── lib/
│   ├── core/                # Shared utilities, constants, theme, and network layer
│   ├── features/            # Domain-driven feature modules (data, domain, presentation)
│   ├── app.dart             # Root application widget and theme
│   └── main.dart            # Flutter application entrypoint
├── test/                    # Automated unit and widget test suites
├── analysis_options.yaml    # Dart and Flutter lint rules
├── LICENSE                  # MIT License
├── pubspec.yaml             # Package metadata and dependencies
└── README.md                # Project documentation
```

</details>

---

<details>
<summary><b>Development Team & Responsibilities</b></summary>
<br>

| Member | Role | Key Responsibilities |
| :--- | :--- | :--- |
| **Jehlia** | Project Manager & UI/UX | Map UI, camera overlay interface, and Iring-dex experience design |
| **Kent** | Lead Flutter Developer | Camera hardware pipeline and on-device TensorFlow Lite model integration |
| **Rob** | Flutter Developer | Geolocation services, permission handling, and coordinate mapping |
| **Royette** | Project Creator / Firebase & ML/QA | Cloud Storage, Firestore schemas, security rules, and ML model training |

</details>

---

<details>
<summary><b>Open Source Governance & Licensing</b></summary>
<br>

- **Contributing**: Please review our [CONTRIBUTING.md](CONTRIBUTING.md) guide and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before submitting pull requests.
- **Security**: For responsible vulnerability disclosure instructions, see [SECURITY.md](SECURITY.md).
- **License**: This project is licensed under the [MIT License](LICENSE).

</details>

# Global Eater Revival

An early revival of the original Global Eater iPhone food dictionary: **1,995 food entries**, the original artwork, and a new Flutter app built and running on a Pixel 9 Pro.

**[Visit the project page](https://mikevoyt.github.io/global-eater-revival/)** · **[Beginner setup guide](docs/BEGINNER_GUIDE.md)** · **[Build evidence](docs/BUILD_STATUS.md)**

This is a starting point for Mike and friends to collaborate, learn, and iterate toward something worth sharing more widely. The app is a development build, and its historical and draft definitions still need editorial review.

## What works today

- Offline browsing across 20 cuisines and two reference sections.
- Search with accent folding, aliases, and A–Z filtering.
- Food details, saved entries, and recent history.
- Original icon and splash artwork by Elliot Ling.
- Android ARM64 build, installation, and launch verified on a Pixel 9 Pro.

The catalog combines **1,815 recovered entries** with **180 draft additions**. Original definitions are marked `needs-review`; additions are marked `draft`. iOS project files and instructions are included, but an iOS build and iPhone run have **not** been verified.

## Quick start on a Mac

New to this? Start with the **[step-by-step beginner guide](docs/BEGINNER_GUIDE.md)**. It explains the tools, phone prompts, Android Studio, and separate iOS simulator/iPhone paths.

After installing Apple's Command Line Tools (`xcode-select --install`), open **Terminal** and paste:

```bash
mkdir -p "$HOME/Development"
cd "$HOME/Development"
git clone https://github.com/mikevoyt/global-eater-revival.git
cd global-eater-revival
bash SETUP_MAC.command --build-only
```

The Mac launcher can install missing tools, asks you to review Android SDK licenses, runs checks, and builds a **debug/development APK**. It uses this checkout and opens it in Android Studio. Flutter **3.44.8** is the tested version; the guide explains how to select it before setup. Do not run the launcher with `sudo`.

Connect an ARM64 Android phone, unlock it, enable USB debugging, and approve your Mac when prompted. Then, in the same project folder:

```bash
source scripts/mac-env.sh
bash scripts/android.sh --install-only
```

Expected result: `Global Eater installed and launched` and the app opens on the phone. The local APK is `dist/GlobalEater-0.1.0-android-arm64-debug.apk`. Existing app data is preserved when updating with the same signing key; the script never automatically uninstalls an app.

For iOS, first install Xcode and an iOS simulator runtime, then follow the **[iOS section](docs/BEGINNER_GUIDE.md#5-prepare-the-mac-for-ios)**. A simulator does not require paid Apple Developer enrollment. A physical iPhone adds signing, trust, and Developer Mode steps. No App Store or TestFlight release is provided.

## How it came back

Mike Voytovich and Harry Kwan created the original Global Eater. This revival brings its recovered catalog and Elliot Ling's artwork into a new Flutter implementation. Mike worked with **Codex and his dot, Klek**, to get the project built, tested, and running on a Pixel 9 Pro.

The project-page structure takes inspiration from Mike's **[Nexus Q Revival](https://github.com/mikevoyt/nexusq-revival)**. This is a personal project, with no implication of official OpenAI endorsement.

## Validation

Verified on the Mac and Pixel during the revival:

| Check | Result |
| --- | --- |
| Catalog validation | 1,995 entries; passed |
| Python tooling tests | 11 passed |
| Flutter analysis | No issues |
| Flutter unit/widget tests | 16 passed |
| Pixel integration test | 1 passed; catalog → search → Phở detail |
| Android build/install/launch | ARM64 debug APK; passed |
| iOS build/device run | Not yet tested |

The tested toolchain is Flutter 3.44.8 / Dart 3.12.2, Java 21, Gradle 9.1.0, and Android Gradle Plugin 9.0.1. See [build status](docs/BUILD_STATUS.md) and the [testing checklist](docs/TESTING.md) for the remaining manual checks. The GitHub Actions workflow repeats catalog, Python, and Flutter checks and builds an Android development APK from a clean checkout.

## What we can build next

Start by trying the app together and filing small, specific [issues](https://github.com/mikevoyt/global-eater-revival/issues): what you expected, what happened, and which screen or food entry was involved.

Possible next steps include reviewing the definitions and duplicate names, improving accessibility and search, testing iOS, and exploring a food passport or saved-list export. These are ideas to choose together, not promised features or deadlines. See the [roadmap](docs/ROADMAP.md).

## Credits and rights

Original app: **Mike Voytovich and Harry Kwan**. Original icon and splash illustration: **Elliot Ling**. Recovered materials and original asset hashes are documented in [provenance](docs/PROVENANCE.md).

Public source access does **not** establish a blanket license to reuse the historical catalog or artwork. Existing rights remain with their respective creators/rightsholders; see [RIGHTS.md](RIGHTS.md). Flutter and dependencies retain their own licenses. No production signing keys or store credentials are included.

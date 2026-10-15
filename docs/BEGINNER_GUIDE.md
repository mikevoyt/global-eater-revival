# Run Global Eater on your phone

You do not need to be a software developer to try this. Work through the common setup once, then choose **Android** or **iPhone**. Copy one command block at a time and let it finish before continuing.

This is an early revival to explore and improve together. The Android app has been built, installed, launched, and smoke-tested on a Pixel 9 Pro. **The iOS project is included, but has not yet been built or tested on a simulator or iPhone.** The iOS steps below are a documented starting point for that next test, not a promise that every Xcode/device combination already works.

| Your goal | Follow this path |
| --- | --- |
| Try it on an Android phone | [Common setup](#1-common-setup-on-a-mac), then [Android phone](#2-android-phone) |
| Try Android without a phone | Common setup, then [Android emulator](#4-android-without-a-phone) |
| Try iOS without signing into a developer account | Common setup, then [iOS simulator](#6-ios-simulator-first) |
| Try it on your own iPhone | Common setup, [Xcode setup](#5-prepare-the-mac-for-ios), then [physical iPhone](#7-your-own-iphone) |
| Something went wrong | [Troubleshooting](#9-short-troubleshooting) |

There is currently no published, ready-to-install APK release linked from this guide. The Android setup below produces a **debug/development APK** on your Mac. An APK is an Android app installation file; it cannot be installed on an iPhone.

## 1. Common setup on a Mac

### Before you start

Have a Mac with a supported macOS version, a reliable internet connection, free disk space for several large developer-tool downloads, and your Mac login password. Apple Silicon Macs are the easiest starting point. Android needs Android Studio; iOS needs the full Xcode app and a macOS version that can run it. These tools are free. You do not need a paid Apple developer membership for the simulator or ordinary personal-device testing.

Open **Terminal** using Spotlight: press **Command–Space**, type `Terminal`, and press Return. A *command* is an instruction pasted into Terminal. A *folder path* tells it where files live. `cd` means “change folder”; `$HOME` means your own home folder. *Clone* means download a working copy of the source and its Git history. A *build* turns that source into an app.

### Install Apple's command-line tools

Run this from any Terminal folder:

```bash
xcode-select --install
```

Finish the macOS installation dialog before continuing. If it says the tools are already installed, continue. These tools include Git. Full Xcode is not needed for the Android path. [Official Flutter installation instructions](https://docs.flutter.dev/install/manual)

Check that Git is available:

```bash
git --version
```

Expected: a version number, such as `git version …`.

### Download Global Eater

Run these commands in Terminal:

```bash
mkdir -p "$HOME/Development"
cd "$HOME/Development"
git clone --branch mikev/main https://github.com/mikevoyt/global-eater-revival.git
cd global-eater-revival
```

No GitHub account is required to download this public repository. If Terminal says the destination already exists, stop cloning and use the existing copy with `cd "$HOME/Development/global-eater-revival"`. Do not delete a folder to get past this message.

Check your location:

```bash
pwd
ls pubspec.yaml
```

Expected: a path ending in `/Development/global-eater-revival`, then `pubspec.yaml`. This is the **project folder**. Unless a step says otherwise, run later commands here.

### Install the tested Flutter version

Flutter is the toolkit that builds this app for both Android and iOS. The verified Android build used **Flutter 3.44.8 / Dart 3.12.2**. The following downloads that specific version from Flutter's official repository into a separate folder, leaving any other Flutter installation alone:

```bash
git clone --depth 1 --branch 3.44.8 https://github.com/flutter/flutter.git "$HOME/Development/flutter-global-eater"
export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"
flutter --version
```

The first Flutter command downloads additional tools. A Git message about “detached HEAD” is expected when selecting a version tag. The final output should report Flutter `3.44.8`. If the SDK folder already exists, skip the clone command and run the `export` and version commands. If the version differs, ask for help before replacing an existing SDK.

This `export` applies to the current Terminal window. In a new Terminal window, repeat:

```bash
export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"
cd "$HOME/Development/global-eater-revival"
```

The [official SDK archive](https://docs.flutter.dev/install/archive) also offers downloadable SDK bundles. Newer Flutter releases exist; this guide deliberately starts with the version used for this project's Android verification.

## 2. Android phone

### Connect and authorize your phone

For a Pixel, open **Settings → About phone → Build number** and tap Build number seven times. Enter your phone PIN if requested. Then open **Settings → System → Developer options** and enable **USB debugging**. Other Android brands may use slightly different names. [Android's developer-options instructions](https://developer.android.com/studio/debug/dev-options)

Connect the unlocked phone to your Mac with a **data-capable USB cable**. When the phone asks whether to allow USB debugging from this computer, review the prompt and allow your own Mac. This lets the Mac install and debug development apps. A bootloader unlock, rooting, and OEM unlocking are not required. macOS needs no separate Android USB driver. [Android's USB connection instructions](https://developer.android.com/studio/run/device)

### Let the project set up and build

From the project folder, run:

```bash
export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"
cd "$HOME/Development/global-eater-revival"
bash SETUP_MAC.command
```

**Do not put `sudo` before this command.** The launcher checks for Python 3.10+, Homebrew, Android Studio, and Android SDK tools. It installs missing dependencies, using Android Studio's bundled Java. Homebrew's installer may request your Mac password; Terminal does not display password characters while you type.

The launcher will pause for you to **read and decide whether to accept Android SDK license terms**. It does not automatically accept them. Watch both Terminal and your phone for prompts. The first build can spend a while downloading tools without opening the app.

The script then validates the catalog, analyzes the Flutter code, runs tests, builds an ARM64 debug APK, and installs it on one authorized ARM64 Android device. It opens the project in Android Studio. If more than one device is connected, it stops and asks you to choose one. Its update command preserves existing app data when the signing key matches; it never automatically uninstalls the app.

Expected final message: `Global Eater installed and launched on …`. Unlock the phone and look for **Global Eater**. You can then disconnect USB.

The generated app file is:

```text
dist/GlobalEater-0.1.0-android-arm64-debug.apk
```

This is a development build, not a Play Store release. The verified setup used Android Studio Otter 3 / 2025.2.3, bundled Java 21, Android SDK 36, Gradle 9.1.0, and Android Gradle Plugin 9.0.1. The tested phone was a Pixel 9 Pro running Android 17. The launcher installs SDK packages required by the selected Flutter SDK; Gradle may download additional matching build components.

If the APK built but the phone was not authorized, approve the phone prompt and run:

```bash
source scripts/mac-env.sh
bash scripts/android.sh --install-only
```

`mac-env.sh` is created by the setup launcher. It tells this Terminal where your installed tools are.

### Repeat a build later

Open Terminal and run:

```bash
cd "$HOME/Development/global-eater-revival"
source scripts/mac-env.sh
bash scripts/android.sh
```

To build the APK without installing it:

```bash
bash scripts/android.sh --build-only
```

## 3. Open and run in Android Studio

1. Launch Android Studio. Use **Settings → Plugins → Marketplace**, search for **Flutter**, install the Flutter plugin and its Dart dependency, then restart if asked.
2. Choose **Open**, then select `Development/global-eater-revival` in your home folder—the folder containing `pubspec.yaml`.
3. If asked for the Flutter SDK, use the full path printed by this Terminal command:

   ```bash
   echo "$HOME/Development/flutter-global-eater"
   ```

4. If Flutter support still needs configuring, check **Settings → Languages & Frameworks → Flutter**. The Dart SDK is inside that Flutter folder at `bin/cache/dart-sdk`.
5. Open `lib/main.dart`. Select your connected phone from the device selector, then press the green **Run** triangle. Wait for the build and check the phone.

Open the whole Flutter project for everyday work. The `android` subfolder alone is the native Android component. [Official Flutter Android Studio guide](https://docs.flutter.dev/tools/android-studio)

If Android Studio offers an Android Gradle Plugin upgrade while importing, leave the checked-in versions in place for this first run. First reproduce the working build; toolchain upgrades can be a separate collaboration step.

## 4. Android without a phone

An **emulator** is a virtual Android phone displayed on your Mac. From the project folder, set up and build without installing:

```bash
export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"
bash SETUP_MAC.command --build-only
source scripts/mac-env.sh
```

In Android Studio, open **Tools → Device Manager → Create Virtual Device**. Choose a phone and an Android system image suitable for your Mac: ARM64 for Apple Silicon, x86_64 for Intel. Download the image if needed, finish the wizard, and start the virtual phone with its play button. [Official Android emulator setup](https://docs.flutter.dev/platform-integration/android/setup)

Then run:

```bash
flutter devices
flutter run
```

If Flutter presents a list, type the number for the Android emulator. Expected: Global Eater opens inside the virtual phone. Use `flutter run` here so Flutter builds for that emulator's architecture; the project's packaged ARM64 APK is intended for ARM64 phones. The emulator path has not been independently validated for this revival.

## 5. Prepare the Mac for iOS

**iOS remains unverified in this project.** Start with the simulator before attempting a physical phone.

Install the full **Xcode** app from the Mac App Store, open it, and finish its first-launch setup. Use an Xcode release compatible with your Mac and intended iOS version. Command Line Tools alone are insufficient. Run the following individually from any Terminal folder. These commands select `/Applications/Xcode.app`, display Apple's license for your decision, initialize tools, and download iOS support:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license
sudo xcodebuild -runFirstLaunch
xcodebuild -downloadPlatform iOS
```

Review the license text yourself. `sudo` requests your Mac password for these Xcode setup operations. If Xcode is installed somewhere else, use its actual location instead. [Official Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup)

### Python, if you skipped Android setup

The project's branding/setup tool needs Python 3.10 or later. Check:

```bash
python3 --version
```

If Python is missing or older, install Homebrew using its [official installer](https://brew.sh/) if you do not already have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Read the installer's prompts. Then make Homebrew available in this Terminal and install Python:

```bash
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
brew install python
python3 --version
```

### Prepare this project

Return to the project folder and run:

```bash
cd "$HOME/Development/global-eater-revival"
export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"
bash scripts/bootstrap.sh
flutter pub get
flutter precache --ios
flutter doctor -v
```

Expected: the bootstrap step says `Native hosts ready`; dependency downloads finish; `flutter doctor` recognizes Xcode. Android or web-tool warnings do not by themselves block an iOS-only run. Resolve Xcode/iOS errors before continuing.

The checked-in iOS project uses **Swift Package Manager**, which Flutter 3.44 enables by default. There is no `scripts/ios.sh` or checked-in `ios/Podfile`. Do not run a random `pod install` command. If Flutter reports that a dependency needs CocoaPods, install it with `brew install cocoapods`, then repeat the Flutter command. [Flutter package-manager guidance](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers), [Homebrew CocoaPods package](https://formulae.brew.sh/formula/cocoapods)

## 6. iOS simulator first

A **simulator** is a virtual iPhone on your Mac. It does not need your own Apple signing team. In Xcode, use **Xcode → Open Developer Tool** to open **Simulator** (or **Device Hub** on Xcode 27). For Xcode 26 and earlier, the Terminal equivalent is:

```bash
open -a Simulator
```

For Xcode 27, use:

```bash
open -a DeviceHub
```

Start an iPhone simulator from its device menu. Then, from the project folder:

```bash
flutter devices
flutter run
```

If Flutter asks you to choose, enter the number for the iOS simulator. Expected, if the unverified iOS build succeeds: the app opens in the simulated iPhone. While `flutter run` is active, press `q` to stop the run. The simulator launch commands follow the [current Flutter iOS setup guide](https://docs.flutter.dev/platform-integration/ios/setup).

To compile a simulator app without launching it:

```bash
flutter build ios --simulator --debug
```

Expected build output: `build/ios/iphonesimulator/Runner.app`. That simulator app is not an iPhone-installable file.

## 7. Your own iPhone

**Signing** identifies the developer allowed to run an app on an Apple device. For personal testing, a free Apple Account can provide an Xcode **Personal Team**. Apple currently limits this to 10 App IDs, 3 registered devices, and 3 installed apps per device. Provisioning expires after 7 days, so expect to rebuild and reinstall periodically. App Store/TestFlight distribution requires a different distribution setup and developer-program membership; this guide does not enroll you or ask you to pay. [Apple's account and Personal Team rules](https://developer.apple.com/help/account/basics/about-your-developer-account)

1. Connect your unlocked iPhone by USB. Review and accept **Trust This Computer** for your own Mac.
2. On the phone, enable **Settings → Privacy & Security → Developer Mode**, then follow the restart and confirmation prompts. If the setting is missing, connect the phone to Xcode first. [Official iOS device setup](https://docs.flutter.dev/platform-integration/ios/setup)
3. In Xcode, open **Settings → Accounts** (the Apple Accounts label may vary by version) and sign in to your own Apple Account. Choose your Personal Team for this local experiment; do not select someone else's organization or replace existing signing identities.
4. From the project folder, prepare generated Flutter configuration and open the workspace:

   ```bash
   flutter build ios --config-only --debug --no-codesign
   open ios/Runner.xcworkspace
   ```

   This prepares files; it is not a completed app build. Open the `.xcworkspace` file, not a newly created Xcode project.

5. In Xcode's left sidebar select **Runner**, then under **TARGETS** choose **Runner**. In **Signing & Capabilities**, enable **Automatically manage signing** and select your own **Personal Team**.
6. If Xcode says the bundle identifier `com.bayapps.globaleater` cannot be registered to your team, set a unique identifier for **your local test copy**, for example `com.youruniquename.globaleater.dev`, replacing `youruniquename`. This identifies a separate local app; keep personal team/identifier edits out of shared commits.
7. Choose the **Runner** scheme and your connected **iPhone** in the top device selector. Press **Run**. Xcode may download device support or request access to your own development key; review those prompts.

The workspace, Runner target, automatic signing, and Team settings follow [Flutter's Xcode project instructions](https://docs.flutter.dev/deployment/ios#review-xcode-project-settings).

If the phone reports an untrusted developer, open **Settings → General → VPN & Device Management**, select your own developer entry, and review its trust prompt. Then retry Run. These changes are performed by you on your own device; do not revoke certificates or delete profiles to get past an unfamiliar error.

Once Xcode has completed signing setup, later runs can use Terminal from the project folder:

```bash
flutter devices
flutter run
```

Select the iPhone if prompted. Expected, after a successful build: Global Eater opens on it. A debug iOS app may need launching through Xcode or Flutter again after it has been stopped. Do not treat this as a standalone, distributable iPhone release.

## 8. Try it, then improve it together

Start with a small demo: browse the catalog, search `pho`, open **Phở**, and save an entry. Relaunch and see whether saved items behave as expected on your device. The catalog contains 1,995 entries, including 180 drafts that still need editorial review. Tell us what felt useful, confusing, or missing.

Good next experiments include testing the iOS path, reviewing a favorite cuisine's definitions, improving accessibility, and making saved entries easier to manage. This is a starting point for collaboration, not a finished product or a commitment to a release date. See the [roadmap](ROADMAP.md) and [testing checklist](TESTING.md).

To get future changes, first check for local edits:

```bash
cd "$HOME/Development/global-eater-revival"
git status --short
```

If that prints nothing, update safely:

```bash
git pull --ff-only
flutter pub get
```

If it lists files, keep your edits and ask for help combining them with the update. Do not discard changes just to make the command succeed. Rebuild afterward using the Android script or your iOS run path.

## 9. Short troubleshooting

| What you see | What to do |
| --- | --- |
| `No such file or directory` for a project script | Run `cd "$HOME/Development/global-eater-revival"`, then `ls pubspec.yaml`. You should be in the folder containing that file. |
| `flutter: command not found` or an unexpected Flutter version | Run `export PATH="$HOME/Development/flutter-global-eater/bin:$PATH"`, then `flutter --version`. |
| Android SDK licenses missing | After Android setup, run `source scripts/mac-env.sh`, then `flutter doctor --android-licenses`. Read and decide on each required license yourself. |
| Android SDK tools missing | In Android Studio use **Tools → SDK Manager**. Confirm SDK Platform 36 and the SDK Command-line Tools / Platform-Tools are installed; rerun the setup launcher for the project's exact build dependencies. |
| `adb devices` shows `unauthorized` | Unlock the phone and approve its USB debugging prompt for this Mac. Reconnect the cable if the prompt did not appear. |
| No Android device appears | Try a data-capable cable/another port, keep the phone unlocked, and use Android Studio **Tools → Troubleshoot Device Connections**. |
| More than one Android device | Disconnect the other device or stop its emulator, then rerun `bash scripts/android.sh --install-only`. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | An installed copy uses another signing key. Ask for the matching build/key. Uninstalling can erase saved items; the script deliberately does not do it for you. |
| Android Studio has no Flutter Run button | Install Flutter and Dart plugins, set the Flutter SDK path, open the project root and `lib/main.dart`, and select a running device. |
| Xcode missing or command-line tools selected | Install/open full Xcode and repeat the Xcode selection and setup steps above. |
| No iOS simulator appears | Finish the iOS runtime download in Xcode, start an iPhone simulator, then run `flutter devices` again. |
| Missing `Generated.xcconfig` or `FlutterGeneratedPluginSwiftPackage` | From the project root run `flutter pub get`, then `flutter build ios --config-only --debug --no-codesign`; reopen `ios/Runner.xcworkspace`. |
| iPhone signing fails or app expires | Review your Personal Team, unique local bundle identifier, device trust, and Developer Mode. Rebuild after the 7-day provisioning expiry. Do not delete unrelated signing certificates. |
| A new toolchain or package error remains | Save the first actual error and tool versions, then ask for help. iOS and tool versions newer than the verified Android setup may need adjustments. |

Android logs are in `dist/mac-setup.log` and `dist/android-build.log`. `flutter doctor -v` helps identify missing tools. Before sharing logs in a public issue, remove usernames, home-folder paths, phone serial numbers, account details, and unrelated device output. Share the short relevant error, what command you ran, and the OS/Flutter versions.

Instructions checked against the repository scripts and official documentation on **2026-10-15**. Menu names and newest tool versions may change. Original catalog and artwork attribution and rights are preserved in [RIGHTS.md](../RIGHTS.md) and [PROVENANCE.md](PROVENANCE.md); public source access does not create a new blanket license.

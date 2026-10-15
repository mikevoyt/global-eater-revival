# Mac setup

For a fresh Mac and step-by-step Android/iOS instructions, use the **[beginner guide](BEGINNER_GUIDE.md)**.

From the cloned project folder:

```bash
bash SETUP_MAC.command --build-only
source scripts/mac-env.sh
```

The launcher uses the current checkout by default, validates it before making changes, installs missing tools when needed, and leaves SDK license acceptance interactive. It does not replace existing source or automatically uninstall the app. Do not use `sudo` to run it.

It writes the machine's tool paths to ignored `scripts/mac-env.sh`. Source that file in each new Terminal window before running Android commands. No shell startup file is changed.

After connecting and authorizing one ARM64 Android phone:

```bash
bash scripts/android.sh --install-only
```

To run validation, build, install, and launch together:

```bash
bash scripts/android.sh
```

The project opens in Android Studio after the Mac launcher runs. Install the Flutter plugin (including its Dart dependency), open the project root containing `pubspec.yaml`, and select the Flutter SDK shown by the launcher.

Logs and the development APK live under `dist/`. That folder contains local machine/device information and must remain untracked. See [build status](BUILD_STATUS.md) for the tested toolchain and [testing](TESTING.md) for manual checks still to complete.

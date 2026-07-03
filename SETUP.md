# SETUP — Getting VIGIL Running (Phase 0 Walkthrough)

These are the manual steps that have to happen on **your computer**. Everything in the repo is
ready; this walks you from zero to "the game runs on my phone."

> **Part 0 — zero-install testing:** every push auto-deploys a browser build to
> **https://brookskemory-ops.github.io/game/** — open that on any device to test instantly.
> The steps below are for the real dev loop (editor + native phone builds).

**Phase 0 is done when:** you can change one line, re-deploy, and see it on your phone in
under 5 minutes.

---

## Part 1 — Run it on your computer (~15 minutes)

### 1. Install Godot 4

1. Go to **https://godotengine.org/download**
2. Download **Godot 4.4 or newer** — the **standard** version (NOT the ".NET" version).
3. It's a single executable, no installer: unzip it and put it somewhere permanent
   (e.g. `C:\Godot\` on Windows or `/Applications` on Mac).

### 2. Get this repository onto your computer

Easiest path if you don't use git yet: install **GitHub Desktop** (https://desktop.github.com),
sign in, *Clone repository* → `brookskemory-ops/game` → make sure you're on the branch
`claude/narrative-roguelike-medieval-design-34nvrc`.

(Or with git: `git clone` the repo and `git checkout claude/narrative-roguelike-medieval-design-34nvrc`.)

### 3. Open the project

1. Launch Godot → **Import** → browse to the repo folder → select `project.godot` → **Import & Edit**.
2. First open takes a moment (Godot builds its import cache — this creates a `.godot/` folder,
   which is intentionally not committed).
3. Press **F5** (or the ▶ button, top right).

### ✅ What you should see

- A night scene: moon, stars, Castle Vane with one lit window, drifting fog — and
  **VIGIL / hold the night**, with a pulsing **TAP TO BEGIN**.
- Click anywhere → the graveyard arena. Wren (a little hooded archer) stands center;
  the dead start closing in and his bow fires by itself at the nearest one.
- **Arrow keys** move; or **click-and-drag** anywhere and a floating joystick ring
  appears under your cursor (this is exactly what a thumb will do on the phone).
- Kill shamblers → collect the blue gems → level up (the bow gets stronger). Survive
  the 5:00 night or die trying — either way you get a results screen.
- **Esc** opens the pause menu; the **II** button does the same on touch.

If instead you get a red error, copy its exact text and paste it to me — I'll fix it.

> Note: on first open Godot generates `.uid` files next to the scripts. That's normal —
> commit them along with your next change.

---

## Part 2 — Run it on your Android phone (~45–60 minutes, one-time setup)

Do this once; afterwards deploying is one click.

### 1. Install export templates (in Godot)

**Editor → Manage Export Templates… → Download and Install.**

### 2. Install Java (JDK 17)

Download **Temurin JDK 17** from https://adoptium.net → install with defaults.

### 3. Install the Android SDK

Simplest reliable route: install **Android Studio** (https://developer.android.com/studio),
open it once, and let its setup wizard install the SDK. You'll never need to open it again —
Godot just uses the SDK it installed.

Default SDK locations:
- **Windows:** `C:\Users\<you>\AppData\Local\Android\Sdk`
- **macOS:** `~/Library/Android/sdk`
- **Linux:** `~/Android/Sdk`

### 4. Point Godot at them

**Editor → Editor Settings → Export → Android:**
- **Java SDK Path** → your JDK 17 folder
- **Android SDK Path** → the SDK folder above

### 5. Create a debug keystore (one command)

Open a terminal and run (adjust the output path to taste; remember it):

```
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
  -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" \
  -validity 9999
```

Then in the same Editor Settings screen set **Debug Keystore** to that file,
user `androiddebugkey`, password `android`.

### 6. Prepare your phone

1. **Settings → About phone → tap "Build number" 7 times** (unlocks Developer options).
2. **Settings → Developer options → enable "USB debugging".**
3. Plug the phone into the computer; accept the "Allow USB debugging?" prompt on the phone.

### 7. Add the Android export preset (in Godot)

**Project → Export… → Add… → Android.** Defaults are fine for now. If anything is missing,
this dialog shows a yellow/red message telling you exactly which step above it wants.

### 8. Deploy 🚀

With the phone plugged in, an **Android icon appears in the editor's top-right toolbar**.
Click it. Godot builds the APK, installs it, and launches it on your phone. Drag your thumb —
the joystick should feel immediate.

### Troubleshooting

| Symptom | Fix |
|---|---|
| "Export templates missing" | Part 2, step 1 |
| "Invalid Java SDK path" / wrong Java version | Use JDK **17** specifically (step 2), re-set the path (step 4) |
| "Unable to find Android SDK" | Re-check the SDK path (steps 3–4) |
| "Debug keystore not configured" | Step 5 |
| Phone never shows the USB prompt | Try another cable/port (must be a data cable); toggle USB mode to "File transfer" |
| Android toolbar icon doesn't appear | Phone not authorized — redo step 6; on Windows you may need your phone vendor's USB driver |
| Installs but shows a black screen | Copy `adb logcat` output or just tell me the phone model — I'll debug |

### iOS (later)

iOS export needs a Mac + Apple Developer account ($99/yr) and is deliberately deferred to
Phase 6 (see `DEVELOPMENT_PLAN.md`). Android is our dev loop.

---

## Part 3 — Daily workflow after setup

1. Pull the latest branch (I push changes here).
2. Open Godot → F5 to sanity-check on desktop.
3. Phone plugged in → click the Android toolbar icon → test on device.
4. Anything odd? Paste me the error/describe it and I fix it next session.

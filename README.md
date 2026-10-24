# WordCraft — Android/Web only (trimmed)

This is a trimmed copy of WordCraft (<https://github.com/storytold/wordcraft>, MIT OR
Apache-2.0) containing **only** what `apps/wordcraft-web` (and, through it, the Android app in
`apps/wordcraft-android`) needs to build. Removed, on purpose: the desktop app, the CLI, the MCP
server, the desktop TCP control channel, `xtask`, and all non-web packaging — none of those are
on the dependency path of the web/Android build (verified by grepping every kept `Cargo.toml`).

Kept crates: `geom, doc, fonts, layout, docx, docbin, formats, render, pdf, proof, metafile,
zotero, engine, ui-egui` — exactly the transitive dependency set of `wordcraft-ui-egui`, which
`apps/wordcraft-web` runs.

## Build

```sh
# 1. Build the WASM web app
cd apps/wordcraft-web
trunk build --release        # output: dist/web (relative to repo root)

# 2. Sync into the Android (Capacitor) shell and build the APK
cd ../wordcraft-android
npm install
npm run android:sync         # cap sync android
npm run android:apk          # ./gradlew assembleDebug  (output under android/app/build/outputs/apk)
```

You need: Rust with `wasm32-unknown-unknown`, [`trunk`](https://trunkrs.dev), Node.js, and an
Android SDK (API 34) + JDK 17 for Gradle.

## Fixes applied versus the upstream file set

- **Missing `colors.xml` (real build breaker).** `android/app/src/main/res/values/styles.xml`
  references `@color/colorPrimary`, `colorPrimaryDark`, `colorAccent`, but no `colors.xml` shipped
  them — `./gradlew assembleDebug` would fail with "resource color/colorPrimary not found". Added
  `android/app/src/main/res/values/colors.xml` with neutral placeholder colours; swap in your own
  brand colours whenever you have them.
- **`minSdkVersion` 22 → 26.** Android 5.1 is a negligible share by 2026 and ships a WebView too old
  for reliable WebGL2 (the `eframe`/`wgpu` fallback path this app depends on); 26 (Android 8) is a
  safer modern floor.
- **Release build wasn't shrunk.** `minifyEnabled` was `false` and resources weren't shrunk, so
  release APKs were needlessly large. Turned on `minifyEnabled true` + `shrinkResources true`, and
  added the R8/ProGuard keep rules Capacitor needs (its plugins — Filesystem, Preferences, Share —
  are found by reflection, which R8 can't see from the call graph; without explicit `-keep` rules
  they'd be stripped or renamed and the JS-to-native bridge calls would silently fail at runtime).
- **Keyboard could cover the canvas on some devices.** `android:windowSoftInputMode` was left
  unset (OEM-dependent default). Set it explicitly to `adjustResize` so the activity's window
  actually shrinks for the keyboard, matching the `100dvh` / `interactive-widget=resizes-content`
  behaviour `index.html` already assumes.
- **Leftover template package name.** The test sources under `android/app/src/test` and
  `androidTest` were still in `com.getcapacitor.myapp` and the instrumented test asserted the
  package name was `com.getcapacitor.app` — both stale from the original Capacitor scaffold and
  inconsistent with the real `applicationId`, `com.wordcraft.app`. Moved the files to
  `com.wordcraft.app` and fixed the assertion (it would have failed otherwise).

## Still worth doing (not mechanical — real engine/UX work, left for you to scope)

- **Touch text selection handles.** egui has no Android-style drag handles for adjusting a
  selection; editing by touch currently relies on drag-select only.
  `crates/ui-egui/src/canvas.rs` is where this would live.
- **Long-press context menu** (copy/paste/format) as an alternative to keyboard shortcuts, since
  there's no physical keyboard on most Android devices.
- **Back-button handling**: `MainActivity` is still the stock
  `class MainActivity extends BridgeActivity {}`; Capacitor's default back-button behaviour (exit
  or WebView-back) doesn't know about unsaved WordCraft documents. Hooking into the `App` Capacitor
  plugin's `backButton` listener and WordCraft's own `recovery.md`/autosave logic would need
  wiring on both the Rust (`web.rs`) and Android side.
- **Custom launcher icon / splash** — still the generic Capacitor-template assets under
  `res/mipmap-*` and `res/drawable*/splash.png`.

## Crediting yourself

See `contributors/contributors_gen.py` — it reads **this repo's own `git log`** (once you've
committed to your fork under your own `git config user.name`) and writes
`contributors/contributors.json` in the schema `crates/ui-egui/build.rs` expects for the in-app
About window. It will not invent a name for you; only commits that actually exist get listed.
After generating it, add your display name to `contributors/people.toml` (see that file's header)
and flip your entry's `"people_entry"` to `true` in `contributors.json`.

Per the MIT/Apache-2.0 licence this is built on, keep `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE`
and `ATTRIBUTION.md` in place — they record the original project's copyright and the licences of
every bundled asset (fonts, hyphenation dictionaries, etc.). Crediting yourself for your own
Android port and Arabic-localization work is fine and encouraged; presenting the ~240k-line engine
underneath as entirely your own original work would not be accurate.

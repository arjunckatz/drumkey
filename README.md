# DrumKey

DrumKey is a macOS menu bar app that turns D, F, J, K, L and Space into an ambient rhythm display. A vertical 192 × 252 point glass overlay starts in the top-left of a secondary display, or the main display when only one is connected. Click and drag anywhere on it to move it. Its circular soundstage is 167.2 points across, 10% wider than the previous stage.

## Build and launch

Requires macOS 15 or newer. Building requires Xcode 26 or newer with its command line tools selected.

```sh
bash scripts/build-app.sh
open build/DrumKey.app
```

Quit DrumKey before rebuilding its app bundle. The script creates an optimized, locally signed app with the identifier `local.drumkey.app`, built for the current Mac’s architecture.

Local ad-hoc signing identifies the exact binary by its content hash. After a rebuild, an existing Input Monitoring entry can remain switched on while access to the new binary is denied. Remove the old DrumKey entry, add `build/DrumKey.app` again, enable it, and quit and reopen DrumKey.

For permission identity that survives updates, supply an existing code-signing certificate with `DRUMKEY_SIGNING_IDENTITY`. The script uses the local ad-hoc fallback when this variable is unset. Developer ID signing and notarization are required for public distribution. [Apple’s code identity documentation](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)

For development, use `swift run DrumKey`. Permission may be associated with the launching terminal or editor when running an unbundled executable.

## First launch

Settings opens on first launch. Click **Allow Input Monitoring**, then allow DrumKey in **System Settings → Privacy & Security → Input Monitoring**. macOS may ask you to quit and reopen the app after granting access.

The menu bar waveform opens the DrumKey menu. **Settings…** opens the settings window again. Close Settings to continue working with the overlay visible.
Command–W closes Settings and leaves the overlay running.

- **Enable DrumKey** starts the listener and displays the HUD. Disable it to pause both.
- **Control + Option + Command + D** toggles DrumKey globally when that shortcut is available.
- **Display** selects an available monitor or automatic secondary-display preference.
- **Visibility** adjusts the faint overlay while retaining a visible minimum.
- **EQ transparency** adjusts the background spectrum separately, starting at 92% transparent. Higher values make it fainter; 100% hides it. The preference survives a restart.
- **Preview a rhythm** runs a short visual example through the same soundstage and analyzer. A real tap takes over when capture is enabled.
- **Reset rhythm** clears the current tempo and meter.
- **Retry keyboard listener** recreates capture immediately without changing permission settings.
- **Quit DrumKey** removes the overlay and stops the listener.

A selected display is remembered across app launches. If it disconnects, DrumKey temporarily selects another available display. It automatically returns when the chosen display reconnects.

Drag the overlay by its text, glass background or soundstage. Its position is remembered separately on each display and adjusts when the screen resolution changes. Dropping it on another monitor selects that display. The panel stays within the usable screen area when released and keeps keyboard focus in your working app.

## Visual feedback

| Input | Visual region | Analysis role |
| --- | --- | --- |
| D / F | Indigo upper-left and blue lower-left bass groups | Hit timing and recurring key patterns |
| D + F together | Blue-violet flash around the overlay border | Visual recognition of a joint bass hit |
| J / K | Orange upper-right and pink lower-right percussion groups | Hit timing and recurring key patterns |
| Space | Mint light around the complete rim | Explicit accent or downbeat hint |
| L | Four teal accent bars between color groups | Manual visual accent, outside rhythm analysis |

Sixteen translucent glass columns sit around an open circular center. D/F occupy the left side and J/K occupy the right. Each three-bar color group has a narrower teal accent bar beside it, with the four accent bars at the top, left, bottom and right. The glass projection remains mirrored horizontally. Block centers and circular flashes share one origin, accounting for the height and depth of the projected glass.

Hits have an immediate 12 point lift and up to seven points of extra height, returning within the existing 360 ms response. Layered ripples spread around each struck group and across the center of the stage. Reduce Motion uses brightness feedback. The instrument-like regions express the tapping pattern, and key identity alone provides limited information about musical intent.

Bass columns are 35% wider at rest and gain another 20% width during a hit. Stronger glass faces, thicker highlights and bolder ripples give their travel more weight.

Press D and F together to flash the rounded border of the entire overlay. Presses within 80 milliseconds count as a pair. Each pair produces a single flare that fades within 360 milliseconds; holding the keys does not continue flashing. Reduce Motion uses a gentler border pulse. The rhythm preview includes joint bass hits so the effect can be checked from Settings.

Press L to trigger all four teal bars together manually. Their former beat automation has been removed. L remains outside tempo and meter analysis.

A faint EQ theme stretches across the entire overlay behind the circle and text. Forty thin stems follow the same D, F, J, K, L and Space hits: bass emphasizes the left, percussion the right, L the high bands and Space the full spectrum. Green rises through yellow and orange to red near the top of the overlay; strong combined or repeated hits occasionally reach those red peaks. The spectrum describes key-driven visual energy rather than measured audio frequencies.

The EQ defaults to 92% transparency and its own Settings slider changes it immediately. Energy fades over 950 milliseconds, leaving a faint static pattern when tapping stops. Reduce Motion uses stationary stems with brightness feedback. The circle, bass border flash and background EQ respond together.

The HUD remains visible while enabled. It uses native Liquid Glass on macOS 26 and newer, with a system visual-effect material on macOS 15. Appearance and transparency follow the system material, and text uses adaptive macOS colors.

## Rhythm analysis

A few steady taps can establish an estimated BPM early. Uneven tapping produces an averaged estimate after about 10–15 seconds instead of staying on Finding pulse. The detector averages a rolling 12 seconds, normalizes subdivisions and missed beats, trims isolated timing slips, and allows 20% timing variation. An approximate symbol marks BPM below 0.70 confidence. Brief uncertainty preserves the previous BPM.

Near-simultaneous keys are grouped into one onset for tempo, while each key still produces its own feedback. Auto-repeat and mapped keys held with Command, Control or Option are ignored.

The meter is visible immediately as a tentative `≈4/4` baseline. Repeated Space accents and recurring key patterns refine the current three- or four-beat hypothesis. The approximate symbol marks uncertain estimates and disappears when support becomes strong. Small dots show the bar position when an accent supplies an anchor.

The analyzer retains up to three minutes or 2,048 hits. Continued tapping strengthens or revises the current meter, with recent patterns gradually outweighing older evidence. Brief pauses preserve the learned pattern. Thirty seconds without a hit resets to the provisional 4/4 baseline while keeping the HUD visible. Pausing, sleeping and changing sessions reset the current rhythm.

The estimator has a 60–200 BPM preference. Tap subdivisions can produce half- or double-time ambiguity, and sparse, irregular, syncopated or changing patterns can remain uncertain. A displayed average describes the tapped pattern and can differ from the song’s tempo. The current meter candidates are 3/4 and 4/4. Inferring 6/8 or other signatures needs further analysis and musical context.

## Capture and platform behavior

All keys retain their normal behavior in the active app. Letters may type into text fields, and Space may scroll or control media. Hit timing comes from the operating system’s event timestamps.

Input Monitoring permission is required for live feedback. Settings and the HUD show missing access, listener failures and secure input. The app verifies the event tap’s enabled and valid state, reenables disabled listeners, and replaces invalid listeners. It attempts passive capture even when the preliminary permission check disagrees with the actual event-tap result. Failed creation is retried at five-second intervals, and Settings provides an immediate retry.

If Input Monitoring is already on but Settings reports missing access, remove the stale entry and re-add the current app bundle, then quit and reopen DrumKey. A secure input session, such as a protected password field, can temporarily prevent keyboard capture. Recovery messages are written to the local system log under `local.drumkey.app`, category `KeyboardCapture`. These log messages describe listener state and omit key identities and typed text.

The listener retains only the mapped hit identities and timestamps in a bounded in-memory history. Preferences store enabled state, visibility, EQ transparency, the chosen display and per-display overlay positions. DrumKey operates locally.

The overlay accepts mouse clicks for dragging, avoids keyboard focus, joins desktop Spaces, and restores its placement when screens change. Some exclusive full-screen applications or protected system surfaces can cover it. The fixed bindings use physical Mac key positions corresponding to ANSI D, F, J, K, L and Space.

DrumKey is permanently silent. MIDI is deferred from the current scope.

## Source and verification

- `Sources/DrumKeyCore` holds the timestamped hit types, rhythm analyzer and display selection policy.
- `Sources/DrumKey` holds the menu bar lifecycle, passive event tap, settings, display discovery, background EQ and glass soundstage.
- `Packaging` and `scripts/build-app.sh` produce the launchable macOS bundle.
- `Tests/DrumKeyCoreTests` covers rhythm analysis, tolerant tempo averaging, tempo changes and boundaries, manual accent isolation, missed beats, idle reset and display fallback/restoration.
- `Tests/DrumKeyAppTests` covers capture recovery, L-key mapping, joint bass recognition and delayed event delivery, EQ peaks and decay, saved EQ transparency, four accent slots, centered projection, clearance during the higher rise, and saved placement across displays and resolution changes.

```sh
swift test
```

The app is built with Swift 6 concurrency checking. Desktop checks covered Settings, preview, pausing and display selection on macOS 27.2.1 with a secondary monitor. Live verification requires permission for the current build. Older-system rendering and physical monitor hot-plug behavior need hardware verification.

The product record lives in [DECISIONS.md](DECISIONS.md). Future candidates include launch at login and more meter models.

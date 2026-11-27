# DrumKey

DrumKey is a macOS menu bar app that turns D, F, J, K, L and Space into an ambient rhythm display. A vertical glass overlay starts at 192 × 252 points in the top-left of a secondary display, or the main display when only one is connected. Click and drag anywhere on it to move it. Size presets enlarge the panel and circle while keeping the meter and BPM text the same size.

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
- **Visual theme** switches live among eleven layouts, including Glass Circle, Circle Towers, Pulse Halo, Radial Spectrum, Orbit Shards, Razor Bloom, Linear EQ, Mirror Wave, LED Matrix, Silk Ribbons and Hex Array.
- **Color scheme** independently selects from fifteen palettes. New options are Ultraviolet, Cyberpunk, Acid, Glacier, Rose Quartz, Copper, Jade and Monochrome. Theme and color choices are remembered.
- **Display** selects an available monitor or automatic secondary-display preference.
- **Overlay size** selects 1×, 1.5×, 2× or 3×. The panel fits inside the chosen display and remembers the size. Meter text stays at 22 points and BPM/status stays at 11 points.
- **Visibility** adjusts the faint overlay while retaining a visible minimum.
- **EQ transparency** adjusts the background spectrum separately, starting at 92% transparent. Higher values make it fainter; 100% hides it. The preference survives a restart.
- **Preview a rhythm** runs a short visual example through the same soundstage and analyzer. A real tap takes over when capture is enabled.
- **Reset rhythm** clears the current tempo and meter.
- **Retry keyboard listener** recreates capture immediately without changing permission settings.
- **Quit DrumKey** removes the overlay and stops the listener.

A selected display is remembered across app launches. If it disconnects, DrumKey temporarily selects another available display. It automatically returns when the chosen display reconnects.

Drag the overlay by its text, glass background or soundstage. Its position is remembered separately on each display and adjusts when the screen resolution changes. Dropping it on another monitor selects that display. The panel stays within the usable screen area when released and keeps keyboard focus in your working app.

## Visual feedback

The following regions describe Glass Circle with Classic colors. Other layouts preserve the key roles with their own shapes and selected palette.

| Input | Visual region | Analysis role |
| --- | --- | --- |
| D / F | Six alternating indigo and blue columns on the left | Hit timing and recurring key patterns |
| D + F together | Deep gunmetal blue flash around the overlay border | Visual recognition of a joint bass hit |
| J / K | Six alternating orange and pink columns on the right, plus left/right border meters | Hit timing and recurring key patterns |
| Space | D and F together, plus the rim accent and joint-bass border flash | One explicit downbeat/accent onset |
| L | Four wider teal accent columns at north, south, east and west | Manual visual accent, outside rhythm analysis |

Sixteen translucent glass columns sit around an open circular center. The left side alternates D, F, D, F, D, F from top to bottom; the right alternates J, K, J, K, J, K. Four wider L accents sit at the cardinal points. The glass projection remains mirrored horizontally, and projected columns and rims share one center at every size.

Column bases stay fixed. A hit immediately extends the top, which gradually falls toward its resting height. Each new hit adds to the remaining height instead of starting another jump. Key energy is capped, with up to 24 points of extension at 1× and a 0.70-second exponential release. The height scales with the circle. Spreading ripples have been removed, and Reduce Motion uses brightness feedback with stationary columns. The instrument-like regions express the tapping pattern, and key identity alone provides limited information about musical intent.

Bass columns are 35% wider, with stronger glass faces and thicker highlights. Their width stays fixed during a hit. The four L accents are 19 points wide at 1×.

Ten additional layouts share this same additive key energy. Circle Towers adds eighteen projected pillars with front D/F bass banks, rear J/K banks and two L side beacons. Razor Bloom adds pointed crystal blades, Silk Ribbons five flowing glass bands, and Hex Array nineteen faceted cells. The layout and color pickers update the overlay without resetting its current animation. [THEMES.md](THEMES.md) describes all eleven themes, fifteen palettes, mappings and research references.

The radial alternatives use amplified travel and pointed ends: Pulse Halo has sharp crests, Radial Spectrum tapered spears, Orbit Shards pointed glass kites, and Razor Bloom faceted blades. They retain the same gradual fall and additive retriggers as Glass Circle. Their peaks fit below the fixed text and inside the panel at each size.

Their new key regions give D broad side jaws, F four diagonal horns, J the upper crown, K the lower crown and L a fine twelve-tooth rim. Space triggers both bass regions together. See [the radial mapping analysis](THEMES.md#radial-key-composition) for the current assignments and design rationale.

Linear EQ and LED Matrix always put D/F on the left, with taller peaks than J/K/L on the right. Linear EQ uses solid banks and a 107-point bass ceiling versus 67 points for percussion at 1×. LED Matrix uses paired bass clusters with sixteen rows versus ten on the right. Space drives both bass banks. The background EQ follows the same left/right placement and lower percussion ceiling.

Press D and F together to flash the rounded border in deep gunmetal blue. Presses within 80 milliseconds count as a pair. Each pair produces a single flare that fades within 360 milliseconds; holding the keys does not continue flashing. Reduce Motion uses a gentler border pulse. The rhythm preview includes joint bass hits so the effect can be checked from Settings.

J raises a segmented meter on the left border and K raises one on the right, alongside their circle feedback. A single tap starts at 8% of the panel height. Repeated taps build the peak over a rolling 30 seconds; roughly two taps per second on a key for thirty seconds earns the maximum 60% height. Short bursts cannot skip the buildup, and each rise releases within 220 milliseconds. A gap over three seconds restarts that lane's buildup. Reduce Motion uses fixed-height tracks with brightness feedback.

Press L to trigger all four teal bars together manually. Their former beat automation has been removed. L remains outside tempo and meter analysis.

A faint EQ theme stretches across the entire overlay behind the selected visualizer and text. Forty thin stems follow the same hits: D/F stay left, J/K/L stay right, and Space triggers the two bass responses. Bass has a higher ceiling. In Classic colors, green rises through yellow and orange to red near the top; strong combined or repeated bass hits occasionally reach those red peaks. Other color schemes supply their own matching spectrum and border colors. The spectrum describes key-driven visual energy rather than measured audio frequencies.

The EQ defaults to 92% transparency and its own Settings slider changes it immediately. Energy fades over 950 milliseconds, leaving a faint static pattern when tapping stops. Reduce Motion uses stationary stems with brightness feedback. The selected visualizer, bass border flash and background EQ respond together.

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

The listener retains only the mapped hit identities and timestamps in bounded in-memory histories. Preferences store enabled state, visual theme, color scheme, overlay size, visibility, EQ transparency, the chosen display and per-display overlay positions. DrumKey operates locally.

The overlay accepts mouse clicks for dragging, avoids keyboard focus, joins desktop Spaces, and restores its placement when screens change. Some exclusive full-screen applications or protected system surfaces can cover it. The fixed bindings use physical Mac key positions corresponding to ANSI D, F, J, K, L and Space.

DrumKey is permanently silent. MIDI is deferred from the current scope.

## Source and verification

- `Sources/DrumKeyCore` holds the timestamped hit types, rhythm analyzer and display selection policy.
- `Sources/DrumKey` holds the menu bar lifecycle, passive event tap, settings, display discovery, visual hit routing, background EQ, shared key-energy dynamics, eleven visual themes and fifteen palettes.
- `Packaging` and `scripts/build-app.sh` produce the launchable macOS bundle.
- `Tests/DrumKeyCoreTests` covers rhythm analysis, tolerant tempo averaging, tempo changes and boundaries, manual accent isolation, missed beats, idle reset and display fallback/restoration.
- `Tests/DrumKeyAppTests` covers capture recovery, L-key mapping, joint bass recognition and delayed event delivery, EQ peaks and decay, saved EQ transparency, alternating columns and wide cardinal accents, fixed column bases and clearance at each size, additive retriggers and bounded release, theme/color persistence, size persistence and screen fitting, 30-second border buildup, burst limits, quick release, and saved placement across displays and resolution changes.

```sh
swift test
```

The app is built with Swift 6 concurrency checking. Desktop checks covered Settings, preview, pausing and display selection on macOS 27.2.1 with a secondary monitor. Live verification requires permission for the current build. Older-system rendering and physical monitor hot-plug behavior need hardware verification.

The product record lives in [DECISIONS.md](DECISIONS.md). Future candidates include launch at login and more meter models.

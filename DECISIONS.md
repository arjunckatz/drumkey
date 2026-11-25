# DrumKey Decision Log

This file records confirmed product decisions, working assumptions, and unresolved questions. Update it whenever a decision changes or a question is resolved.

## Confirmed decisions

| Date | Area | Decision | Reason or consequence |
| --- | --- | --- | --- |
| 2026-11-24 | Input behavior | D, F, J, K, L and Space retain their ordinary operating-system and application actions while DrumKey is enabled. | DrumKey remains usable alongside ordinary work. |
| 2026-11-24 | Overlay position | Start in the top-left of the selected display, then allow clicking and dragging anywhere on the overlay. | Supersedes the fixed position and mouse click-through behavior. The panel keeps keyboard focus in the working app. |
| 2026-11-24 | Remembered placement | Remember the dropped position separately for each display, relative to its usable area. | Placement survives app restarts and adapts to screen resolution changes. Drops are kept inside the usable screen bounds. |
| 2026-11-24 | Dragging between displays | Dropping the overlay on another display selects that display in Settings. | The new display and placement survive a restart. |
| 2026-11-24 | Display selection | Use the first secondary display when one is connected. Fall back to the main display when there is only one display. | Prefer moving the ambient visual away from the primary workspace. |
| 2026-11-24 | Visual character | Keep the time signature and soundstage tiny, light, and consistent with Apple’s Liquid Glass design direction. | The overlay should feel ambient and avoid obscuring work. |
| 2026-11-24 | Glass implementation | Use AppKit’s native `NSGlassEffectView` on macOS 26 and newer, with a system visual-effect material on older supported versions. | Native materials adapt to appearance and accessibility settings. |
| 2026-11-24 | Visual mapping | Place D in the upper-left bass group and F in the lower-left bass group. Place J in the upper-right percussion group and K in the lower-right percussion group. | The two sides match the hands on the keyboard and make each group easier to identify. |
| 2026-11-24 | Mapping meaning | Treat the visual mapping as expressive feedback rather than an accurate interpretation of the user’s intended instrument. | Key identity alone cannot reveal musical intent. |
| 2026-11-24 | Meter presentation | Always show a provisional time signature, starting at 4/4, and refine it during continued tapping. Mark uncertain estimates with the approximate symbol. | Supersedes the initial decision to withhold ambiguous meter. |
| 2026-11-24 | Accent input | Treat Space as an explicit downbeat or accent marker. | Space recurrence can contribute more strongly to bar and meter hypotheses. |
| 2026-11-24 | Idle appearance | Keep the overlay faintly visible whenever DrumKey is enabled. | The user can see that capture is active without waiting for a hit. |
| 2026-11-24 | Motion | Keep resting positions anchored. Hits lift bars by 12 points and add up to seven points of height, returning within the existing 360 ms pulse. Use layered ripples around the stage and each struck group. | The rise is higher while its attack remains immediate. Reduce Motion uses brightness feedback. |
| 2026-11-24 | Generated sound | Do not generate drum sounds in any version of DrumKey. | DrumKey is a visual companion rather than a drum sampler. |
| 2026-11-24 | Minimum system | Support macOS 15 and newer. | A roughly two-year support window is acceptable and allows greater use of current platform behavior. |
| 2026-11-24 | Multiple secondary displays | Use the first secondary display reported by macOS by default. | This is acceptable without requiring initial configuration. |
| 2026-11-24 | Display settings | Include a Settings display picker. | Users can override automatic display selection and the preference survives a restart. |
| 2026-11-24 | MIDI | Do not work on MIDI support in the current project scope. Preserve it only as a possible later extension. | MIDI can be wired to the hit stream later if the product evolves in that direction. |
| 2026-11-24 | Saved display unavailable | Temporarily fall back to another available display when the chosen display disconnects, then automatically return when it reconnects. | The overlay remains available without discarding the user’s display preference. |

## Implementation choices

| Date | Area | Choice | Reason or consequence |
| --- | --- | --- | --- |
| 2026-11-24 | Overlay footprint | Use a vertical 192 × 252 point HUD with a default 16 point inset from the usable top-left screen corner. | Supersedes the original 248 × 72 horizontal layout. Dragging can change the position. |
| 2026-11-24 | Soundstage scale | Use a 167.2 point circular stage, 10% wider than the previous 152 point stage. | The circular layout determines the new overlay width. |
| 2026-11-24 | Soundstage appearance | Arrange sixteen glass columns around an open center. Each three-bar color group is followed by a narrower teal accent bar. | Preserves the twelve colored bars and adds four interleaved accents. |
| 2026-11-24 | Mirrored projection | Mirror the stage, glass faces, reflections and shading horizontally. | Reverses the previous apparent direction of the rising blocks. |
| 2026-11-24 | Bass emphasis | Make D/F columns 35% wider at rest and add 20% width during their rise. Use stronger glass faces, thicker highlights and bolder local and stage ripples. | Bass movement reads more strongly while using the existing 12 point lift and 360 ms response. Reduce Motion keeps the columns stationary. |
| 2026-11-24 | Joint bass border flash | Pressing D and F within 80 ms triggers a blue-violet flare around the rounded overlay border, fading within 360 ms. Consume each pair once and use the original event timestamps. | A brief border flash marks a joint bass hit; holding keys does not generate a continuing strobe. Reduce Motion uses a dimmer pulse. |
| 2026-11-24 | Accent placement | Place the four teal accent columns at the top, left, bottom and right of the ring, between the color triplets. | All bass columns remain on the left and all J/K columns remain on the right. |
| 2026-11-24 | Flash alignment | Center the projected resting blocks and all circular flashes on the same point. | Compensates for the visual shift caused by block height and depth. |
| 2026-11-24 | Manual accent bars | L triggers all four new bars together and keeps its normal typing behavior. | L is a visual control and does not alter BPM or meter estimates. |
| 2026-11-24 | Automatic accent bars | Remove automatic L-column triggering and its beat scheduler. Keep L as a manual accent control. | Supersedes the earlier learned-beat automation. The background EQ replaces its ambient motion. |
| 2026-11-24 | Background EQ | Draw forty 1.1 point spectrum stems behind the circle and text across the entire overlay. The same real key hits drive both visualizers. | D/F emphasize the left bands, J/K the right, L the high bands and Space the whole spectrum. The EQ is expressive key feedback. |
| 2026-11-24 | EQ transparency | Default to 92% transparency and provide an independent Settings slider from 0% to 100%. Persist the setting. | Higher values make the EQ fainter; 100% hides it. Overall overlay visibility remains separately adjustable. |
| 2026-11-24 | EQ palette | Use green at the bottom, yellow and orange above, and red at the highest peaks. Anchor the gradient to the full overlay height. | Strong combined or repeated hits can reach red without making every short band end in red. |
| 2026-11-24 | EQ activity lifetime | Decay key-driven energy over 950 ms, then leave a faint static resting pattern and stop animation frames. Reset on pause, reset, sleep or unavailable capture. | Background motion follows actual tapping. Reduce Motion keeps the EQ stems stationary and varies their brightness. |
| 2026-11-24 | Space feedback | Light the complete circular rim for a Space accent. | The center stays open. |
| 2026-11-24 | Enable shortcut | Use Control + Option + Command + D as a global toggle when the shortcut is available. | DrumKey can be paused while another app is active. The menu remains available if registration fails. |
| 2026-11-24 | Shortcut input | Ignore key repeats and mapped keys held with Command, Control or Option. | Held keys produce one hit and normal keyboard shortcuts avoid adding accidental hits. |
| 2026-11-24 | Permissions | Use a passive event tap with Input Monitoring access and show the capture state in Settings and the HUD. | Permission changes can recover automatically. Secure input is surfaced explicitly. |
| 2026-11-24 | Idle estimates | Keep the learned pattern through pauses up to 30 seconds. After a longer pause, reset to the provisional 4/4 baseline. | Supersedes the three-second reset so short pauses preserve learning. |
| 2026-11-24 | Pulse tolerance and averaging | Average normalized tap intervals over a rolling 12 seconds with 20% timing tolerance. Show an average after ten seconds of tapping even when the pulse is uncertain. | Supersedes the strict 6% match and fixed interval count that could leave uneven tapping on Finding pulse. Clear rhythms can establish BPM earlier. |
| 2026-11-24 | Uncertain BPM | Prefix BPM with the approximate symbol below 0.70 confidence and retain the previous BPM through brief uncertainty. | An uncertain average remains visible. The existing 30-second idle reset still applies, and EQ feedback responds independently of tempo confidence. |
| 2026-11-24 | Meter history | Retain up to three minutes or 2,048 hits, with recent evidence weighted more strongly. | Longer tapping can refine the current hypothesis and eventually replace it. |
| 2026-11-24 | Meter confidence | Mark tentative 3/4 and 4/4 with the approximate symbol, and remove the symbol when confidence reaches 0.8. Use a small switching margin to keep close candidates stable. | Confidence reflects recurrence, accents, duration and separation between candidates. |
| 2026-11-24 | Accessibility | Use system appearance colors and glass, and honor Reduce Motion in custom pulse drawing. | The HUD follows macOS appearance preferences. |
| 2026-11-24 | Border preview | Include D/F joint hits in the existing rhythm preview and describe the combination in Settings. | The complete border effect can be checked without live keyboard capture. |
| 2026-11-24 | Packaging | Build a local ad-hoc signed app at `build/DrumKey.app`. | Developer ID signing and notarization are needed for public distribution. |
| 2026-11-24 | Live verification | The user will grant Input Monitoring and perform live keyboard testing. | Automated checks cover analysis and display policy. Desktop checks cover Settings, preview and monitor selection. |
| 2026-11-24 | Capture recovery | Check both validity and enabled state of the passive event tap, reenabling or recreating it as needed. | A retained handle can outlive a functioning listener. |
| 2026-11-24 | Permission verification | Use the actual passive event-tap result to determine whether capture can start. | A preliminary permission result alone can block a working listener. |
| 2026-11-24 | Capture retry | Provide an immediate retry in Settings and throttle failed background creation attempts to one per five seconds. | The user can recover capture while background retries stay bounded. |
| 2026-11-24 | Local signing | Explain that ad-hoc rebuilds change code identity, and accept an existing certificate through `DRUMKEY_SIGNING_IDENTITY`. | The observed Input Monitoring switch was on while access to the running local build was denied. |
| 2026-11-24 | Packaging a running app | Require DrumKey to quit before replacing its app bundle. | The process and on-disk executable stay consistent during development updates. |
| 2026-11-24 | Permission refresh verification | With user approval, replace the stale Input Monitoring entry with the current DrumKey 0.1.1 app and reopen it. | The app changed from Permission needed to Listening after the entry was refreshed. |
| 2026-11-24 | Vertical update verification | Package DrumKey 0.2.0, inspect the portrait stage and animated preview, and refresh the same Input Monitoring permission for the updated build. | All 22 tests pass. The final vertical overlay reports Listening with a tentative 4/4 meter. |
| 2026-11-24 | Ripple update verification | Package DrumKey 0.3.0, inspect the mirrored sixteen-bar stage and animated preview, and refresh the existing Input Monitoring entry after the user unlocks System Settings. | All 36 tests pass, including beat scheduling, L-key mapping, shared visual centering and clearance at the higher rise. The final app reports Listening. |
| 2026-11-24 | Drag update verification | Package DrumKey 0.3.1 and refresh its existing Input Monitoring entry. | All 40 tests pass, including placement persistence, screen bounds and resolution changes. The final app reports Listening. Live mouse dragging still needs a user check because desktop automation cannot target the nonactivating panel. |
| 2026-11-24 | Pulse update verification | Package DrumKey 0.3.2, refresh the existing Input Monitoring entry, and inspect the BPM preview. | All 46 tests pass, including uneven tapping after warmup, uncertain averages, mixed subdivisions, missed beats, tempo changes and jitter at 60/200 BPM. The preview displays 150 BPM and the final app reports Listening. |
| 2026-11-24 | Bass layout verification | Package DrumKey 0.3.3, inspect the animated preview with D/F on the left and J/K on the right, and refresh the existing Input Monitoring entry. | All 46 tests pass, including projected centering, peak-rise clearance and Reduce Motion. The wider bass groups fit the HUD, and the final app reports Listening. |
| 2026-11-24 | Border flash verification | Package DrumKey 0.3.4, visually confirm the rounded border flare during the joint-bass preview, and refresh the existing Input Monitoring entry. | All 49 tests pass, including either key order, separate-tap rejection, delayed event delivery and reset behavior. The final app reports Listening. |
| 2026-11-24 | Background EQ verification | Package DrumKey 0.4.0, inspect the EQ behind the circle and text in the rhythm preview, exercise its transparency slider, restore the 92% default, and refresh the existing Input Monitoring entry. | All 44 current tests pass after removing the obsolete automation tests and adding EQ peak, decay and preference checks. The overall visibility remains 78%, the EQ setting changes independently, and the final app reports Listening. |

## Working assumptions

| Date | Area | Assumption | Needs confirmation |
| --- | --- | --- | --- |
| 2026-11-24 | Platform | Build the first version for macOS. | Confirm whether another desktop platform is expected later. |

## Open decisions

1. Confirm whether platforms other than macOS are expected later.

Display arrangement changes restore the saved placement immediately, including restoration of a connected preferred display. Displays without a saved placement use the top-left default.

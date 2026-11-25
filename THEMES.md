# DrumKey visual themes

Choose **Settings → Overlay → Visual theme**, then choose a separate **Color scheme**. Both selections update the running overlay immediately and survive a restart. The default remains Glass Circle with Classic colors.

## Layouts

| Theme | Appearance and response |
| --- | --- |
| Glass Circle | The original sixteen glass columns around an empty center. D/F alternate on the left, J/K on the right, with four wider manual L accents at the cardinal points. Each base stays fixed while its top grows. |
| Pulse Halo | An open, smoothly contoured halo with mirrored upper bass ears and progressively narrower side and lower percussion lobes. Its glass fill and outline blend through the five key colors symmetrically. Up to 36 points of outward travel at 1× makes each hit punchier. |
| Radial Spectrum | Sixty-four bold spokes growing outward from a fixed inner circle, with about 41 points of travel at 1×. The shared mirrored fields form smooth, overlapping musical regions with matching blended colors. |
| Linear EQ | Sixteen upright bars above a fixed horizontal baseline. Bass occupies the left half and percussion the right, with L accents distributed across the row. |
| Mirror Wave | A filled horizontal waveform extending above and below a fixed centerline. Key energy changes its amplitude across the width. |
| Orbit Dots | Twenty illuminated beads on static circular tracks, joined as a delicate necklace around an open center. The shared mirrored fields kick the beads outward along visible stems. Bass beads are fuller and lower accent beads are finer. |
| LED Matrix | A sixteen-column, twelve-row segmented display. Energy lights cells from the bottom upward through the selected spectrum. |

The primary visualizer shares one bounded energy envelope across all layouts. A hit adds 0.42 to its key's remaining energy, up to 1.0. Energy releases exponentially with a 0.70-second time constant. Repeated hits therefore build from the current height instead of restarting a separate jump. Glass tops extend up to 24 points at 1×; their bottom edges and widths remain fixed. All distances scale with the overlay preset while BPM and meter text keep their physical size.

Pulse Halo, Radial Spectrum and Orbit Dots amplify this same envelope with longer outward travel and stronger highlights. Radial tips and bead edges reserve room for their glow, the fixed-size labels and the panel boundary at every size. Retriggers add to the remaining energy while each shape falls back; the extra travel does not introduce a separate oscillator or expanding ripple.

Space supplies a broad accent in the new layouts. L remains a manual visual accent outside tempo and meter analysis. The existing background EQ, D/F border flash, and J/K border meters run alongside every layout with their own established timing. Switching themes preserves the current key energy. Reduce Motion uses stationary geometry with brightness feedback, and drawing timers stop once the input energy has settled.

## Radial key composition

Pulse Halo, Radial Spectrum and Orbit Dots share a low-to-high sweep reflected across the vertical centerline. Every individual key excites both sides together. Broad bass fields give the silhouette weight; percussion becomes progressively narrower toward the lower edge. Adjacent fields overlap smoothly, so mixed taps combine into a coherent outline. Color transitions follow the same fields and remain mirrored.

| Key | Main regions, approximately | Visual role |
| --- | --- | --- |
| D | 11:10 and 12:50 | Broad upper bass crests, forming the inner pair of ears. |
| F | 10:10 and 1:50 | Broad outer bass shoulders, opening the upper half. |
| J | 9 and 3 o'clock | Paired sidewalls for the main snare response. |
| K | 7:50 and 4:10 | Tighter lower shoulders for a contrasting percussion response. |
| L | 6:40 and 5:20 | Fine lower accent peaks, replacing the radial four-cardinal cross. |
| Space | Complete circumference | A balanced whole-rim downbeat accent. |

These are expressive spatial roles, rather than a measured frequency or a claim about the intended instrument. The same 0.70-second release and additive retriggers drive every region. Glass Circle retains its alternating left-hand bass/right-hand percussion layout and four manual cardinal L columns. The flat layouts keep their existing mapping. The rhythm preview includes a manual L example alongside its percussion hits.

### Mapping analysis and references

For this small HUD, I selected bilateral symmetry so alternating bass keys reshape a centered silhouette. Grouping neighboring bands creates a clear upper-to-lower progression, while narrower accent fields supply detail. The open halo and necklace leave visual space in the center. This is an aesthetic choice for DrumKey; radial visualizers do not prescribe a universal position for each drum or keyboard key.

- [audioMotion's mirror documentation](https://github.com/hvianna/audioMotion-analyzer/blob/master/README.md#mirror-number) describes mirroring the frequency axis and its radial behavior. It informed the shared reflected sweep.
- [More Lively Audio Visualizer](https://github.com/Bao6879/more-lively-audio-visualizer) supports circle spectra with mirrored segments. A single reflected pair gives DrumKey a balanced silhouette at its small size.
- [Watherum's Audio Visualizer](https://github.com/Watherum/Audio-Visualizer) describes circular bars and particles tied to frequency bands. It informed applying one region model to both spokes and beads.

## Color schemes

| Scheme | Character |
| --- | --- |
| Classic | Original indigo/blue bass, orange/pink percussion, teal L and mint Space. Background EQ and LEDs progress from green through yellow and orange to red. The border uses deep gunmetal blue. |
| Aurora | Violet, cyan and green with pale mint highlights. |
| Sunset | Coral, amber, pink and violet. |
| Neon | Cyan, purple, lime and magenta. |
| Ocean | Deep blue through turquoise with ice-blue highlights. |
| Ember | Rust, orange and red with warm gold highlights. |
| Gunmetal | Muted steel blues and pale silver-blue highlights. |

Colors apply to the main visualizer, background spectrum and border feedback. The three radial layouts blend their key colors across mirrored regions; the Halo fill follows a matching top-to-bottom gradient. Theme and color selections are independent of display, size, overall visibility and background EQ transparency.

## Research references

These projects informed the visual vocabulary. DrumKey's drawings are original native AppKit implementations; they do not embed these projects' code, logos or assets. Pulse Halo also follows the user-requested direction of a Trap Nation-style open circular visualizer.

| Project | Relevant reference and DrumKey design direction |
| --- | --- |
| [audioMotion-analyzer](https://github.com/hvianna/audioMotion-analyzer) | Its documented radial, round-bar and LED modes informed the distinction between Radial Spectrum, Linear EQ and LED Matrix. |
| [Wave.js](https://github.com/foobar404/Wave.js) | Its layered Wave, Square and Glob animations and configurable gradients informed the contoured Pulse Halo and Mirror Wave treatments. |
| [Butterchurn](https://github.com/jberg/butterchurn) | Its MilkDrop preset approach informed offering several substantially different compositions through one selector. Orbit Dots uses a restrained geometric composition suited to this small overlay. |
| [Webamp](https://github.com/captbaritone/webamp) | Its recreation of the classic Winamp desktop player provided a compact desktop visual reference for the segmented LED Matrix treatment. |
| [CAVA](https://github.com/karlstav/cava) | Its console-bar presentation and gradient options informed Linear EQ's clean baseline and LED Matrix's bottom-up spectrum. |
| [wavesurfer.js](https://github.com/katspaugh/wavesurfer.js) | Its horizontal waveform display provided a reference for Mirror Wave's centerline composition. |

Those projects generally visualize audio. DrumKey derives its display entirely from the mapped keyboard hits, so its bars and waves express tapping energy rather than measured sound frequencies. It remains permanently silent and does not capture music or microphone audio.

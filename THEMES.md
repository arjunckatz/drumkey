# DrumKey visual themes

Choose **Settings → Overlay → Visual theme**, then choose a separate **Color scheme**. Both selections update the running overlay immediately and survive a restart. The default remains Glass Circle with Classic colors.

## Layouts

| Theme | Appearance and response |
| --- | --- |
| Glass Circle | The original sixteen glass columns around an empty center. D/F alternate on the left, J/K on the right, with four wider manual L accents at the cardinal points. Each base stays fixed while its top grows. |
| Pulse Halo | An angular open halo with pointed side jaws, diagonal horns and separate upper/lower crowns. Its sharp outline and glass fill retain up to 36 points of outward travel at 1×. |
| Radial Spectrum | Seventy-two tapered spears growing from a fixed inner circle, with about 41 points of travel at 1×. Spear tips and angular key fields give it a bass-distortion character. |
| Linear EQ | Twenty-four bars above a fixed baseline: six D, six F, then four each of J, K and L. Bass stays entirely on the left and has a 107-point peak height at 1×; J/K/L peak at 67 points. |
| Mirror Wave | A filled horizontal waveform extending above and below a fixed centerline. Key energy changes its amplitude across the width. |
| Orbit Shards | Twenty-four radial glass kites with pointed outer tips and anchored stems. The saved Orbit Dots preference opens this refreshed design automatically. |
| LED Matrix | Twenty-four segmented columns. Paired D/F clusters fill the left half and two J/K/L banks fill the right. Bass can light sixteen rows; J/K/L can light ten. |
| Circle Towers | Eighteen projected glass towers around an elliptical circular stage. D/F control the heavy front-left/front-right banks; J/K the rear-left/rear-right banks; L the two side beacons. Bases stay anchored as tops grow. |
| Razor Bloom | Twenty-four faceted crystal blades around an open core, driven by the new radial mapping. Each blade ends in a sharp point. |
| Silk Ribbons | Five translucent horizontal ribbons, one each for D, F, J, K and L from top to bottom. Hits lift their waves and strengthen their glass highlights. |
| Hex Array | Nineteen glass hexagons: D controls the central spine, F the middle flanks, J/K the side cells and L the upper/lower edge tiles. |

The primary visualizer shares one bounded energy envelope across all layouts. A hit adds 0.42 to its key's remaining energy, up to 1.0. Energy releases exponentially with a 0.70-second time constant. Repeated hits therefore build from the current height instead of restarting a separate jump. Glass tops extend up to 24 points at 1×; their bottom edges and widths remain fixed. All distances scale with the overlay preset while BPM and meter text keep their physical size.

The radial layouts use longer outward travel, tapered tips and stronger highlights. Tips and crystal edges reserve room for their glow, the fixed-size labels and the panel boundary at every size. Retriggers add to the remaining energy while each shape falls back; the extra travel does not introduce a separate oscillator or expanding ripple. Circle Towers uses 36 points of bass extension, 26 points of percussion extension and 44 points for its side beacons at 1×.

Space triggers D and F together in every layout, including the background EQ and joint-bass border flash, while retaining its own downbeat/rim accent. The analyzer receives one original Space onset. L remains a manual visual accent outside tempo and meter analysis. The background EQ and J/K border meters run alongside every layout. Switching themes preserves the current key energy. Reduce Motion uses stationary geometry with brightness feedback, and drawing timers stop once the input energy has settled.

## Radial key composition

The November 27 redesign replaces the previous upper-to-lower frequency sweep in Pulse Halo, Radial Spectrum and Orbit Shards, and also drives Razor Bloom. D makes broad horizontal jaws, F forms four diagonal horns, J and K separate the top and bottom crowns, and L cuts a fine twelve-tooth rim. Compact angular profiles and unsmoothed crests make pointed shapes, with stronger bass weight across the sides and diagonals. The existing additive hit-and-decay physics remains shared.

| Key | Main regions, approximately | Visual role |
| --- | --- | --- |
| D | 9 and 3 o'clock | Broad lateral bass jaws. |
| F | 1:30, 4:30, 7:30 and 10:30 | Four diagonal bass horns. |
| J | 12 o'clock | Upper percussion crown. |
| K | 6 o'clock | Lower percussion crown. |
| L | Twelve fine peaks around the rim | Manual serrated accent. |
| Space | D and F regions together | Combined bass response plus the downbeat accent. |

These are expressive spatial roles rather than measured frequencies or a claim about the intended instrument. The same 0.70-second release and additive retriggers drive every region. Glass Circle retains its alternating hand layout. Circle Towers has its own front/rear banks, and the two EQ layouts have separate assignments as described above. The rhythm preview includes Space and manual L examples.

### Mapping analysis and references

The current composition uses broad side weight for D and diagonal thrust for F, so the bass keys have visibly different shapes. Upper/lower percussion crowns add contrast, and the narrow L teeth supply detail without taking a fixed four-column cross. This is an aesthetic choice for DrumKey; radial visualizers do not prescribe a universal position for each drum or keyboard key. Earlier research informed the visual vocabulary:

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
| Ultraviolet | Saturated violet, orchid and electric purple. |
| Cyberpunk | Hot pink, purple, cyan and amber. |
| Acid | Lime, chartreuse, green and a red-orange accent. |
| Glacier | Ice blue, cool silver and pale cyan. |
| Rose Quartz | Rose, blush, lilac and warm pearl. |
| Copper | Copper, bronze, gold and oxidized teal. |
| Jade | Forest green, jade, sea glass and pale cream. |
| Monochrome | Graphite through steel and silver-white. |

All fifteen color schemes apply to the main visualizer, background spectrum and border feedback. The radial layouts blend key colors across their angular regions; the Halo adds a matching glass gradient. Theme and color selections are independent of display, size, overall visibility and background EQ transparency.

## EQ bass placement and height

D/F columns stay on the left of both foreground EQs. Linear EQ uses solid banks; LED Matrix uses alternating two-column bass clusters. J/K/L stay on the right. For equal input energy, bass rises higher, with a higher maximum: 107 versus 67 points in Linear EQ and sixteen versus ten rows in LED Matrix. The background EQ follows the same left/right assignment and caps repeated J/K/L energy below the bass ceiling. Space supplies the same D/F responses together.

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

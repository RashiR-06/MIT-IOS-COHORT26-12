# Lesson 1.1 — Audio manifest

Every audio file used by Lesson 1.1, where it lives and where it is used.
File names must stay unique across the whole project (the app bundle is flat).

## In the app bundle

| File | Path | Format | Length | Used in |
|---|---|---|---|---|
| `drum_kick.wav` | `MusicProdApp/MusicProdApp/Resources/Audio/Learning/Drums/` | 44.1 kHz, 24-bit, stereo | 0.43 s | Lesson groove (Intro, Learn, Do, Finale) and the audio debug screen |
| `drum_snare.wav` | `MusicProdApp/MusicProdApp/Resources/Audio/Learning/Drums/` | **48 kHz**, 32-bit float, stereo | 0.57 s | Same as above |
| `drum_hat_closed.wav` | `MusicProdApp/MusicProdApp/Resources/Audio/Learning/Drums/` | 44.1 kHz, 24-bit, stereo | 0.33 s | Same as above |

The sample rates differ on purpose: `DrumSampleLoader` loads each file in its own format and the mixer converts.

## Reference only (not in the app)

| File | Path | Format | Length | Purpose |
|---|---|---|---|---|
| `ref_groove_100bpm.wav` | `docs/lesson-1.1/audio/` | 44.1 kHz, 16-bit, stereo | 7.3 s (3 bars) | How the Learn/Do groove should sound at 100 BPM |

## The groove (`DrumPattern.lessonGroove`)

8 steps of one eighth note each (one bar of 4/4), same for Learn and Do:

| Step | 1 | 1& | 2 | 2& | 3 | 3& | 4 | 4& |
|---|---|---|---|---|---|---|---|---|
| Kick | ● | | | | ● | | | |
| Snare | | | ● | | | | ● | |
| Closed hat | ● | soft | ● | soft | ● | soft | ● | soft |

"Soft" hats play at 43% volume. This matches the reference WAV and the Learn mockup. The Do/Finale mockups add a soft kick on 3&; that is deliberately not used.

## Mockups

The HTML mockups are in `docs/lesson-1.1/` (not a `mockups/` subfolder): `intro_track_breaks_no_bar.html`, `learn_three_cards_mockup.html`, `do_section_three_activities_mockup.html`, `lesson_finale_tap_only_mockup.html`.

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
| `ref_groove_100bpm.wav` | `docs/lesson-1.1/audio/` | 44.1 kHz, 16-bit, stereo | 7.3 s (3 bars) | How the Intro/Learn/Do groove should sound at 100 BPM |

## The groove (`DrumPattern.lessonGroove`, also `introGroove`)

8 steps of one eighth note each (one bar of 4/4). The same groove is used in the Intro, Learn and Do. It was matched to `ref_groove_100bpm.wav` by mixing our three samples and comparing each eighth note:

| Step | 1 | 1& | 2 | 2& | 3 | 3& | 4 | 4& |
|---|---|---|---|---|---|---|---|---|
| Kick | ● | | | | ● | | | |
| Snare | | | ● | | | | ● | |
| Closed hat | | ● | | ● | | ● | | ● |

Hats play on the off-beats only, at full volume. The reference has no sound on the sixteenths in between and no kick on 3&. (The Do/Finale mockups add a kick on 3&, and the Intro mockup has sixteenth-note hats; neither is used, because the reference WAV wins for sound.) In the Intro the groove then slows from 100 to 52 BPM with lower pitch and a closing low-pass filter (see `IntroTiming`).

## Mockups

The HTML mockups are in `docs/lesson-1.1/` (not a `mockups/` subfolder): `intro_track_breaks_no_bar.html`, `learn_three_cards_mockup.html`, `do_section_three_activities_mockup.html`, `lesson_finale_tap_only_mockup.html`.

# Lesson 1.1 — Decisions (source of truth for the build)

Last updated: 12 Nov 2026

## Rule 0: what wins when sources disagree
1. Figma screens (file App-Design-Version-2, Lesson 1.1 section, node 191:1956 and 527:3429) win over everything.
2. HTML mockups fill in behaviour the Figma screens don't show (timings, tempo maths, tap judging).
3. The Curriculum PDF is used ONLY for interactions/behaviour the other two don't cover. Where it contradicts Figma or the mockups, ignore the PDF.
Do not invent screens, copy, colours or interactions. If something is missing, stop and ask.

## Screen flow (from Figma frame names)
Intro (E): 1 Steady -> 2 Slowing -> 3 Crawl settled, invite to rescue. One continuous screen, no bottom bar.
Learn (F): 3 cards (pulse; BPM; tempo and energy), swipe stack.
Do (G): 1 Tap the pulse -> 2 Find the 1 -> 3 Match the brief.
Finale (H): Tap the tempo (+/-5 BPM) -> drums speed back up -> back to original tempo -> "Lesson complete" pop-up.

## Navigation
- Back = go to the previous step in the flow above. On the first step, Back behaves like Close.
- Close = alert "Leave the lesson?" (Leave / Stay). Leave goes to a TEMPORARY blank screen (placeholder, replaced when Home/Learn map exists).
- After "Lesson complete" the same temporary blank screen is shown.
- Primary button label is "Next" (as in Figma); other labels exactly as in Figma.

## Progress bar
- 10 segments, two states only: reached (accentCyan) and not reached (stroke). No "current" state.
- Which segment each step lights: READ FROM THE FIGMA FRAMES (Progress bar in each frame). Mockup values: Intro = 1, Do 1/2/3 = 6/7/8, Finale = 10. Segments for Learn cards and the rest: read from Figma, do not guess.

## Colours
- Only the 8 AppColor tokens. Wrong/miss = accentPink (Figma), NOT red (PDF says red).

## Audio (Lesson 1.1)
- Three one-shot WAVs (kick, snare, closed hi-hat), sequenced in code on one AVAudioEngine clock. No Timer for musical timing.
- Pattern data and tempo maths as in the mockups (intro 100 BPM -> slow-down to 52 over 8 s after 4.8 s; Learn/Do 8-step eighth-note groove).
- Tap judged with output-latency compensation; tap pad reacts on touch-down.
- Note: the PDF says "no audio files, note data only". That describes the later melodic lane / sourcing concern; for drums we use our own recorded one-shots. Not a conflict for the build.

## Timing thresholds (decision needed from team)
- Do 1 Tap the pulse: mockup = 8 hits within +/-100 ms. PDF = 6 of 8 within +/-80 ms. DEFAULT: follow the mockup (+/-100 ms) unless the team says otherwise.
- Finale: 4 taps show a reading, 6 taps enable Set tempo, reset after 1.5 s gap, median interval, pass within +/-5 BPM of 100, ramp 52 -> 100 over 2.4 s.

## Not in the PDF's 1.1, ignore the PDF here
- PDF lists a 4th Do activity ("Tune the track"). Figma moved this into the Finale (Tap the tempo). Follow Figma.
- PDF "Hint after 2 wrong, answer after 3" rules: not in mockups. NOT built in Lesson 1.1 unless a Figma frame shows it (Match the brief has a "hint open" frame: build exactly that).
- PDF mentions a "Learn tab": the app has NO tab bar. Ignore.

## Open (defaults used until the team answers)
- Reward / sound on lesson complete: none beyond the Figma pop-up.
- Where the user goes after the pop-up: temporary blank screen.

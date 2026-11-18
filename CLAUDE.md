# CLAUDE.md

## Project
- MusicProdApp: native iOS app teaching beginner music production. Features: Home (navigation hub), Learn (4 stations of lessons), Challenges, Sandbox, Progress (Profile lives inside Progress).
- Built by two students as a capstone. Both are Swift/SwiftUI/Xcode beginners, so explain what you do in plain language.
- Current phase: UI RESKIN. The audio engine, tap/tempo logic, view models and content models from Lesson 1.1 already exist and are tested: reuse them, do not rewrite them. Views, tokens and components are being rebuilt to the new Figma design.
- Current scope is stated in the task. Do not build screens or features that aren't asked for.

## Source of truth
1. Figma, page "HiFi 4 · Digital" (node 1364:20821) in https://www.figma.com/design/TGDsK15xqZlYz7PCaRiFDR/App-Design-Version-2 wins for looks, layout, text and states.
2. `docs/lesson-1.1/decisions.md` and the mockups in `docs/lesson-1.1/` for lesson behaviour not shown in Figma.
3. `docs/lesson-1.1/Curriculum...pdf` only for interactions nothing else covers. If anything disagrees with Figma, Figma wins.
Do not invent screens, copy, colours or interactions. If something is missing or two sources disagree in a way you can't resolve, stop and ask.

## Tech stack
- Xcode 27.2, Swift, SwiftUI. iPhone only, landscape only, dark mode only, English only.
- Minimum iOS: Liquid Glass needs iOS 26+. Check the project's deployment target before relying on it, and never set it above the iOS on our test phones.
- Test devices: iPhone 13 (844x390), iPhone 17 (874x402). Figma frames are iPhone 16 landscape (852x393): use real layout and safe areas, never hard-code Figma coordinates.
- Frameworks: SwiftUI, AVFoundation. No third-party packages without asking.
- Persistence is undecided (SwiftData vs UserDefaults + JSON). Do not choose. Put it behind a small protocol.

## Folder structure
The repo's current structure is the source of truth; put new files in existing folders.
```
MusicProdApp/
  App/        entry point, root navigation
  Core/       design system (AppColor, AppFont), extensions, utilities
  Features/   Home/, Learn/, Challenges/, Sandbox/, Progress/ (incl. Profile)
  Shared/     reusable views, components, navigation, protocols, Shared/Models
  Services/   Audio/, Persistence/, Data/
  Resources/  Assets/, Audio/, Fonts/, Data/
```
- Pure, feature-independent logic goes to `Core/Utilities`. Feature-specific logic stays in its feature.
- Features never import another feature's folder; they communicate via Shared navigation and Services.
- `.gitkeep` files are excluded from the app target by a membership-exceptions block in the project file. Do not remove it.
- File names must be unique project-wide (audio and fonts included).

## Architecture: MVVM
- View: draws state, forwards taps, no business logic.
- ViewModel: `@Observable` class, one per screen or flow.
- Model: plain structs and enums.
- Services (audio engine etc.) are created once at app start and passed in; views never create services.
- Navigation: one route enum and NavigationStack at the root. Back always navigates by the stack, never by hard-coded destinations.
- Keep it simple: no extra abstraction layers we can't explain.

## Design rules (from the current Figma)
- Fonts, ONLY two: Pulse12 (Bold) for titles, headings and big numbers; SF Mono for everything else, buttons included. Never SF Pro, never a digital font on buttons. Use `Font.custom(..., relativeTo:)` / system monospaced so text scales.
- Fonts are defined once in `Core/DesignSystem` (`AppFont`). Colours only via `AppColor`, never inline. Re-read the exact values from the Figma variables; do not trust the values written in old docs.
- Effects: native Liquid Glass (`.glass`, `.glassProminent`) is allowed on controls. No other glow, blur, gradients, scanlines, VHS/CRT effects, or custom shadows unless Figma shows them.
- Icons: SF Symbols only.
- No tab bar anywhere. Landscape only. Minimum touch target 44 pt.
- Navigation and play/pause buttons are 32 pt with 12 pt padding (44 pt hit area), symbols sized to match. CTA buttons are all the same style.
- Lessons and challenges are shown by name, never by number ("Tempo and Beats", not "1.1"). "Musician Coins" for points. No stars.
- Respect the safe area on the Dynamic Island side; backgrounds run edge to edge.
- Short on-screen text, one clear purpose per screen.

## Audio
- One audio clock: schedule every musical event from the audio engine's clock, never Timer or DispatchQueue. Visuals read position from the engine.
- Judge taps against the audio clock, compensating for output latency. Tap pads react on touch-down.
- Drums are three one-shots (kick, snare, closed hi-hat) sequenced in code; melodic sounds later via a sampler.
- Audio files live in `Resources/Audio/`, uniquely named, listed in `docs/lesson-1.1/audio-manifest.md`.
- Nothing audio-related counts as working until a human tests it on a real iPhone.

## Git: WE commit, not you
- NEVER run git commit, git push, git merge, git tag, git branch or gh. Don't stage files. You may read git status/diff/log.
- When a block is approved and finished, give us the exact terminal commands to run, in order: create the branch from an up-to-date `develop`, `git add` with explicit paths (never `git add .` or `-A`), a short imperative commit message, push, and the PR title and description to paste in GitHub.
- Our local signing settings in project.xcproj (team, bundle ID) and `xcshareddata/` must never be staged.
- Branches are `<area>/<what>` from `develop`. One block = one branch = one PR into `develop`. `develop` to `main` by PR at milestones. Never push to `main` or `develop`, never force-push.

## How to work with us
- Before coding each block: list the files to create or change and why, and the Figma frames you read. WAIT for our OK.
- Small steps; explain what each file does in plain language. Don't generate the whole project at once.
- After each block: build, run tests, then tell us what to test on the iPhone 13 and 17, then give the git commands. Never call anything working unless verified.
- Challenge our decisions when there's a better approach. Ask instead of guessing. If a build error isn't fixed after two attempts, stop and report what you tried.

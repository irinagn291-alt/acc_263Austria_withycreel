# Withycreel

Withycreel is a catch log for anglers who must know what they may keep against daily and season bag limits. Home is today’s stringer of glass clips. Tap Keep to file a fish; remaining for that species updates. Everything stays on this device.

## Architecture

The day is a **Stringer ADT fold** with cases `Open`, `Kept`, `Released`, and `Over`. Today’s stringer is a fold over `Fish`, not a list of records the view edits in place.

That pattern fits this product because the verb is keep-the-stringer, not log-a-row. Keep appends a `Fish`, writes a `KeepMark`, and spends one from daily remaining and from season remaining. Remaining is `max(0, SpeciesLimit − KeepMark count)` so it never goes negative. Release files a `Fish` with no `KeepMark` and spends nothing. Keep at remaining 0 still files, lifts that fish to `Over`, and publishes a warning. Undo peels only the last `Fish` on today’s stringer and restores remaining if that fish carried a KeepMark.

One `StringerStore` owns the fold. Views talk to `CreelHold` and never touch UserDefaults. Types and folders follow stringer role: Stringer, Fish, KeepMark, Release, Limit, Over.

## Overhang keep

Keep is the first tap and stays enabled after seed. A full stringer does not block the clip. The fish hangs past the last clip as Over, remaining stays at zero, and the open clip warns in words and shape — colour is never the only signal. Release never spends. Peel last undoes only today. Limits edits `SpeciesLimit`. Settings exports CSV. History is Fish order on the stringer, not a global timeline.

## Design

Orchid soft focus. SF Pro via `Font.system`. Named colours: background `#F7F5FA`, surface `#FEFDFE`, ink `#231839`, accent `#5B2CBA`, muted `#6F6487`. Cards use 22pt corners and one soft shadow; chips use 14pt. Primary Keep sits in a soft card. Custom drawing is confined to the glass-clip stringer (Shape, Path, Material glass). Limits and Settings are stock.

Art style: 3D glass render glassmorphism. Base prompt:

```
3D glass render, frosted translucent glassmorphism, soft-focus studio light, a withy creel and a hanging stringer of glass fish clips over still water, refraction and milky frost, quiet product still life, no readable text, no letters, no logo, no specific hues
```

Exact prompt used for every image set:

- `wyc_AppIcon` — 3D glass fish clip on a withy stringer, single emblem filling the canvas edge to edge, frosted glassmorphism, studio soft focus, no text, no letters, no rounded corners, no drop shadow, opaque, subject inside the middle 80 percent
- `wyc_Splash` — Vertical 3D glass stringer of clips over still water, frosted glassmorphism, quiet uncluttered centre band, studio soft focus, no readable text
- `wyc_Onboarding1` — 3D glass still life of a withy creel and an empty stringer, the product in one glance, frosted glassmorphism, isolated cutout, no text
- `wyc_Onboarding2` — 3D glass mid-gesture: a keep clipping a glass fish onto the stringer, frosted glassmorphism, isolated cutout, no text
- `wyc_Onboarding3` — 3D glass stringer after many clips with one fish hanging past the last clip, accumulated creel, frosted glassmorphism, isolated cutout, no text
- `wyc_EmptyHome` — 3D glass empty withy creel and vacant stringer over still water, waiting, calm and inviting, never sad, frosted glassmorphism, isolated cutout, no text
- `wyc_EmptyList` — 3D glass empty creel-census leaf with no limit cards, frosted glassmorphism, isolated cutout, no text
- `wyc_CardBackdrop` — Abstract frosted glass and still-water refraction, low contrast so type can sit on top, 3D glass render, no letters, fills the canvas
- `wyc_ControlFace` — Face of a single glass keep clip as a physical control, frosted glassmorphism, isolated cutout, no text
- `wyc_TwistHero` — 3D glass emblem of overhang keep: a fish hanging past the last clip on a full stringer, frosted glassmorphism, isolated cutout, no text
- `wyc_SuccessMark` — Small 3D glass clip-click confirmation spark, frosted glassmorphism, isolated cutout, no text
- `wyc_HeaderDecor` — Wide 3D glass withy-and-water band, frosted clips in a row, low contrast, no readable text

Cut-outs (everything except AppIcon, Splash, CardBackdrop) are isolated subjects with a real PNG alpha channel and transparent corners. Assets are produced by a later `assets.generate` step; imagesets are named and empty until then.

## How this is not a repeat

catch_log has not shipped. Home is the stringer of glass clips, not a CatchList plus form. Keep is the first tap and stays enabled after seed. Over hangs past a full bag instead of blocking. This is not trip-life, not scaffold-then-bed, and not a food tracker. Scanner and a remote catalog stay unused. There is no Game tab, no WebView, and no photo-dump home.

## Build

```bash
cd Withycreel
xcodegen generate
xcodebuild build-for-testing -scheme Withycreel -destination 'generic/platform=iOS Simulator'
xcodebuild -scheme Withycreel -destination 'generic/platform=iOS' build
```

Simulator seed is `wyc.demo.v1` only. Launch with `-ReviewScreen today|log|goals` after onboarding to open Catches, Limits, and Settings.

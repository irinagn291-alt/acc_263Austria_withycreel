# Withycreel — Build Specification

> Portfolio app 69, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Log a kept fish and see remaining daily and season bag limits.

| Field | Value |
| --- | --- |
| Product name | Withycreel |
| Bundle identifier | `com.withycreel.bag` |
| Domain | https://withycreel-bag.pro |
| Contact URL | https://withycreel-bag.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `wyc_` |
| User-Agent | `Withycreel/1.0 (iOS; +https://withycreel-bag.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Withycreel -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

An angler logs a kept fish on today's stringer and the remaining bag for that species updates.

### 2.1 User flow

1. Tap Keep on the stringer to file a fish of the selected species
2. Change species, length or weight on the stringer and keep again
3. Tap Release to file a fish that does not spend remaining
4. Read remaining, or the Over warning when the bag is already full
5. Edit daily and season limits on the Limits tab
6. Export CSV from Settings

### 2.2 Essential behaviour

- Species daily and season bag limits
- Keep versus Release
- Length and weight fused on the stringer, stored as cm and kg
- Over warning after save when remaining is 0; Keep is not refused
- Display units with SI in the store
- CSV export
- Local only

---

## 3. Uniqueness assignment for Withycreel

| Axis | Assigned value |
| --- | --- |
| Architecture | **Stringer ADT fold (Open | Kept | Released | Over); the day is a fold over Fish; Keep writes a KeepMark and spends 1 from remaining; Release files without spending; Keep at remaining 0 files Over and warns** |
| UI approach | **SwiftUI pure · take catchlog** |
| Naming convention | **Stringer / creel-census lexicon** |
| File organization | **By stringer role (Stringer, Fish, KeepMark, Release, Limit, Over)** |
| Dependency strategy | **None** |
| Design direction | **Orchid soft focus** |
| Typography | **SF Pro** |
| Navigation pattern | **Stringer-tab chrome (Catches holds the stringer; species, length and keep fuse on the stringer; Limits and Settings are sibling tabs)** |
| AI art style | **3D glass render glassmorphism · take catchlog** |
| Functional twist | **Overhang keep (Keep always files; a full stringer writes Over and warns; remaining never goes negative)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — catch_log

**Core** — An angler logs a kept fish on today's stringer and the remaining bag for that species updates.

**Audience** — Anglers who must know what they may keep against daily and season bag limits.

**User flow**

1. Tap Keep on the stringer to file a fish of the selected species
2. Change species, length or weight on the stringer and keep again
3. Tap Release to file a fish that does not spend remaining
4. Read remaining, or the Over warning when the bag is already full
5. Edit daily and season limits on the Limits tab
6. Export CSV from Settings

**Essential features**

- Species daily and season bag limits
- Keep versus Release
- Length and weight fused on the stringer, stored as cm and kg
- Over warning after save when remaining is 0; Keep is not refused
- Display units with SI in the store
- CSV export
- Local only

**Twist** — Overhang keep. Home is today's stringer. Keep writes a Fish at the inline length and weight, writes a KeepMark, and spends one from that species' daily remaining and from its season remaining. Release writes a Fish with no KeepMark and spends nothing. When daily remaining or season remaining is already 0, Keep still files and writes Over; remaining stays 0 and the fish hangs past the last clip. Undo peels the last Fish on today's stringer and restores remaining if that Fish had a KeepMark. Home verb: keep-the-stringer, not log-a-row. Limits edits SpeciesLimit. Settings exports CSV. History is Fish order on the stringer, not a global timeline.

**Why this is not a repeat** — catch_log has not shipped. Home is the stringer of glass clips, not a CatchList plus form. Keep is the first tap and stays enabled after seed; Over hangs past a full bag instead of blocking. This is not trip-life (no snap that zeros a daily register), not scaffold-then-bed (no second commit), and not a food tracker. Scanner and cgi search are unused leftovers.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Catch journal. Limits after save, not instead of save.
- Invariant: Always save the catch, then warn if day/season count > SpeciesLimit. Season = calendar year. Store SI (kg, cm).
- Never: No Tides mini-game. Location denied → Settings copy.
- Mini-ref `ReelLedger`: steal Catch log, kept/released, store kg, monthly weight, photo, CSV, empty water. Never WebView leftover. Not a bag-limit skip — family still warns after save. New types and layout — do not reskin.

### 3.1 Architecture contract

The day is a Stringer ADT with cases Open, Kept, Released, and Over, and today's stringer is a fold over Fish rather than a list of records the view edits in place. Keep appends a Fish at the inline length and weight stored as cm and kg, writes a KeepMark, and spends one from that species daily remaining and from its season remaining, with remaining equal to max of zero and SpeciesLimit minus KeepMark count so it never goes negative. Release appends a Fish with no KeepMark and spends nothing. When daily remaining or season remaining is already zero, Keep still files, lifts that Fish to Over, and publishes a warning; Keep is never refused. Undo peels the last Fish on today's stringer and restores remaining only if that Fish carried a KeepMark. One StringerStore owns the fold; views call keep, release, and peel; unit tests prove always-save-then-warn against SpeciesLimit, season as the calendar year of the Int YYYYMMDD day key, SI storage, remaining never negative, and peel restore.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI pure with the catchlog take-token: first of this family, so compose an original glass-clip stringer; steal kept versus released, kg and cm in the store, CSV, and empty water only — do not copy ReelLedger type names, file trees, photo-dump home, WebView, or a CatchList plus form. Stock SwiftUI only: TabView, NavigationStack, Button, List, Form, scrollTargetBehavior paging. No UIViewRepresentable, no WKWebView, no Safari sheet. Home is the mechanic: Catches is a vertical snap of glass clips filling remaining height and the iPad width; species, length, weight, Keep, and Release fuse on the open clip. Confine custom drawing to that one stringer hero (Shape, Path, Material glass); Limits and Settings are stock. Chrome lives inside the Button label with contentShape; min 44pt; buttonStyle plain; primary Keep sits in a soft card. Empty and onboarding are full pages with frame(maxHeight: .infinity) and a bottom full-width CTA. Background fills the safe area; tab bar sits on the home indicator; lists use contentMargins.bottom. Colour is never the only Over signal. One haptic on a successful keep, release, or peel; none on tab changes.

### 3.3 Naming contract

Convention: Stringer / creel-census lexicon.

Examples to follow: `Stringer`, `KeepMark`, `keep(_:)`, `Over`

### 3.4 Dependency contract

Withycreel ships no SPM packages and no vendored sources. project.yml has no packages key. Foundation and SwiftUI only. The leftover AVCaptureMetadataOutput scanner and cgi search pl endpoint stay unused; do not import AVFoundation for capture, do not request camera access, and do not call a remote catalog. CSV export is a local FileManager write from the creel document. SF Pro is the system face; do not bundle a font.

### 3.5 Navigation contract

Stringer-tab chrome: a TabView of Catches, Limits, and Settings, each with its own NavigationStack. Catches never leaves the stringer; species, length, weight, Keep, and Release fuse on the open clip rather than pushing a log row. Limits and Settings are sibling tabs, not sheets that replace the stringer. No Scan, Search, Tides, or Game tab. Contact URL lives on Settings. Read ProcessInfo.processInfo.arguments once after onboarding: ReviewScreen today stays on Catches; log opens Limits; goals opens Settings. Skip onboarding on Simulator after the wyc.demo.v1 seed so the hook can fire.

### 3.6 Screen composition contract

Vertical snap pages. Physical screens: Catches, Limits, Settings. Catches is home: a vertical paging snap of glass clips (open clip first, then each Fish in stringer order; Over hangs past the last clip); Keep and Release commit in place; remaining daily and season figures sit on the open clip; ReviewScreen today. Empty Catches is a full page with generated cutout art, headline No catches yet., one line Log the first fish., and a full-width bottom Keep. Limits is a vertical snap of SpeciesLimit cards for daily and season bag edits (ReviewScreen log) with its own full-page empty state. Settings is a Form for display units (SI in the store), CSV export, contact URL at https://withycreel-bag.pro/contact-us, re-run onboarding, and resetAllData (ReviewScreen goals). Onboarding is a one-shot cover of three or four pages with Next at the bottom full width. No Today, Scan, Search, or Goals screens. No Tides mini-game. ReviewScreen today log and goals must open three different screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By stringer role (Stringer, Fish, KeepMark, Release, Limit, Over)**

```
Withycreel/
  Stringer/
  Fish/
  KeepMark/
  Release/
  Limit/
  Over/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Catches
A first-class screen for **Catches**. Must render empty, populated and error states.

### 5.3 Limits
A first-class screen for **Limits**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **CatchRecord** — named per this app's convention.
- **SpeciesLimit** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Orchid soft focus**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F7F5FA` | Screen background |
| `surface` | `#FEFDFE` | Cards, rows, sheets |
| `ink` | `#231839` | Primary text and icons |
| `accent` | `#5B2CBA` | Primary action, key figure, progress fill |
| `muted` | `#6F6487` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro via Font.system for Withycreel. Display is remaining on the open clip. Body is species names on glass clips. Caption is Over copy. Tabular figures for remaining, length cm, and weight kg through NumberFormatter. At most six steps behind one accessor. No Font.custom and no fixedSize. Never below 12pt. Dynamic Type; species names truncate, numbers win. Day edges use Calendar.current.startOfDay then fold to Int YYYYMMDD; season is that calendar year.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **22pt** for cards, sheets and primary surfaces; **14pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **shadow** — a single soft drop-shadow token, reused everywhere a surface sits above another.

Primary control: **soft card** — primary actions live inside a rounded card using the radius below, not a flat row with no fill.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **SwiftUI pure · take catchlog**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **SwiftUI pure · take catchlog** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable CreelDocument (schemaVersion from 1, SpeciesLimit rows, and per-day Stringer folds of Fish, KeepMark, and Over keyed as Int YYYYMMDD) encoded to JSON Data in UserDefaults under wyc.stringer.v1. Remaining daily and season counts are derived at display and are never stored. In-memory StringerStore is the source of truth; UserDefaults is the projection. Debounce writes; flush when scenePhase becomes inactive or background; encode after every keep, release, and peel. Decoding failure falls back to an empty stringer, never a crash. resetAllData() is reachable from Settings. Simulator seed only once behind wyc.demo.v1 writes several Fish with Keep still enabled and remaining above zero, marks onboarding complete, and never seeds Over as the first frame. Never seed on a device. Views never touch UserDefaults. CSV export reads the same document.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Withycreel/1.0 (iOS; +https://withycreel-bag.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.sports`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.sports
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Overhang keep (Keep always files; a full stringer writes Over and warns; remaining never goes negative)

Home is today's stringer of glass clips, not a catch list plus a form. Keep is the first tap and stays enabled after seed. A keep writes a Fish and a KeepMark and spends remaining; when the bag is already full it still files, hangs that fish past the last clip as Over, and warns. Remaining never goes negative and Keep is not refused. Release files a Fish without a KeepMark and spends nothing. Undo peels the last Fish on this day's stringer only, Limits edits SpeciesLimit, Settings exports CSV, and history is Fish order on the stringer rather than a global timeline.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **3D glass render glassmorphism · take catchlog**


This assignment restates a catalog technique another app already holds. Write a new composition: new types, new layout, new motion. Do not copy source, file trees, or type names from the holder.

Base prompt, reused and extended for every asset:

```
3D glass render, frosted translucent glassmorphism, soft-focus studio light, a withy creel and a hanging stringer of glass fish clips over still water, refraction and milky frost, quiet product still life, no readable text, no letters, no logo, no specific hues
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `wyc_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `wyc_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `wyc_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `wyc_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `wyc_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `wyc_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `wyc_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `wyc_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `wyc_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `wyc_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `wyc_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Overhang keep (Keep always files; a full stringer writes Over and warns; remaining never goes negative)' feature screen. |
| 11 | `wyc_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `wyc_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`wyc_AppIcon`** — 1024x1024

```
3D glass fish clip on a withy stringer, single emblem filling the canvas edge to edge, frosted glassmorphism, studio soft focus, no text, no letters, no rounded corners, no drop shadow, opaque, subject inside the middle 80 percent
```

**`wyc_Splash`** — 1290x2796

```
Vertical 3D glass stringer of clips over still water, frosted glassmorphism, quiet uncluttered centre band, studio soft focus, no readable text
```

**`wyc_Onboarding1`** — 1024x1536

```
3D glass still life of a withy creel and an empty stringer, the product in one glance, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_Onboarding2`** — 1024x1536

```
3D glass mid-gesture: a keep clipping a glass fish onto the stringer, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_Onboarding3`** — 1024x1536

```
3D glass stringer after many clips with one fish hanging past the last clip, accumulated creel, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_EmptyHome`** — 1024x1024

```
3D glass empty withy creel and vacant stringer over still water, waiting, calm and inviting, never sad, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_EmptyList`** — 1024x1024

```
3D glass empty creel-census leaf with no limit cards, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_CardBackdrop`** — 1200x800

```
Abstract frosted glass and still-water refraction, low contrast so type can sit on top, 3D glass render, no letters, fills the canvas
```

**`wyc_ControlFace`** — 512x512

```
Face of a single glass keep clip as a physical control, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_TwistHero`** — 1024x1024

```
3D glass emblem of overhang keep: a fish hanging past the last clip on a full stringer, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_SuccessMark`** — 512x512

```
Small 3D glass clip-click confirmation spark, frosted glassmorphism, isolated cutout, no text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`wyc_HeaderDecor`** — 1200x600

```
Wide 3D glass withy-and-water band, frosted clips in a row, low contrast, no readable text

HARD CUTOUT: isolated subject on a fully transparent background. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated subject, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`wyc.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `WithycreelTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Parse `ProcessInfo.processInfo.arguments` once after onboarding. 
   `-ReviewScreen today|log|goals` switches the running app's live navigation.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Withycreel -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Stringer ADT fold (Open | Kept | Released | Over); the day is a fold over Fish; Keep writes a KeepMark and spends 1 from remaining; Release files without spending; Keep at remaining 0 files Over and warns** with no leakage across layers.
- [ ] UI approach matches **SwiftUI pure · take catchlog**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Stringer-tab chrome (Catches holds the stringer; species, length and keep fuse on the stringer; Limits and Settings are sibling tabs)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Withycreel
xcodegen generate
xcodebuild -scheme Withycreel -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Withycreel -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.

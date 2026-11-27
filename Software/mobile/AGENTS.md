# AGENTS.md — Home Energy Coach mobile apps

This file is for AI coding agents (and humans) working on the mobile apps in `Software/mobile/`.
It explains how the iOS app is built and how to build an Android app that behaves and looks the same.

- `iOS/HomeEnergyCoach/` — native iOS app (Swift 6, UIKit). **This is the reference implementation.**
- `android/` — does not exist yet. See [Building the Android app](#building-the-android-app).

---

## 1. Product in one paragraph

Home Energy Coach helps people in shared flats (German "WG") build energy-saving habits.
A short questionnaire estimates the household's energy profile. The app then recommends one habit at a time,
tracks check-ins and habit strength, and shows "Green Hours" (times when grid electricity is cleanest, from public SMARD data).
It also has a shared WG challenge, an impact summary and a transparent data & privacy page.
Recommendations will come from an R backend (k-means clustering, recommenderlab, arules, time-series forecasting). That backend does not exist yet.

## 2. Source of truth: Figma

- File: `https://www.figma.com/design/LXdHAB7LGzbOWMw3sBCY2u` (Home Energy Coach – iOS prototype).
- **Only implement from the `v4` page** (canvas `187:817`).
  - Ignore the v1, v2, v3 and v5 pages.
  - v5 duplicates v4's frame names under different node IDs, so don't search by frame name alone.
- Design tokens are the Figma variables of the v4 collection. Their names are mirrored in code: `ink-2` → `ink2`.
- When the design and the code disagree, the design wins unless the deviation is listed in [§9](#9-deliberate-deviations-from-figma).

| Flow | Screen | Figma node | iOS controller |
|---|---|---|---|
| Intro | I1–I3 carousel | `201:1877` | `Features/Onboarding/Controller/OnboardingViewController` |
| Account | A1 Welcome | `190:855` | `Features/Welcome/Controller/WelcomeViewController` |
| | A2 Create account | `190:929` | `Features/Account/Controller/CreateAccountViewController` |
| | A3 Log in | `190:1040` | `Features/Account/Controller/LogInViewController` |
| Questionnaire | O1 Your home | `190:1126` | `Features/PlanSetup/Controller/YourHomeViewController` |
| | O2 Hot water | `191:961` | `HotWaterViewController` |
| | O3 Heating | `191:1071` | `HeatingViewController` |
| | O4 Appliances | `191:1175` | `AppliancesViewController` |
| | O5 Your week | `192:1036` | `YourWeekViewController` |
| | O6 Your focus | `192:1170` | `YourFocusViewController` |
| | O7 Your plan | `192:1294` | `YourPlanViewController` |
| Main (tabs) | 01 Home | `193:1086` | `Features/Home/Controller/HomeViewController` |
| | 02 Plan | `193:1248` | `Features/Habits/Controller/PlanViewController` |
| | 03 Habit | `193:1412` | `HabitDetailViewController` |
| | 04 Green Hours | `194:1241` | `GreenHoursViewController` |
| | 05 Habit catalogue | `194:1507` | `HabitCatalogueViewController` |
| | 06 Quick wins | `194:1669` | `QuickWinsViewController` |
| | 07 WG | `195:1396` | `WGViewController` |
| | 08 Impact | `195:1537` | `ImpactViewController` |
| | 09 Data & privacy | `195:1681` | `DataPrivacyViewController` |
| | 10 Green software | `195:1815` | `GreenSoftwareViewController` |

## 3. Navigation flow

```
Intro carousel (I1–I3)
   ├─ "Let's go"  → Welcome (A1)
   └─ "Log in"    → Welcome → Log in (A3)

Welcome (A1)
   ├─ "Get started" → Create account (A2) ─ submit ─┐
   └─ "Log in"      → Log in (A3) ──────── submit ──┤   (login is skipped for now, see §8)
                                                    ▼
                   Questionnaire O1 → O2 → O3 → O4 → O5 → O6 → O7 "Start my plan"
                                                    ▼
                   Main app (tab bar, replaces the whole window; no way back)
                     Home | Plan | Green Hours | WG | Impact
```

Pushed from inside the tabs:
- **Home:** habit card → Habit (03); green-window card → Green Hours tab; "Next" → Plan tab.
- **Plan:** "See all habits" → Habit catalogue (05). In the catalogue, H01 → Habit (03).
- **Impact:**
  - "Data & privacy" → 09; "Green software" → 10.
  - The "x/6 one-time actions" tile → Quick wins (06). The design has no entry point for Quick wins, so this one was chosen.
- **Quick wins:** the H22 row ("WG energy agreement") → WG tab.
- **Habit:** "Check in today" → Home tab.
- **Data & privacy:** "Delete account" → confirmation → back to Welcome.

## 4. iOS project facts

| | |
|---|---|
| Project | `iOS/HomeEnergyCoach/HomeEnergyCoach.xcodeproj`, scheme `HomeEnergyCoach` |
| Language / UI | Swift 6 (strict concurrency), UIKit, **no storyboards** (programmatic Auto Layout) except the launch screen |
| Minimum OS | iOS 17, iPhone only, portrait, light mode only (`UIUserInterfaceStyle = Light`) |
| Bundle ID | `com.greenhabit.HomeEnergyCoach` |
| Groups | Folder-synchronized groups (objectVersion 77): new files in the folders are picked up automatically, so don't edit `project.pbxproj` to add files |
| Tests | Swift Testing (`import Testing`) in `HomeEnergyCoachTests/` — view models and models only |
| Dependencies | None (no SPM / CocoaPods) |
| Fonts | Geist (Regular, SemiBold, Bold) and Geist Mono Medium in `Resources/Fonts`, registered in `Info.plist` → `UIAppFonts` |
| Strings | `Resources/Localizable.xcstrings`, always via `String(localized:comment:)` |
| Assets | `Resources/Assets.xcassets`: Figma SVGs with `preserves-vector-representation`; tinted icons use template rendering |

**Known gap:** `Info.plist` lists `Geist-ExtraBold.ttf`, but the file is not in `Resources/Fonts`.
The `display` and `stat` styles therefore fall back to the system font.
To fix it, add the font file (Geist is OFL-licensed) to `Resources/Fonts`.

### Build, run, test

```bash
cd Software/mobile/iOS/HomeEnergyCoach
xcodebuild -scheme HomeEnergyCoach -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
xcodebuild -scheme HomeEnergyCoach -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

**Debug deep links** (DEBUG builds only): launch with `-startScreen <name>` to open any screen directly.
The values are:
- Account screens: `welcome`, `signup`, `login`.
- Questionnaire: `setup`, `hotwater`, `heating`, `appliances`, `week`, `focus`, `plan`.
- Main app: `home`, `planTab`, `habit`, `greenHours`, `catalogue`, `quickWins`, `wg`, `impact`, `privacy`, `greenSoftware`.

See `App/AppCoordinator.startDebugScreen`.

## 5. Architecture

**MVVM + Coordinators.** Controllers never push other controllers. They report intent through a delegate or closure, and a coordinator decides where to go.

```
HomeEnergyCoach/
├── App/                  AppDelegate, SceneDelegate, AppCoordinator (root flow + debug deep links)
├── Core/
│   ├── DesignSystem/     AppColor, TextStyle, Spacing + CornerRadius, EntranceAnimation
│   ├── Components/       Reusable views (buttons, fields, chips, cards, list rows, progress…)
│   └── Scaffold/         FormScreenViewController (base class for almost every screen)
├── Features/<Feature>/
│   ├── Model/            Plain value types (structs/enums, Sendable), sample data, protocols for services
│   ├── ViewModel/        @MainActor final classes: state + validation + formatting, no UIKit views
│   ├── View/             Feature-specific views
│   ├── Controller/       UIViewControllers: build views, bind to the view model, forward intents
│   └── <Feature>Coordinator.swift (where the feature has its own flow)
└── Resources/            Assets.xcassets, Fonts, Localizable.xcstrings
```

The features are:
- `Onboarding` (intro carousel)
- `Welcome`
- `Account` (create account and log in)
- `PlanSetup` (the questionnaire, with `PlanSetupCoordinator`)
- `Home`
- `Habits` (all main-app screens except Home)
- `Main` (`MainCoordinator`, `MainTabBarController`, `AppTabBarView`)
- `ComingSoon` (placeholder)

**Coordinators**
- `AppCoordinator`:
  - Owns the `UIWindow`.
  - Runs the flow: intro → welcome/account → questionnaire → main app.
  - `swapRoot` cross-dissolves the window root when entering or leaving the main app.
- `PlanSetupCoordinator`:
  - Pushes O1–O7, carrying a `PlanSetupDraft` (all questionnaire answers) from step to step.
  - Builds the plan through `PlanRecommending`, currently `StubPlanRecommender`.
  - Calls `onFinish(draft, summary)` when the questionnaire is complete.
- `MainCoordinator`:
  - Five tabs, each with its own `AppNavigationController`.
  - `enum Route` and `open(_:)` for deep links.
  - Owns the shared state: `QuickWinsViewModel` and `PrivacySettingsStoring`.
  - Calls `onSignOut` when the account is deleted.

**Screen pattern** (copy this for new screens):

```swift
final class FooViewController: FormScreenViewController {
    var onSomething: (() -> Void)?                     // intent out → coordinator
    private let viewModel: FooViewModel

    init(viewModel: FooViewModel) {
        self.viewModel = viewModel
        super.init(navigationTitle: String(localized: "Foo", comment: "Foo nav title")) // nil = no nav header
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setContent([HeadlineView(title: …, subtitle: …), …], actions: [AppButton(kind: .primary, title: …)])
    }
}
```

`FormScreenViewController` provides:
- The optional `v4/Nav` header (back chevron and title).
- A scroll view with content insets of 12pt at the top, 24pt at the sides and 16pt between blocks.
- Bottom-anchored actions that stay above the keyboard and 32pt above the home indicator.
- Tap-to-dismiss for the keyboard.
- The standard entrance animation.

The system navigation bar is always hidden. The swipe-back gesture is re-enabled in `AppNavigationController`.

## 6. Design system (shared by iOS and Android)

### Colors (`Core/DesignSystem/AppColor.swift`)

| Token | Hex | Use |
|---|---|---|
| `ink` | `#1B4332` | Primary text, icons |
| `ink-2` | `#4F6F62` | Secondary/body text |
| `ink-3` | `#93A89D` | Placeholders, hints, inactive, section eyebrows |
| `brand` | `#40916C` | Primary buttons, active indicators, emphasized cards |
| `green` | `#40916C` | Accent text, brand tile, chart highlight |
| `on-ink` | `#FFFFFF` | Content on `brand`/`ink` fills |
| `on-ink-2` | `#D8F3DC` | Secondary content on `brand` |
| `green-soft` | `#95D5B2` | Soft highlight surfaces, positive tags |
| `lime` | `#FFCB42` | Highlight tags |
| `orange` | `#E76F51` | High-CO₂ hours, destructive actions |
| `card` | `#FFFFFF` | Cards, pills |
| `bg` | `#FFFFFF` | Screen background |
| `line` | `#EDE3CB` | Dividers, borders, inactive bars |

### Typography (`Core/DesignSystem/TextStyle.swift`)

All sizes are in points, which map 1:1 to Android sp. Every style scales with Dynamic Type / font scale.

| Style | Font | Size / line height | Tracking |
|---|---|---|---|
| `display` | Geist ExtraBold | 44 / 46 | −4% |
| `stat` | Geist ExtraBold | 36 / 38 | −4% |
| `h1` | Geist Bold | 30 / 34 | −3% |
| `h2` | Geist Bold | 22 / 26 | −2% |
| `headline` | Geist SemiBold | 16 / 22 | −1% |
| `body` | Geist Regular | 15 / 22 | −0.5% |
| `bodyStrong` | Geist SemiBold | 15 / 22 | −0.5% |
| `caption` | Geist Regular | 13 / 18 | 0 |
| `label` | Geist SemiBold | 13 / 18 | 0 |
| `meta` | Geist Mono Medium | 11 / 14 | +2%, UPPERCASE (eyebrows, habit codes) |

### Spacing and radius (`Spacing.swift`)

- **Spacing:** `xxs 6`, `xs 10`, `s 16`, `m 24`, `l 32`.
- **Corner radius:**
  - `indicator 4`, `tile 10`, `field 14`
  - `button 16`, `card 20`, `illustration 28`
- **Screen layout:**
  - 24pt side margins, 16pt between blocks.
  - 20pt horizontal padding inside list cards.
  - 1pt `line` dividers.

### Motion (`EntranceAnimation.swift`)

- **Screen entrance:** each content block fades in and rises 8pt → 0, over 350ms ease-out, staggered 50ms apart starting at 50ms. It plays once per screen.
- **Charts and progress:** bars grow from zero on first appear.
- **Reduce Motion:** no movement, only a 200ms fade.

### Components (`Core/Components/`)

| Component | What it is |
|---|---|
| `AppButton(kind:)` | 56pt-high button. Kinds: `.primary` (brand fill), `.ghost` (outlined), `.destructiveGhost` (orange title) |
| `PillButton`, `TextLinkButton`, `LinkPromptView`, `TouchTargetButton` | Small buttons and links; hit area is always ≥ 44pt |
| `NavHeaderView` | `v4/Nav`: back chevron and title |
| `HeadlineView` | `h1` title plus `body` subtitle |
| `FormTextField` | Label above a 14-radius field with an error state |
| `CheckboxControl`, `ToggleRowView` | Checkbox; title (and optional subtitle) with a native switch |
| `ChipGroupView` | Wrapping chips (single or multi-select, optional icon) |
| `OptionCardGroupView` | Selectable cards with title and subtitle (multi-select) |
| `SegmentedChoiceView`, `StepperView` | Segmented single choice; −/+ stepper with clamped range |
| `ProgressBarView`, `SegmentedProgressView`, `StrengthDotsView`, `PageIndicatorView` | Progress displays |
| `TagView` | Small rounded tag; `TagView.code("H01")` is the mono habit-code tag |
| `CardView` | `card` surface with radius 20 |
| `ListComponents.swift` | Building blocks for lists and stats, listed below |

The building blocks in `ListComponents.swift` are:
- `DividedListCard` and `ListRow`: cards with hairline dividers between rows.
- `HabitRowContentView`: habit-code tag, title and subtitle, with an optional trailing view.
- `CheckBulletRow`: a check bullet with text.
- `StatTileView`: a big number with captions. It can act as a selectable filter.
- `FlowLayoutView`: wraps its items onto new lines when they don't fit.
- `StyledLabel.section(_:)`: the uppercase eyebrow label.

## 7. Domain model

- **Habits** (`Features/Habits/Model/HabitCatalog.swift`):
  - Each habit has a code (`H01`…`H22`), a title, a topic and a `HabitCategory`.
  - The categories are `timing` (shift to Green Hours), `reduction` (use less) and `oneTime` (one decision).
  - The design names only 16 habits: H01–H05, H07–H09, H12, H14 and H17–H22. **Do not invent the missing ones** (H06, H10, H11, H13, H15, H16).
- **Questionnaire answers:** `PlanSetupDraft`.
  - Household size, flat size, postcode, yearly kWh
  - Hot water system, shower duration, heating
  - Appliances and how often they run each week
  - Home time slots, whether the washer has a delay timer
  - Focus areas, nudge frequency
  - Anonymous sharing: opt-in, so it defaults to **false**.
- **Plan output:** `PlanSummary`, from `PlanRecommending`.
- **Main-app content** (`MainAppContent.swift`):
  - `PlanTabContent`, `HabitDetail` (a 4-week × 7-day check-in grid), `GreenHoursForecast` (24 hourly g CO₂/kWh values)
  - `QuickWin`, `WGOverview`, `ImpactSummary`, `GreenSoftwareReport`
  - Each has a `.sample` copied from Figma.
- **Green Hours rules** (`GreenHoursViewModel`):
  - An hour is **clean** at ≤ 260 g and **high** at ≥ 345 g; anything in between is medium. Hours inside the recommended window count as "window".
  - The summary's figure is the window mean rounded **down** to the nearest 10 g.
- **Privacy settings** (`PrivacySettings`, Codable, stored in UserDefaults):
  - `shareProgressWithWG` = true
  - `improveRecommendations` = **false** (opt-in)
  - `reminders` = true

## 8. Current state, stubs and TODOs

- **Login is skipped:**
  - `LogInViewModel(requiresCredentials: false)` keeps "Log in" always enabled.
  - Log in and Face ID both run the questionnaire, then open Home.
  - Once an account API exists, default `requiresCredentials` to `true` and send returning users straight to Home.
- **No backend yet.** Every number in the main app is `.sample` data, and each spot is marked `// TODO:`.
  - Plan generation uses `StubPlanRecommender`.
  - Export only covers local settings.
  - Delete account doesn't call an API.
- **Forgot password** opens `ComingSoonViewController`, because no design exists for it.
- **Persistence:** only the privacy settings are saved. Plan start/dismiss, check-ins and quick wins live in memory.

Search with `grep -rn "TODO" iOS/HomeEnergyCoach/HomeEnergyCoach` to find the open items.

## 9. Deliberate deviations from Figma

Keep these on **both** platforms unless the design changes:
1. **Habit counts:** the catalogue says "16 habits" and Plan's "See all" link says 16, matching the habits that actually exist. The design says 22.
2. **Catalogue filters:** the category tiles filter the list, with none selected by default. The design highlights "Reduction" without filtering.
3. **"Improve recommendations anonymously"** starts **off** (GDPR opt-in). The design shows it on.
4. **Switches:** native platform switches are used instead of the design's toggle drawing.
5. **Tab labels:** may shrink to 80% so "Green Hours" fits.
6. **Kept as drawn,** though they are design bugs:
   - `green` on `brand` is invisible (same hex), e.g. the WG Jonas bar.
   - `card` and `bg` are both white, so cards have no visible edge.

## 10. Coding standards (both platforms)

- **Tokens only:**
  - Never hard-code a color, font or radius in a screen. Add or extend a token or component instead.
  - Reuse an existing component before writing a new one.
- **Accessibility is required:**
  - Text scales with the user's font size.
  - Every interactive element has an accessibility label (VoiceOver/TalkBack) and a hit area of at least 44pt/48dp.
  - Decorative images are hidden from accessibility.
  - Composite rows read as one element.
  - Selected state is announced.
  - Reduce Motion / "Remove animations" is respected.
- **Localize every user-facing string,** with a comment for translators. Use `localizedUppercase`/locale-aware formatting.
- **Privacy by default:** anything that shares data is opt-in. Collect nothing beyond what §7 lists. Never collect location, contacts or microphone.
- **Logic lives in view models and models,** which are unit-tested. Controllers/composables stay thin. Every view-model rule gets a test.
- **Sample data:** never invent product content (habit names, numbers, copy). Take it from Figma. If something is missing, leave a `TODO` and say so.
- **Commits:** don't commit or push unless asked. Branch off `main` first.

---

## Building the Android app

Goal: **the same app, screen for screen**, using the same Figma v4 frames, tokens, copy, flow, deviations and test rules described above.
Use the iOS code as the behavioural spec: read the view model before building each screen.

### Recommended stack

| Concern | iOS (existing) | Android (to build) |
|---|---|---|
| Language | Swift 6 | Kotlin 2.x |
| UI | UIKit, programmatic | Jetpack Compose + Material 3 (styled entirely with our own tokens) |
| Min OS | iOS 17 | minSdk 26, target/compile the latest SDK |
| Screen state | `@MainActor` view-model classes | `androidx.lifecycle.ViewModel` + `StateFlow<UiState>` (immutable data class) |
| Navigation | Coordinators | Navigation Compose: one `NavHost` per flow; the main app is a `Scaffold` with a custom bottom bar and a nested graph per tab |
| Intents out of screens | delegates / closures | Lambda parameters (`onLogIn: () -> Unit`); screens never call `navController` directly |
| DI | Initializer injection | Constructor injection; add Hilt only if it pays off |
| Persistence | `UserDefaults` (`PrivacySettingsStoring`) | DataStore (Preferences) behind a `PrivacySettingsStore` interface |
| Strings | `Localizable.xcstrings` | `res/values/strings.xml` (+ `plurals`) |
| Icons | SVG in the asset catalog | Same Figma SVGs, imported as VectorDrawables (`res/drawable/ic_*.xml`) |
| Fonts | `Resources/Fonts/*.ttf` | `res/font/geist_*.ttf` + a `FontFamily` |
| Tests | Swift Testing | JUnit 5 (or 4) + Turbine for flows; Compose UI tests for key flows |
| Debug deep links | `-startScreen <name>` | Debug-only intent extra `startScreen` with the same names |

### Suggested module layout

```
android/
├── app/src/main/java/com/greenhabit/homeenergycoach/
│   ├── MainActivity.kt              single activity, edge-to-edge, light theme only
│   ├── navigation/                  AppNavHost (intro → account → setup → main), MainNavHost (tabs), Routes
│   ├── core/designsystem/           AppColors, AppTypography (TextStyle equivalents), Spacing, Radius, EntranceAnimation
│   ├── core/components/             AppButton, NavHeader, FormTextField, ChipGroup, OptionCardGroup, Stepper,
│   │                                SegmentedChoice, ToggleRow, Tag, Card, DividedListCard, HabitRow, StatTile, …
│   └── feature/
│       ├── onboarding/  welcome/  account/  plansetup/  home/  habits/  main/
│       │   each with model/, viewmodel/, ui/ (Screen composables)
└── app/src/test/…                   ViewModel + model unit tests, ported from HomeEnergyCoachTests/
```

### Porting rules

1. **Tokens first.**
   - Port §6 exactly: colors as `Color(0xFF1B4332)`, etc.
   - Typography as `TextStyle(fontFamily = Geist, fontWeight = …, fontSize = 15.sp, lineHeight = 22.sp, letterSpacing = (-0.075).sp)`.
   - Compute letter spacing as tracking% × size, the same as iOS.
   - Set `MaterialTheme`'s colorScheme and typography from these tokens. Do not use Material's default purple, ripples or elevation where the design doesn't show them.
2. **Port the models and view models next,** with their tests.
   - Port `PlanSetupDraft`, `HabitCatalog`, `MainAppContent` (including the `.sample` data), and every rule in the iOS view models: validation, clamping, Green Hours thresholds and rounding, catalogue search, quick-wins toggling, WG fractions and privacy defaults.
   - Port `HomeEnergyCoachTests/*.swift` one-to-one, so both platforms prove the same behaviour.
3. **Port the components,** matching the iOS sizes:
   - Buttons: 56dp high, 16dp radius.
   - Fields: 14dp radius.
   - Cards: 20dp radius, 20dp inner side padding, 1dp `line` dividers.
   - Tab bar: 62dp tall plus the system inset. A 24×3dp `brand` indicator sits above the active item. The active label is `label` style in `ink`; inactive labels are `caption` in `ink-3`.
4. **Screen scaffold:** build the equivalent of `FormScreenViewController` as a `FormScreen(title, content, actions)` composable:
   - Optional nav header.
   - Scrollable column: 24dp side padding, 12dp at the top (20dp without the header), 16dp between blocks.
   - Actions pinned to the bottom, 32dp above the navigation bar.
   - `imePadding()` so the actions stay above the keyboard.
   - The entrance cascade on first composition.
5. **Then build the screens,** in the order of §2's table, checking each against its Figma frame. Use the frame screenshot only as the visual target; build from the design context and tokens.
6. **Navigation and back behaviour:**
   - The intro is replaced, not stacked.
   - Entering the main app clears the back stack, so Back from Home exits the app.
   - Create account ⇄ Log in replace each other.
   - "Delete account" clears everything and returns to Welcome.
7. **Accessibility:**
   - Use `semantics { contentDescription; role; selected; heading() }`.
   - Use `Modifier.minimumInteractiveComponentSize()`.
   - Font scale works via `sp`.
   - Respect "Remove animations" by checking `Settings.Global.ANIMATOR_DURATION_SCALE == 0`.
8. **Keep §8 (stubs) and §9 (deviations) identical,** and mirror the iOS `TODO` comments.
9. **Strings:** copy the English copy exactly from iOS/Figma: same punctuation, the `→` arrows, and the `CO₂` subscript character.

### Definition of done for an Android screen

- It matches the v4 Figma frame (layout, tokens, copy, icons) at 1× font scale and stays usable at 2× font scale.
- Its navigation in and out matches §3.
- The view model is ported with tests, and `./gradlew test` passes.
- TalkBack reads every element sensibly, and every touch target is ≥ 48dp.
- It has no hard-coded colors, sizes or strings.

# Premium rules

Authority for prices, free limits and feature gates. Last updated: 2026-09-06.

## Offer

| Product | Price | Trial | Access |
|---|---:|---:|---|
| Premium Monthly | $4.99/month | None | All Premium features |
| Premium Yearly | $29.99/year | 7 days | Same as monthly |

Yearly saves 50% compared with twelve monthly payments. There is no lifetime
product: app costs such as WeatherKit, alerts and Firestore recur.

| Rule | Requirement |
|---|---|
| Price display | Use the store-provided `PremiumOffer.priceLabel` |
| Entitlement source | RevenueCat only, and only while `premium_enabled` is on |
| Account | Not required to buy, restore or use Premium |
| Existing lifetime buyer | Keep the entitlement; do not show a lifetime offer |

## Free limits

Code authority: `lib/core/constants/premium_limit_constant.dart`.

| Record | Limit | Constant | Reason |
|---|---:|---|---|
| Attacks | **None** | — | Logging one is recording a health event the app calls the user's own; a wall in front of it contradicts that, and the chronic sufferer who hit the old 40 in month three left rather than paid |
| Readable history | 90 days | `freeHistoryWindow` | What is sold is reading the record back, not writing it. Applied in the widget layer (`AttackWindow`) — never in a provider, see below |
| Medications | 5 | `medications` | Covers a typical acute + preventive regimen |
| Reminders | 2 total | `reminders` | Covers morning/evening preventive use |
| Attack warning | 5 remaining | `attacksWarnAt` | Avoids surprising a user during an attack |

## Limit behavior

| Situation | Required behavior |
|---|---|
| Logging an attack | Never refused, never counted |
| History older than the window | Hidden from History, named by `FreeHistoryBanner`, and still on the device |
| Add beyond a limit | Explain the limit, then offer the paywall |
| Existing records above a limit | Keep visible and editable; never hide or delete |
| Anything behind the window | Show `FreeHistoryBanner` — dashboard and History — and only where something IS hidden |
| Current usage | Show `FreeLimitProgress`; hide it for Premium users |
| New month | Do not reset lifetime limits |
| Medication limit in attack flow | Block adding a new medication, never the attack log |
| Reminder limit | Check before requesting OS notification permission |
| Locked surface already labeled Premium | Open the paywall directly |
| Dashboard risk card without premium | Absent, never locked — the banner is that screen's one premium door |

## Access matrix

| Capability | Free | Premium |
|---|:---:|:---:|
| Offline attack log | Unlimited | Unlimited |
| Reading history back | Last 90 days | All of it |
| Weather snapshot on an attack | Yes | Yes |
| Current weather except pressure | Yes | Yes |
| Plain pressure reading in weather details | Yes | Yes |
| 7-day pressure forecast, with 5 days of history behind it | No | Yes |
| Pressure correlation and drop alerts | No | Yes |
| Second alert as the drop begins | No | Yes |
| Medications | Up to 5 | Unlimited |
| Medication effectiveness | Yes | Yes |
| Medication-overuse warning | Yes | Yes |
| Medication reminders | Up to 2 | Unlimited |
| Notification list | Yes | Yes |
| Severity donut | Yes | Yes |
| Migraine days this month | Yes | Yes |
| Sleep and step readings | Yes | Yes |
| Sleep, step and exertion correlations | No | Yes |
| Daily check-in | Yes | Yes |
| Menstrual cycle read from Apple Health | Yes | Yes |
| Attack-in-progress screen and Live Activity | Yes | Yes |
| Time to relief on an attack | Yes | Yes |
| Siri shortcuts | Yes | Yes |
| Trigger / protector map | No | Yes |
| 7-day risk score | No | Yes |
| Humidity and temperature-swing factors | No | Yes |
| MIDAS questionnaire and its score | No | Yes |
| Other charts | No | Yes |
| JSON, CSV and PDF export screen | No | Yes |
| Export history and preview | No | Yes |
| Delete your account, and everything it holds | Yes | Yes |

## Gate rules

| Rule | Why |
|---|---|
| Premium data starts at the first record | Buying must unlock value immediately |
| Small samples are graded, not withheld | A threshold must not create an empty paid screen |
| Free widget trees use sample data behind locks | Blurring real premium data can leak it in a screenshot |
| Pressure forecast checks access before loading | Free users must not trigger paid WeatherKit work |
| Export entrance is gated | The whole export surface is Premium |

A lapsed subscriber cannot open previous exports through the app, but the files
remain on-device and deleting the account still deletes them. Free data-access
requests remain available through the support route in the privacy policy.

## Why the window is not a provider

**No provider may filter the attack list by the entitlement.** The premium flag
arrives asynchronously — RevenueCat in production, a stream in the tests — so a
provider watching it is recomputed while the first frames are still laying out,
and Riverpod reports that as "setState called during build" on whatever screen
was mid-transition. Three shapes were tried and all three threw it: a
`StreamProvider` that watched the flag, a sync provider over that stream, and a
`FutureProvider` the engines awaited.

So the window lives in the widget layer: `HistoryScreen` watches
`freeHistoryStartProvider` and runs its two lists through `AttackWindow.within`.
The analyses are left reading the whole record — every one of them that is worth
money is already behind `PremiumGate`, so a free user sees the lock rather than
a short answer.

## The app-wide off switch

`app_config/current.premium_enabled: false` makes `hasPremiumProvider` answer false
for **everyone at once** — bought, listed, and forced by the Dev group
alike — and ends the pressure-alert cron pass before it pushes anything. It is
checked ahead of every other branch, because the address list and the Dev
override both return early and a switch below either is one they could talk
their way past.

| State | Premium |
|---|---|
| `premium_enabled: false` | Off, for everybody |
| Field absent, document absent, read denied, read in flight | **On** — a failed read must not take away what someone paid for |
| Anything that is not literally `false` (including `"false"`) | On |

Shape and rules: [`../lib/features/app_config/CLAUDE.md`](../lib/features/app_config/CLAUDE.md).

## Named implementations

| Purpose | Owner |
|---|---|
| Limit dialog → paywall | `NavigationUtils.toPaywallFromLimit` |
| Free usage display | `FreeLimitProgress` |
| The history window, and what it hides | `AttackWindow`, `freeHistoryStartProvider`, `FreeHistoryBanner` |
| Locked content | `PremiumGate`, `PremiumChartLock` |
| Safe preview data | `SampleChartData` |
| Export gate | `NavigationUtils.toExport` |

Read [`rules/DECISIONS.md`](rules/DECISIONS.md) before moving the free/Premium
boundary, especially for pressure features.

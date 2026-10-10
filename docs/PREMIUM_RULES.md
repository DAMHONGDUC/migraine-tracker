# Premium rules

Authority for prices, free limits and feature gates. Last updated: 2026-10-10.

**Everything is free except two things** (owner's rule, 2026-10-10): pressure
push alerts and the export screen. No record limits, no history window, no
locked analysis. Those two are the ones with a cost or a deliverable behind
them: an alert spends WeatherKit quota on every run, for every cell, forever;
export is the file a user takes away.

## Offer

| Product | Price | Trial | Access |
|---|---:|---:|---|
| Premium Monthly | $4.99/month | None | All Premium features |
| Premium Yearly | $29.99/year | 7 days | Same as monthly |
| Premium Lifetime | One-time, store price | None | Same as monthly |

Yearly saves 50% compared with twelve monthly payments. Lifetime is back as
of 2026-09-23 (owner's call); the history is in `docs/rules/DECISIONS.md`.

| Rule | Requirement |
|---|---|
| Price display | Use the store-provided `PremiumOffer.priceLabel` |
| Entitlement source | RevenueCat only |
| Account | Not required to buy, restore or use Premium |
| Lifetime package | RevenueCat `$rc_lifetime` (product `app.dd.reseller.studio.premium.lifetime2`); the row is labelled "One-time purchase" |

## What is paid

| Capability | Free | Premium |
|---|:---:|:---:|
| Pressure-drop push alerts (and the onset push) | Only while `app_config/current.free_pressure_alerts` is `true` | Yes |
| Export screen: JSON, CSV, PDF doctor report, export history | No | Yes |
| Everything else in the app | Yes | Yes |

Everything else includes the full history, every chart, the 7-day forecast,
every correlation, the trigger map, the risk score, MIDAS, unlimited
medications and unlimited reminders.

## Pressure alerts — the one switch

| `free_pressure_alerts` | Who can turn alerts on | Who the cron pushes to |
|---|---|---|
| absent, `false`, anything but the bool `true` | Premium accounts | `users.premium == true` + `premium_emails` |
| `true` | Every **signed-in** account | Every registered account (`fcmToken` + `geohash5`) |

- **Off by default because it costs.** The cron makes one WeatherKit call per
  geohash cell every 3 hours — 240 runs a month against a 500k quota shared
  with the app. Flip it on only while the number of cells allows it.
- **An account is still required**, either way. The server never pushes to an
  anonymous session (`lib/features/alerts/CLAUDE.md`).
- **The app and the cron read the same field** off the same document, so they
  cannot disagree about who gets alerts.

## Gate rules

| Rule | Why |
|---|---|
| Entitlement comes from RevenueCat only | Never a client-side flag |
| Export entrance is gated (`NavigationUtils.toExport`) | The whole export surface is Premium |
| Alert controls are gated on `hasAlertAccessProvider` | Premium, or the switch above |
| A gate never sits between a user and a free surface | Gate the action, not the screen that holds it |

A lapsed subscriber cannot open previous exports through the app, but the files
remain on-device and deleting the account still deletes them. Free data-access
requests remain available through the support route in the privacy policy.

Read [`rules/DECISIONS.md`](rules/DECISIONS.md) before moving the free/Premium
boundary.

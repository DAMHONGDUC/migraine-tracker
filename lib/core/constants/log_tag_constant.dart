/// Every flow name `SdLogger` prints, in one place.
final class LogTagConstant {
  /// App-wide wiring: the root widget's listeners, not a user flow.
  static const String app = 'App';

  /// `AppBootstrap` and the global error handlers it installs.
  static const String bootstrap = 'Bootstrap';

  /// `SecureStore` and the first-launch guard over it — the Keychain, not a user flow.
  static const String storage = 'Storage';

  /// `AppAnalytics` reporting on itself — an event sent, or one that threw.
  static const String analytics = 'Analytics';

  /// Opening an external url (privacy policy, store page, mail client).
  static const String link = 'Link';

  static const String alerts = 'Alerts';
  static const String appUpdate = 'App Update';

  /// The 3-tap log flow, up to the attack row being written.
  static const String attackLog = 'Log Attack';

  /// Viewing and editing an attack that already exists.
  static const String attackDetail = 'Attack Detail';

  /// Rendering an attack to an image and handing it to the share sheet.
  static const String attackShare = 'Attack Share';

  /// The best-effort weather backfill onto a logged attack. Its own flow because it runs long after the log finished and fails on its own.
  static const String weatherAttach = 'Weather Attach';

  /// The provider sheet through to the linked credential.
  static const String signIn = 'Sign In';

  /// Sign-out, deletion, and the Apple token revoke that precedes it.
  static const String account = 'Account';

  /// The `users/{uid}` document and the display name on the auth record.
  static const String profile = 'Profile';

  static const String health = 'Health';
  static const String history = 'History';
  static const String homeWidget = 'Home Widget';
  static const String insights = 'Insights';

  /// The weather card's own interaction — opening its detail sheet — not a weather fetch.
  static const String weatherCard = 'Weather Card';

  static const String medications = 'Medications';
  static const String medicationFilters = 'Medication Filters';
  static const String reminders = 'Reminders';
  static const String notifications = 'Notifications';
  static const String onboarding = 'Onboarding';

  /// Entitlement state — what RevenueCat says the user is entitled to.
  static const String premium = 'Premium';

  /// A purchase or a restore in flight, and the identity it runs under.
  static const String purchase = 'Purchase';

  /// The paywall screen itself.
  static const String paywall = 'Paywall';

  /// The RevenueCat SDK client, below both of those.
  static const String revenueCat = 'RevenueCat';

  static const String review = 'Review';
  static const String contact = 'Contact';
  static const String export = 'Export';
  static const String settings = 'Settings';

  static const String sync = 'Sync';

  /// Fetching the account key from the `getSyncKey` callable.
  static const String syncKey = 'Sync Key';

  /// The AES-GCM cipher itself. Separate so a decrypt failure is never read as a network problem.
  static const String syncCrypto = 'Sync Crypto';

  static const String weather = 'Weather';
  static const String location = 'Location';

  /// The daily pressure sample written for the correlation engine.
  static const String pressureRecord = 'Pressure Record';

  /// Dev-only flows. They exist in dev builds alone, and a tag of their own keeps them out of a filter on the real flow they stand in for.
  static const String devPush = 'Dev Push';
  static const String devLocation = 'Dev Location';
}

# Splash

The app icon and a loading indicator, on screen for exactly as long as
`AppBootstrap.init` takes.

- **It is not a route.** `AppBootstrapGate` (`core/bootstrap/`) watches
  `appBootstrapProvider` and shows this while it is pending; nothing about it
  touches go_router, and there is no timer. It lasts what startup lasts.
- **Bootstrap used to run before `runApp`**, which left the platform's launch
  screen standing in for it — nothing moving, and nothing to tell a slow start
  from a hang. Same wait now, but it looks like work.
- **Nothing of the app is built until bootstrap resolves.** `BaroEaseApp`
  installs listeners that read Firebase and the store on their first frame, and
  `FreshInstallGuard` has to have signed a reinstall out before any of them run —
  which is why the gate branches rather than overlaying.
- **The store arrives through a child `ProviderScope`.** It does not exist when
  the root scope is created, and every controller reads it synchronously.
- **Raw pixel sizes here, on purpose.** This screen lives above the app, outside
  the `ScreenUtilInit` that gives `.r` and `SdSpacingConstant` their scale. Two
  centred elements do not need it — `SplashConstant` holds the three numbers.
- **There are two launch screens, and only this one is Flutter.** The native one
  (`LaunchScreen.storyboard`, `launch_background.xml`) carries the SAME icon at
  the same size on the same colour, so the handover only adds the dots.
  `docs/setup/APP_ICON.md` covers regenerating those PNGs.
- **The icon is square in both**, because a storyboard image view cannot clip
  corners and rounding only one of them would pop at the handover.
- **No ARB strings.** Nothing on the screen is a word.
